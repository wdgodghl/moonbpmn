///|
fn escape_dot(value : String) -> String {
  value
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\"", new="\\\"")
  .replace_all(old="\n", new="\\n")
}

///|
fn dot_shape(kind : NodeKind) -> String {
  match kind {
    StartEvent => "circle"
    EndEvent => "doublecircle"
    Task => "box"
    ExclusiveGateway => "diamond"
    ParallelGateway => "diamond"
  }
}

///|
fn dot_flow_label(flow : SequenceFlow) -> String {
  match flow.condition {
    Some(condition) => condition
    None => flow.name
  }
}

///|
/// Export a process as deterministic Graphviz DOT source.
pub fn to_dot(process : ProcessModel) -> String {
  let mut output = "digraph \"" +
    escape_dot(process.id) +
    "\" {\n  rankdir=LR;\n"
  for node in process.nodes {
    output = output +
      "  \"" +
      escape_dot(node.id) +
      "\" [label=\"" +
      escape_dot(node.name) +
      "\", shape=" +
      dot_shape(node.kind) +
      "];\n"
  }
  for flow in process.flows {
    output = output +
      "  \"" +
      escape_dot(flow.source) +
      "\" -> \"" +
      escape_dot(flow.target) +
      "\""
    let label = dot_flow_label(flow)
    if label != "" {
      output = output + " [label=\"" + escape_dot(label) + "\"]"
    }
    output = output + ";\n"
  }
  output + "}\n"
}
