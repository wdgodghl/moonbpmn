///|
/// The BPMN flow-node kinds supported by the first executable subset.
pub(all) enum NodeKind {
  StartEvent
  EndEvent
  Task
  ExclusiveGateway
  ParallelGateway
} derive(Eq)

///|
pub extend NodeKind with Eq::{equal, not_equal}

///|
/// A node in a BPMN process graph.
pub(all) struct ProcessNode {
  id : String
  name : String
  kind : NodeKind
}

///|
pub fn ProcessNode::new(
  id : String,
  name : String,
  kind : NodeKind,
) -> ProcessNode {
  { id, name, kind, }
}

///|
pub fn ProcessNode::start_event(id : String, name : String) -> ProcessNode {
  { id, name, kind: StartEvent, }
}

///|
pub fn ProcessNode::end_event(id : String, name : String) -> ProcessNode {
  { id, name, kind: EndEvent, }
}

///|
pub fn ProcessNode::task(id : String, name : String) -> ProcessNode {
  { id, name, kind: Task, }
}

///|
pub fn ProcessNode::exclusive_gateway(
  id : String,
  name : String,
) -> ProcessNode {
  { id, name, kind: ExclusiveGateway, }
}

///|
pub fn ProcessNode::parallel_gateway(id : String, name : String) -> ProcessNode {
  { id, name, kind: ParallelGateway, }
}

///|
/// A directed connection between two process nodes.
pub(all) struct SequenceFlow {
  id : String
  source : String
  target : String
  name : String
  condition : String?
}

///|
pub fn SequenceFlow::new(
  id : String,
  source : String,
  target : String,
) -> SequenceFlow {
  { id, source, target, name: "", condition: None, }
}

///|
pub fn SequenceFlow::named(
  id : String,
  source : String,
  target : String,
  name : String,
) -> SequenceFlow {
  { id, source, target, name, condition: None, }
}

///|
pub fn SequenceFlow::conditional(
  id : String,
  source : String,
  target : String,
  name : String,
  condition : String,
) -> SequenceFlow {
  { id, source, target, name, condition: Some(condition), }
}

///|
/// A mutable builder-friendly representation of one BPMN process.
pub(all) struct ProcessModel {
  id : String
  name : String
  nodes : Array[ProcessNode]
  flows : Array[SequenceFlow]
}

///|
pub fn ProcessModel::new(id : String, name : String) -> ProcessModel {
  { id, name, nodes: [], flows: [], }
}

///|
pub fn ProcessModel::add_node(self : ProcessModel, node : ProcessNode) -> Unit {
  self.nodes.push(node)
}

///|
pub fn ProcessModel::add_flow(self : ProcessModel, flow : SequenceFlow) -> Unit {
  self.flows.push(flow)
}

///|
pub fn ProcessModel::node_count(self : ProcessModel) -> Int {
  self.nodes.length()
}

///|
pub fn ProcessModel::flow_count(self : ProcessModel) -> Int {
  self.flows.length()
}

///|
pub fn ProcessModel::find_node(
  self : ProcessModel,
  id : String,
) -> ProcessNode? {
  for node in self.nodes {
    if node.id == id {
      return Some(node)
    }
  }
  None
}

///|
/// Find a sequence flow by its stable BPMN identifier.
pub fn ProcessModel::find_flow(
  self : ProcessModel,
  id : String,
) -> SequenceFlow? {
  for flow in self.flows {
    if flow.id == id {
      return Some(flow)
    }
  }
  None
}

///|
/// Return all outgoing flows in their declaration order.
pub fn ProcessModel::outgoing_flows(
  self : ProcessModel,
  node_id : String,
) -> Array[SequenceFlow] {
  let result : Array[SequenceFlow] = []
  for flow in self.flows {
    if flow.source == node_id {
      result.push(flow)
    }
  }
  result
}

///|
/// Return all incoming flows in their declaration order.
pub fn ProcessModel::incoming_flows(
  self : ProcessModel,
  node_id : String,
) -> Array[SequenceFlow] {
  let result : Array[SequenceFlow] = []
  for flow in self.flows {
    if flow.target == node_id {
      result.push(flow)
    }
  }
  result
}

///|
/// Return direct successor node ids without resolving missing references.
pub fn ProcessModel::successor_ids(
  self : ProcessModel,
  node_id : String,
) -> Array[String] {
  let result : Array[String] = []
  for flow in self.flows {
    if flow.source == node_id {
      result.push(flow.target)
    }
  }
  result
}

///|
/// Return direct predecessor node ids without resolving missing references.
pub fn ProcessModel::predecessor_ids(
  self : ProcessModel,
  node_id : String,
) -> Array[String] {
  let result : Array[String] = []
  for flow in self.flows {
    if flow.target == node_id {
      result.push(flow.source)
    }
  }
  result
}

///|
pub fn ProcessModel::incoming_count(
  self : ProcessModel,
  node_id : String,
) -> Int {
  let mut count = 0
  for flow in self.flows {
    if flow.target == node_id {
      count = count + 1
    }
  }
  count
}

///|
pub fn ProcessModel::outgoing_count(
  self : ProcessModel,
  node_id : String,
) -> Int {
  let mut count = 0
  for flow in self.flows {
    if flow.source == node_id {
      count = count + 1
    }
  }
  count
}
