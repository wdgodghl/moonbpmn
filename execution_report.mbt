///|
fn run_status_code(status : RunStatus) -> String {
  match status {
    RunCompleted => "completed"
    RunInvalidModel => "invalid_model"
    RunStalled(_) => "stalled"
    RunStepLimitExceeded => "step_limit_exceeded"
  }
}

///|
fn run_status_message(status : RunStatus) -> String {
  match status {
    RunStalled(message) => message
    RunInvalidModel => "model is invalid"
    RunStepLimitExceeded => "step limit exceeded"
    RunCompleted => ""
  }
}

///|
fn execution_event_kind_name(kind : ExecutionEventKind) -> String {
  match kind {
    NodeEntered => "node_entered"
    FlowSelected => "flow_selected"
    TaskWaiting => "task_waiting"
    TaskCompleted => "task_completed"
    ProcessCompleted => "process_completed"
    ExecutionStopped => "execution_stopped"
  }
}

///|
/// Serialize an execution result and its complete event log as stable JSON.
pub fn execution_result_json(result : ExecutionResult) -> String {
  let visited : Array[Json] = []
  for node_id in result.visited_nodes {
    visited.push(Json::string(node_id))
  }
  let selected : Array[Json] = []
  for flow_id in result.selected_flows {
    selected.push(Json::string(flow_id))
  }
  let events : Array[Json] = []
  for event in result.events {
    events.push({
      "sequence": event.sequence,
      "kind": execution_event_kind_name(event.kind),
      "elementId": event.element_id,
      "detail": event.detail,
    })
  }
  let document : Json = {
    "status": run_status_code(result.status),
    "message": run_status_message(result.status),
    "steps": result.steps,
    "visitedNodes": visited,
    "selectedFlows": selected,
    "events": events,
  }
  document.stringify()
}
