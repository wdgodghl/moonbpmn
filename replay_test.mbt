///|
fn replay_linear_process() -> @moonbpmn.ProcessModel {
  let process = @moonbpmn.ProcessModel::new("replay", "Replay")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::task("work", "Work"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "work"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "work", "done"))
  process
}

///|
test "event replay reconstructs execution history" {
  let execution = @moonbpmn.run(
    replay_linear_process(),
    @moonbpmn.VariableSet::new(),
    20,
  )
  match @moonbpmn.replay(execution.events) {
    ReplayFailure(message) => fail(message)
    ReplaySuccess(summary) => {
      assert_true(summary.completed)
      assert_eq(summary.visited_nodes, ["start", "work", "done"])
      assert_eq(summary.selected_flows, ["f1", "f2"])
      assert_eq(summary.event_count, execution.events.length())
    }
  }
}

///|
test "event replay rejects sequence gaps" {
  let events : Array[@moonbpmn.ExecutionEvent] = [
    {
      sequence: 1,
      kind: @moonbpmn.ExecutionEventKind::ExecutionStopped,
      element_id: "",
      detail: "stopped",
    },
  ]
  match @moonbpmn.replay(events) {
    ReplaySuccess(_) => fail("expected sequence validation failure")
    ReplayFailure(message) =>
      assert_eq(message, "non-contiguous event sequence at index 0")
  }
}

///|
test "event replay rejects unterminated streams" {
  let events : Array[@moonbpmn.ExecutionEvent] = [
    {
      sequence: 0,
      kind: @moonbpmn.ExecutionEventKind::NodeEntered,
      element_id: "start",
      detail: "token entered node",
    },
  ]
  match @moonbpmn.replay(events) {
    ReplaySuccess(_) => fail("expected terminal event validation failure")
    ReplayFailure(message) =>
      assert_eq(message, "event stream has no terminal event")
  }
}
