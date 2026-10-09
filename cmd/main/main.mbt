///|
fn build_order_approval() -> @moonbpmn.ProcessModel {
  let process = @moonbpmn.ProcessModel::new("order_approval", "Order approval")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Submitted"))
  process.add_node(@moonbpmn.ProcessNode::task("review", "Review order"))
  process.add_node(
    @moonbpmn.ProcessNode::exclusive_gateway("decision", "Approved?"),
  )
  process.add_node(@moonbpmn.ProcessNode::end_event("approved", "Approved"))
  process.add_node(@moonbpmn.ProcessNode::end_event("rejected", "Rejected"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "review"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "review", "decision"))
  process.add_flow(
    @moonbpmn.SequenceFlow::conditional(
      "approve", "decision", "approved", "approved", "approved",
    ),
  )
  process.add_flow(
    @moonbpmn.SequenceFlow::named("reject", "decision", "rejected", "otherwise"),
  )
  process
}

///|
fn main {
  let source = build_order_approval()
  let xml = @moonbpmn.export_bpmn_xml(source)
  let process = match @moonbpmn.import_bpmn_xml(xml) {
    ImportFailure(issues) => {
      println(
        "BPMN XML import failed with " +
        issues.length().to_string() +
        " issue(s)",
      )
      return
    }
    ImportSuccess(process, issues) => {
      println("BPMN XML import issues: " + issues.length().to_string())
      process
    }
  }
  let report = @moonbpmn.validate(process)
  println("MoonBPMN runnable example")
  println("process: " + process.id)
  println("nodes: " + process.node_count().to_string())
  println("flows: " + process.flow_count().to_string())
  println("validation JSON: " + @moonbpmn.validation_report_json(report))
  if !report.is_valid() {
    println("execution skipped because the model is invalid")
    return
  }
  let variables = @moonbpmn.VariableSet::new()
  variables.set(@moonbpmn.ProcessVariable::bool("approved", true))
  let result = @moonbpmn.run(process, variables, 100)
  println("BPMN XML bytes: " + xml.length().to_string())
  println("execution JSON: " + @moonbpmn.execution_result_json(result))
  match @moonbpmn.replay(result.events) {
    ReplayFailure(message) => println("replay: failed: " + message)
    ReplaySuccess(summary) =>
      println("replay events: " + summary.event_count.to_string())
  }
  println("--- Mermaid ---")
  println(@moonbpmn.to_mermaid(process))
}
