///|
fn round_trip_model() -> @moonbpmn.ProcessModel {
  let process = @moonbpmn.ProcessModel::new("approval", "Order & approval")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::exclusive_gateway("choice", "A < B?"))
  process.add_node(@moonbpmn.ProcessNode::end_event("yes", "Accepted"))
  process.add_node(@moonbpmn.ProcessNode::end_event("no", "Rejected"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "choice"))
  process.add_flow(
    @moonbpmn.SequenceFlow::conditional(
      "yes_flow", "choice", "yes", "yes", "approved",
    ),
  )
  process.add_flow(@moonbpmn.SequenceFlow::new("no_flow", "choice", "no"))
  process
}

///|
test "BPMN XML exporter emits escaped deterministic XML" {
  let xml = @moonbpmn.export_bpmn_xml(round_trip_model())
  assert_true(xml.contains("name=\"Order &amp; approval\""))
  assert_true(xml.contains("name=\"A &lt; B?\""))
  assert_true(
    xml.contains(
      "<bpmn:conditionExpression>approved</bpmn:conditionExpression>",
    ),
  )
}

///|
test "BPMN XML export can be imported without semantic loss" {
  let xml = @moonbpmn.export_bpmn_xml(round_trip_model())
  match @moonbpmn.import_bpmn_xml(xml) {
    ImportFailure(_) => fail("expected exported XML to import")
    ImportSuccess(process, issues) => {
      assert_eq(issues.length(), 0)
      assert_eq(process.id, "approval")
      assert_eq(process.name, "Order & approval")
      assert_eq(process.node_count(), 4)
      assert_eq(process.flow_count(), 3)
      assert_true(@moonbpmn.validate(process).is_valid())
      match process.find_flow("yes_flow") {
        None => fail("expected yes_flow")
        Some(flow) => assert_eq(flow.condition, Some("approved"))
      }
    }
  }
}
