///|
fn snapshot_process() -> @moonbpmn.ProcessModel {
  let process = @moonbpmn.ProcessModel::new("snapshot", "Snapshot")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::task("approve", "Approve"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "approve"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "approve", "done"))
  process
}

///|
test "snapshot restores an independently resumable task instance" {
  let process = snapshot_process()
  match @moonbpmn.start_instance(process, @moonbpmn.VariableSet::new()) {
    InstanceRejected(_) => fail("valid process should start")
    InstanceStarted(live) => {
      @moonbpmn.advance_instance(process, live, 20)
      let snapshot = @moonbpmn.snapshot_instance(live)
      ignore(@moonbpmn.complete_task(process, live, "approve"))
      @moonbpmn.advance_instance(process, live, 20)
      assert_eq(live.status, @moonbpmn.InstanceStatus::InstanceCompleted)
      assert_eq(snapshot.waiting_tasks, ["approve"])
      match @moonbpmn.restore_instance(process, snapshot) {
        RestoreFailure(message) => fail(message)
        RestoreSuccess(restored) => {
          assert_eq(restored.status, @moonbpmn.InstanceStatus::InstanceWaiting)
          assert_eq(restored.waiting_tasks, ["approve"])
          ignore(@moonbpmn.complete_task(process, restored, "approve"))
          @moonbpmn.advance_instance(process, restored, 20)
          assert_eq(
            restored.status,
            @moonbpmn.InstanceStatus::InstanceCompleted,
          )
        }
      }
    }
  }
}

///|
test "restore rejects a snapshot for another process" {
  let process = snapshot_process()
  match @moonbpmn.start_instance(process, @moonbpmn.VariableSet::new()) {
    InstanceRejected(_) => fail("valid process should start")
    InstanceStarted(instance) => {
      let snapshot = @moonbpmn.snapshot_instance(instance)
      let other = @moonbpmn.ProcessModel::new("other", "Other")
      match @moonbpmn.restore_instance(other, snapshot) {
        RestoreSuccess(_) => fail("expected process id mismatch")
        RestoreFailure(message) =>
          assert_eq(message, "snapshot process id does not match model")
      }
    }
  }
}

///|
test "restore rejects tokens that reference missing nodes" {
  let process = snapshot_process()
  match @moonbpmn.start_instance(process, @moonbpmn.VariableSet::new()) {
    InstanceRejected(_) => fail("valid process should start")
    InstanceStarted(instance) => {
      let snapshot = @moonbpmn.snapshot_instance(instance)
      snapshot.active_tokens[0] = "missing"
      match @moonbpmn.restore_instance(process, snapshot) {
        RestoreSuccess(_) => fail("expected invalid token rejection")
        RestoreFailure(message) =>
          assert_eq(message, "snapshot token references missing node: missing")
      }
    }
  }
}
