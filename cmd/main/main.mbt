///|
fn main {
  let process = @moonbpmn.ProcessModel::new("order_approval", "Order approval")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Submitted"))
  process.add_node(@moonbpmn.ProcessNode::task("review", "Review order"))
  process.add_node(@moonbpmn.ProcessNode::end_event("approved", "Approved"))
  process.add_flow(@moonbpmn.SequenceFlow::new("flow_1", "start", "review"))
  process.add_flow(@moonbpmn.SequenceFlow::new("flow_2", "review", "approved"))
  let report = @moonbpmn.validate(process)
  println("MoonBPMN order_approval")
  println("nodes: " + process.node_count().to_string())
  println("flows: " + process.flow_count().to_string())
  println(
    if report.is_valid() {
      "validation: PASS"
    } else {
      "validation: FAIL"
    },
  )
}
