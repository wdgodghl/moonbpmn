///|
fn mermaid_node(node : ProcessNode) -> String {
  match node.kind {
    StartEvent => "  " + node.id + "((\"" + node.name + "\"))\n"
    EndEvent => "  " + node.id + "(((\"" + node.name + "\")))\n"
    Task => "  " + node.id + "[\"" + node.name + "\"]\n"
    ExclusiveGateway => "  " + node.id + "{\"" + node.name + "\"}\n"
    ParallelGateway => "  " + node.id + "{{\"" + node.name + "\"}}\n"
  }
}

///|
fn mermaid_flow(flow : SequenceFlow) -> String {
  let label = match flow.condition {
    Some(condition) => condition
    None => flow.name
  }
  if label == "" {
    "  " + flow.source + " --> " + flow.target + "\n"
  } else {
    "  " + flow.source + " -->|" + label + "| " + flow.target + "\n"
  }
}

///|
/// Export a process graph as a deterministic Mermaid flowchart.
///
/// Declaration order is preserved so generated diagrams produce stable diffs.
/// Callers should validate externally sourced labels before embedding the output
/// into an untrusted HTML page.
pub fn to_mermaid(process : ProcessModel) -> String {
  let mut output = "flowchart TD\n"
  for node in process.nodes {
    output = output + mermaid_node(node)
  }
  for flow in process.flows {
    output = output + mermaid_flow(flow)
  }
  output
}
