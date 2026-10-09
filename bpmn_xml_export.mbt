///|
fn escape_xml(value : String) -> String {
  value
  .replace_all(old="&", new="&amp;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&apos;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
}

///|
fn bpmn_node_element(kind : NodeKind) -> String {
  match kind {
    StartEvent => "startEvent"
    EndEvent => "endEvent"
    Task => "task"
    ExclusiveGateway => "exclusiveGateway"
    ParallelGateway => "parallelGateway"
  }
}

///|
fn export_node(node : ProcessNode) -> String {
  "    <bpmn:" +
  bpmn_node_element(node.kind) +
  " id=\"" +
  escape_xml(node.id) +
  "\" name=\"" +
  escape_xml(node.name) +
  "\" />\n"
}

///|
fn export_flow(flow : SequenceFlow) -> String {
  let opening = "    <bpmn:sequenceFlow id=\"" +
    escape_xml(flow.id) +
    "\" sourceRef=\"" +
    escape_xml(flow.source) +
    "\" targetRef=\"" +
    escape_xml(flow.target) +
    "\" name=\"" +
    escape_xml(flow.name) +
    "\""
  match flow.condition {
    None => opening + " />\n"
    Some(condition) =>
      opening +
      ">\n      <bpmn:conditionExpression>" +
      escape_xml(condition) +
      "</bpmn:conditionExpression>\n    </bpmn:sequenceFlow>\n"
  }
}

///|
/// Export the supported process model as deterministic BPMN 2.0 XML.
///
/// Elements retain declaration order, all identifiers and labels are escaped,
/// and conditions use portable text content rather than engine-specific syntax.
pub fn export_bpmn_xml(process : ProcessModel) -> String {
  let mut output = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<bpmn:definitions xmlns:bpmn=\"http://www.omg.org/spec/BPMN/20100524/MODEL\">\n" +
    "  <bpmn:process id=\"" +
    escape_xml(process.id) +
    "\" name=\"" +
    escape_xml(process.name) +
    "\" isExecutable=\"true\">\n"
  for node in process.nodes {
    output = output + export_node(node)
  }
  for flow in process.flows {
    output = output + export_flow(flow)
  }
  output + "  </bpmn:process>\n</bpmn:definitions>\n"
}
