///|
/// State reconstructed solely from an append-only execution event stream.
pub(all) struct ReplaySummary {
  visited_nodes : Array[String]
  selected_flows : Array[String]
  completed : Bool
  event_count : Int
}

///|
pub(all) enum ReplayResult {
  ReplaySuccess(ReplaySummary)
  ReplayFailure(String)
}

///|
/// Verify and replay an event log without re-running the process model.
///
/// Sequence numbers must be contiguous, no event may follow a terminal event,
/// and the stream must end in either completion or an explicit stop event.
pub fn replay(events : Array[ExecutionEvent]) -> ReplayResult {
  let visited_nodes : Array[String] = []
  let selected_flows : Array[String] = []
  let mut terminal = false
  let mut completed = false
  for index, event in events {
    if event.sequence != index {
      return ReplayFailure(
        "non-contiguous event sequence at index " + index.to_string(),
      )
    }
    if terminal {
      return ReplayFailure("event appears after terminal event")
    }
    match event.kind {
      NodeEntered => visited_nodes.push(event.element_id)
      FlowSelected => selected_flows.push(event.element_id)
      ProcessCompleted => {
        terminal = true
        completed = true
      }
      ExecutionStopped => terminal = true
    }
  }
  if !terminal {
    return ReplayFailure("event stream has no terminal event")
  }
  ReplaySuccess({
    visited_nodes,
    selected_flows,
    completed,
    event_count: events.length(),
  })
}
