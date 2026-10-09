///|
/// Terminal outcome of a deterministic process run.
pub(all) enum RunStatus {
  RunCompleted
  RunInvalidModel
  RunStalled(String)
  RunStepLimitExceeded
} derive(Eq, Debug)

///|
pub extend RunStatus with Eq::{equal, not_equal}

///|
pub extend RunStatus with Debug::{to_repr}

///|
/// Stable event kinds emitted by the in-memory runner.
pub(all) enum ExecutionEventKind {
  NodeEntered
  FlowSelected
  TaskWaiting
  TaskCompleted
  ProcessCompleted
  ExecutionStopped
} derive(Eq, Debug)

///|
pub extend ExecutionEventKind with Eq::{equal, not_equal}

///|
pub extend ExecutionEventKind with Debug::{to_repr}

///|
/// One append-only execution event. Sequence numbers start at zero.
pub(all) struct ExecutionEvent {
  sequence : Int
  kind : ExecutionEventKind
  element_id : String
  detail : String
}

///|
/// Immutable result returned by the bounded in-memory runner.
pub(all) struct ExecutionResult {
  status : RunStatus
  visited_nodes : Array[String]
  selected_flows : Array[String]
  events : Array[ExecutionEvent]
  steps : Int
}

///|
pub fn ExecutionResult::is_completed(self : ExecutionResult) -> Bool {
  self.status == RunCompleted
}

///|
fn record_event(
  events : Array[ExecutionEvent],
  kind : ExecutionEventKind,
  element_id : String,
  detail : String,
) -> Unit {
  events.push({ sequence: events.length(), kind, element_id, detail, })
}

///|
fn enqueue_flow(
  queue : Array[String],
  selected_flows : Array[String],
  events : Array[ExecutionEvent],
  flow : SequenceFlow,
) -> Unit {
  selected_flows.push(flow.id)
  record_event(
    events,
    FlowSelected,
    flow.id,
    flow.source + " -> " + flow.target,
  )
  queue.push(flow.target)
}

///|
fn stalled(
  message : String,
  visited_nodes : Array[String],
  selected_flows : Array[String],
  events : Array[ExecutionEvent],
  steps : Int,
) -> ExecutionResult {
  record_event(events, ExecutionStopped, "", message)
  { status: RunStalled(message), visited_nodes, selected_flows, events, steps, }
}

///|
/// Execute the supported BPMN subset with a deterministic FIFO token queue.
///
/// Tasks complete immediately in this library-level runner. Exclusive gateways
/// select the first true conditional flow in declaration order and fall back to
/// the single unconditional flow. Parallel gateways emit one token per outgoing
/// flow and synchronize joins. `max_steps` bounds cycles and malformed models.
pub fn run(
  process : ProcessModel,
  variables : VariableSet,
  max_steps : Int,
) -> ExecutionResult {
  if !validate(process).is_valid() {
    let events : Array[ExecutionEvent] = []
    record_event(events, ExecutionStopped, process.id, "model is invalid")
    return {
      status: RunInvalidModel,
      visited_nodes: [],
      selected_flows: [],
      events,
      steps: 0,
    }
  }
  let queue : Array[String] = []
  let visited_nodes : Array[String] = []
  let selected_flows : Array[String] = []
  let events : Array[ExecutionEvent] = []
  let parallel_arrivals : Array[String] = []
  for node in process.nodes {
    if node.kind == StartEvent {
      queue.push(node.id)
    }
  }
  let mut cursor = 0
  let mut steps = 0
  let mut completed_tokens = 0
  while cursor < queue.length() {
    if steps >= max_steps {
      record_event(events, ExecutionStopped, "", "step limit exceeded")
      return {
        status: RunStepLimitExceeded,
        visited_nodes,
        selected_flows,
        events,
        steps,
      }
    }
    let node_id = queue[cursor]
    cursor = cursor + 1
    steps = steps + 1
    visited_nodes.push(node_id)
    record_event(events, NodeEntered, node_id, "token entered node")
    let node = match process.find_node(node_id) {
      Some(node) => node
      None =>
        return stalled(
          "token reached missing node: " + node_id,
          visited_nodes,
          selected_flows,
          events,
          steps,
        )
    }
    let outgoing = process.outgoing_flows(node.id)
    match node.kind {
      EndEvent => completed_tokens = completed_tokens + 1
      ExclusiveGateway => {
        let mut selected : SequenceFlow? = None
        let mut default_flow : SequenceFlow? = None
        for flow in outgoing {
          match flow.condition {
            None => default_flow = Some(flow)
            Some(expression) =>
              match evaluate_condition(expression, variables) {
                ConditionMatched(true) =>
                  if selected is None {
                    selected = Some(flow)
                  }
                ConditionMatched(false) => ()
                UnknownVariable(name) =>
                  return stalled(
                    "unknown condition variable: " + name,
                    visited_nodes,
                    selected_flows,
                    events,
                    steps,
                  )
                NonBooleanVariable(name) =>
                  return stalled(
                    "condition variable is not boolean: " + name,
                    visited_nodes,
                    selected_flows,
                    events,
                    steps,
                  )
              }
          }
        }
        if selected is None {
          selected = default_flow
        }
        match selected {
          Some(flow) => enqueue_flow(queue, selected_flows, events, flow)
          None =>
            return stalled(
              "exclusive gateway has no matching branch: " + node.id,
              visited_nodes,
              selected_flows,
              events,
              steps,
            )
        }
      }
      ParallelGateway => {
        let required = process.incoming_count(node.id)
        let mut arrivals = 0
        if required > 1 {
          parallel_arrivals.push(node.id)
          for arrived_id in parallel_arrivals {
            if arrived_id == node.id {
              arrivals = arrivals + 1
            }
          }
        }
        if required <= 1 || arrivals % required == 0 {
          for flow in outgoing {
            enqueue_flow(queue, selected_flows, events, flow)
          }
        }
      }
      StartEvent | Task => {
        if outgoing.length() != 1 {
          return stalled(
            "node requires exactly one outgoing flow: " + node.id,
            visited_nodes,
            selected_flows,
            events,
            steps,
          )
        }
        enqueue_flow(queue, selected_flows, events, outgoing[0])
      }
    }
  }
  if completed_tokens > 0 {
    record_event(events, ProcessCompleted, process.id, "execution completed")
    { status: RunCompleted, visited_nodes, selected_flows, events, steps, }
  } else {
    stalled(
      "execution ended without an end event", visited_nodes, selected_flows, events,
      steps,
    )
  }
}
