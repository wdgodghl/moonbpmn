///|
/// Lifecycle state of a resumable process instance.
pub(all) enum InstanceStatus {
  InstanceReady
  InstanceRunning
  InstanceWaiting
  InstanceCompleted
  InstanceFailed(String)
} derive(Eq, Debug)

///|
pub extend InstanceStatus with Eq::{equal, not_equal}

///|
pub extend InstanceStatus with Debug::{to_repr}

///|
/// Mutable in-memory state for a resumable workflow instance.
pub(all) struct ProcessInstance {
  process_id : String
  mut status : InstanceStatus
  active_tokens : Array[String]
  waiting_tasks : Array[String]
  variables : VariableSet
  events : Array[ExecutionEvent]
  parallel_arrivals : Array[String]
  mut steps : Int
}

///|
pub(all) enum InstanceStartResult {
  InstanceStarted(ProcessInstance)
  InstanceRejected(ValidationReport)
}

///|
pub(all) enum TaskCompletionResult {
  TaskCompletedSuccessfully
  TaskNotWaiting
  TaskCompletionFailed(String)
} derive(Eq, Debug)

///|
pub extend TaskCompletionResult with Eq::{equal, not_equal}

///|
pub extend TaskCompletionResult with Debug::{to_repr}

///|
fn instance_record(
  instance : ProcessInstance,
  kind : ExecutionEventKind,
  element_id : String,
  detail : String,
) -> Unit {
  record_event(instance.events, kind, element_id, detail)
}

///|
fn instance_fail(instance : ProcessInstance, message : String) -> Unit {
  instance.status = InstanceFailed(message)
  instance_record(instance, ExecutionStopped, "", message)
}

///|
fn instance_enqueue_flow(
  instance : ProcessInstance,
  flow : SequenceFlow,
) -> Unit {
  instance_record(
    instance,
    FlowSelected,
    flow.id,
    flow.source + " -> " + flow.target,
  )
  instance.active_tokens.push(flow.target)
}

///|
/// Create a validated resumable instance. Call `advance_instance` to run it.
pub fn start_instance(
  process : ProcessModel,
  variables : VariableSet,
) -> InstanceStartResult {
  let report = validate(process)
  if !report.is_valid() {
    return InstanceRejected(report)
  }
  let active_tokens : Array[String] = []
  for node in process.nodes {
    if node.kind == StartEvent {
      active_tokens.push(node.id)
    }
  }
  InstanceStarted({
    process_id: process.id,
    status: InstanceReady,
    active_tokens,
    waiting_tasks: [],
    variables: variables.copy(),
    events: [],
    parallel_arrivals: [],
    steps: 0,
  })
}

///|
fn select_instance_branch(
  process : ProcessModel,
  instance : ProcessInstance,
  node : ProcessNode,
) -> SequenceFlow? {
  let mut selected : SequenceFlow? = None
  let mut default_flow : SequenceFlow? = None
  for flow in process.outgoing_flows(node.id) {
    match flow.condition {
      None => default_flow = Some(flow)
      Some(expression) =>
        match evaluate_condition(expression, instance.variables) {
          ConditionMatched(true) =>
            if selected is None {
              selected = Some(flow)
            }
          ConditionMatched(false) => ()
          UnknownVariable(name) => {
            instance_fail(instance, "unknown condition variable: " + name)
            return None
          }
          NonBooleanVariable(name) => {
            instance_fail(
              instance,
              "condition variable is not boolean: " + name,
            )
            return None
          }
        }
    }
  }
  if selected is None {
    selected = default_flow
  }
  selected
}

///|
/// Advance automatic nodes until a task waits, the process terminates, or the
/// per-call step budget is exhausted. A ready instance can be advanced again.
pub fn advance_instance(
  process : ProcessModel,
  instance : ProcessInstance,
  max_steps : Int,
) -> Unit {
  if process.id != instance.process_id {
    instance_fail(instance, "instance process id does not match model")
    return
  }
  match instance.status {
    InstanceCompleted | InstanceFailed(_) => return
    _ => ()
  }
  if instance.waiting_tasks.length() > 0 {
    instance.status = InstanceWaiting
    return
  }
  instance.status = InstanceRunning
  let mut call_steps = 0
  while instance.active_tokens.length() > 0 &&
        instance.waiting_tasks.length() == 0 &&
        call_steps < max_steps {
    let node_id = instance.active_tokens.remove(0)
    instance.steps = instance.steps + 1
    call_steps = call_steps + 1
    instance_record(instance, NodeEntered, node_id, "token entered node")
    let node = match process.find_node(node_id) {
      Some(node) => node
      None => {
        instance_fail(instance, "token reached missing node: " + node_id)
        return
      }
    }
    let outgoing = process.outgoing_flows(node.id)
    match node.kind {
      EndEvent => ()
      Task => {
        instance.waiting_tasks.push(node.id)
        instance_record(instance, TaskWaiting, node.id, "task is waiting")
      }
      ExclusiveGateway =>
        match select_instance_branch(process, instance, node) {
          Some(flow) => instance_enqueue_flow(instance, flow)
          None =>
            if !(instance.status is InstanceFailed(_)) {
              instance_fail(
                instance,
                "exclusive gateway has no matching branch: " + node.id,
              )
            }
        }
      ParallelGateway => {
        let required = process.incoming_count(node.id)
        let mut arrivals = 0
        if required > 1 {
          instance.parallel_arrivals.push(node.id)
          for arrived_id in instance.parallel_arrivals {
            if arrived_id == node.id {
              arrivals = arrivals + 1
            }
          }
        }
        if required <= 1 || arrivals % required == 0 {
          for flow in outgoing {
            instance_enqueue_flow(instance, flow)
          }
        }
      }
      StartEvent => {
        if outgoing.length() != 1 {
          instance_fail(
            instance, "start event requires exactly one outgoing flow",
          )
          return
        }
        instance_enqueue_flow(instance, outgoing[0])
      }
    }
    if instance.status is InstanceFailed(_) {
      return
    }
  }
  if instance.waiting_tasks.length() > 0 {
    instance.status = InstanceWaiting
  } else if instance.active_tokens.length() == 0 {
    instance.status = InstanceCompleted
    instance_record(
      instance,
      ProcessCompleted,
      process.id,
      "execution completed",
    )
  } else {
    instance.status = InstanceReady
  }
}

///|
/// Complete one waiting task and release its outgoing token.
pub fn complete_task(
  process : ProcessModel,
  instance : ProcessInstance,
  task_id : String,
) -> TaskCompletionResult {
  let mut waiting_index : Int? = None
  for index, waiting_id in instance.waiting_tasks {
    if waiting_id == task_id {
      waiting_index = Some(index)
      break
    }
  }
  let index = match waiting_index {
    None => return TaskNotWaiting
    Some(index) => index
  }
  let node = match process.find_node(task_id) {
    None => return TaskCompletionFailed("waiting task is missing from model")
    Some(node) => node
  }
  if node.kind != Task {
    return TaskCompletionFailed("waiting element is not a task")
  }
  let outgoing = process.outgoing_flows(task_id)
  if outgoing.length() != 1 {
    return TaskCompletionFailed("task requires exactly one outgoing flow")
  }
  ignore(instance.waiting_tasks.remove(index))
  instance_record(instance, TaskCompleted, task_id, "task completed")
  instance_enqueue_flow(instance, outgoing[0])
  instance.status = if instance.waiting_tasks.length() == 0 {
    InstanceReady
  } else {
    InstanceWaiting
  }
  TaskCompletedSuccessfully
}
