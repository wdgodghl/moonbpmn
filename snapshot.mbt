///|
/// Detached copy of every state component needed to resume an instance.
pub(all) struct InstanceSnapshot {
  process_id : String
  status : InstanceStatus
  active_tokens : Array[String]
  waiting_tasks : Array[String]
  variables : VariableSet
  events : Array[ExecutionEvent]
  parallel_arrivals : Array[String]
  steps : Int
}

///|
pub(all) enum RestoreResult {
  RestoreSuccess(ProcessInstance)
  RestoreFailure(String)
}

///|
/// Capture an independent snapshot. Later mutations of the live instance do
/// not change the snapshot's arrays, variables, or event history.
pub fn snapshot_instance(instance : ProcessInstance) -> InstanceSnapshot {
  {
    process_id: instance.process_id,
    status: instance.status,
    active_tokens: instance.active_tokens.copy(),
    waiting_tasks: instance.waiting_tasks.copy(),
    variables: instance.variables.copy(),
    events: instance.events.copy(),
    parallel_arrivals: instance.parallel_arrivals.copy(),
    steps: instance.steps,
  }
}

///|
fn validate_snapshot_events(events : Array[ExecutionEvent]) -> String? {
  for index, event in events {
    if event.sequence != index {
      return Some(
        "snapshot has non-contiguous event sequence at index " +
        index.to_string(),
      )
    }
  }
  None
}

///|
fn validate_snapshot_nodes(
  process : ProcessModel,
  snapshot : InstanceSnapshot,
) -> String? {
  for node_id in snapshot.active_tokens {
    if process.find_node(node_id) is None {
      return Some("snapshot token references missing node: " + node_id)
    }
  }
  for task_id in snapshot.waiting_tasks {
    match process.find_node(task_id) {
      None => return Some("snapshot references missing task: " + task_id)
      Some(node) =>
        if node.kind != Task {
          return Some("snapshot waiting element is not a task: " + task_id)
        }
    }
  }
  None
}

///|
fn validate_snapshot_status(snapshot : InstanceSnapshot) -> String? {
  match snapshot.status {
    InstanceWaiting =>
      if snapshot.waiting_tasks.length() == 0 {
        Some("waiting snapshot has no waiting task")
      } else {
        None
      }
    InstanceCompleted =>
      if snapshot.active_tokens.length() > 0 ||
        snapshot.waiting_tasks.length() > 0 {
        Some("completed snapshot still contains active work")
      } else {
        None
      }
    InstanceRunning => Some("running instances cannot be restored")
    InstanceReady | InstanceFailed(_) => None
  }
}

///|
/// Validate and restore an instance against the process definition it belongs
/// to. Invalid or tampered snapshots are rejected before execution resumes.
pub fn restore_instance(
  process : ProcessModel,
  snapshot : InstanceSnapshot,
) -> RestoreResult {
  if process.id != snapshot.process_id {
    return RestoreFailure("snapshot process id does not match model")
  }
  if !validate(process).is_valid() {
    return RestoreFailure("cannot restore against an invalid process model")
  }
  match validate_snapshot_events(snapshot.events) {
    Some(message) => return RestoreFailure(message)
    None => ()
  }
  match validate_snapshot_nodes(process, snapshot) {
    Some(message) => return RestoreFailure(message)
    None => ()
  }
  match validate_snapshot_status(snapshot) {
    Some(message) => return RestoreFailure(message)
    None => ()
  }
  RestoreSuccess({
    process_id: snapshot.process_id,
    status: snapshot.status,
    active_tokens: snapshot.active_tokens.copy(),
    waiting_tasks: snapshot.waiting_tasks.copy(),
    variables: snapshot.variables.copy(),
    events: snapshot.events.copy(),
    parallel_arrivals: snapshot.parallel_arrivals.copy(),
    steps: snapshot.steps,
  })
}
