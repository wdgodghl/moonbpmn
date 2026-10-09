///|
fn two_task_process() -> @moonbpmn.ProcessModel {
  let process = @moonbpmn.ProcessModel::new("resumable", "Resumable")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::task("first", "First"))
  process.add_node(@moonbpmn.ProcessNode::task("second", "Second"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "first"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "first", "second"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f3", "second", "done"))
  process
}

///|
test "resumable instance waits for and completes tasks" {
  let process = two_task_process()
  match @moonbpmn.start_instance(process, @moonbpmn.VariableSet::new()) {
    InstanceRejected(_) => fail("valid process should start")
    InstanceStarted(instance) => {
      @moonbpmn.advance_instance(process, instance, 20)
      assert_eq(instance.status, @moonbpmn.InstanceStatus::InstanceWaiting)
      assert_eq(instance.waiting_tasks, ["first"])
      assert_eq(
        @moonbpmn.complete_task(process, instance, "first"),
        @moonbpmn.TaskCompletionResult::TaskCompletedSuccessfully,
      )
      @moonbpmn.advance_instance(process, instance, 20)
      assert_eq(instance.waiting_tasks, ["second"])
      ignore(@moonbpmn.complete_task(process, instance, "second"))
      @moonbpmn.advance_instance(process, instance, 20)
      assert_eq(instance.status, @moonbpmn.InstanceStatus::InstanceCompleted)
      assert_eq(instance.steps, 4)
    }
  }
}

///|
test "resumable instance rejects completion of a task not waiting" {
  let process = two_task_process()
  match @moonbpmn.start_instance(process, @moonbpmn.VariableSet::new()) {
    InstanceRejected(_) => fail("valid process should start")
    InstanceStarted(instance) =>
      assert_eq(
        @moonbpmn.complete_task(process, instance, "second"),
        @moonbpmn.TaskCompletionResult::TaskNotWaiting,
      )
  }
}

///|
test "resumable instance honors a per-call step budget" {
  let process = two_task_process()
  match @moonbpmn.start_instance(process, @moonbpmn.VariableSet::new()) {
    InstanceRejected(_) => fail("valid process should start")
    InstanceStarted(instance) => {
      @moonbpmn.advance_instance(process, instance, 1)
      assert_eq(instance.status, @moonbpmn.InstanceStatus::InstanceReady)
      assert_eq(instance.active_tokens, ["first"])
      @moonbpmn.advance_instance(process, instance, 1)
      assert_eq(instance.status, @moonbpmn.InstanceStatus::InstanceWaiting)
    }
  }
}
