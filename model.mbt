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
  extensions : Array[ExtensionProperty]
}

///|
pub fn ProcessNode::new(
  id : String,
  name : String,
  kind : NodeKind,
) -> ProcessNode {
  { id, name, kind, extensions: [], }
}

///|
pub fn ProcessNode::start_event(id : String, name : String) -> ProcessNode {
  { id, name, kind: StartEvent, extensions: [], }
}

///|
pub fn ProcessNode::end_event(id : String, name : String) -> ProcessNode {
  { id, name, kind: EndEvent, extensions: [], }
}

///|
pub fn ProcessNode::task(id : String, name : String) -> ProcessNode {
  { id, name, kind: Task, extensions: [], }
}

///|
pub fn ProcessNode::exclusive_gateway(
  id : String,
  name : String,
) -> ProcessNode {
  { id, name, kind: ExclusiveGateway, extensions: [], }
}

///|
pub fn ProcessNode::parallel_gateway(id : String, name : String) -> ProcessNode {
  { id, name, kind: ParallelGateway, extensions: [], }
}

///|
pub fn ProcessNode::set_extension(
  self : ProcessNode,
  namespace_uri : String,
  name : String,
  value : String,
) -> Unit {
  set_extension_property(
    self.extensions,
    ExtensionProperty::new(namespace_uri, name, value),
  )
}

///|
pub fn ProcessNode::get_extension(
  self : ProcessNode,
  namespace_uri : String,
  name : String,
) -> String? {
  get_extension_property(self.extensions, namespace_uri, name)
}

///|
pub fn ProcessNode::remove_extension(
  self : ProcessNode,
  namespace_uri : String,
  name : String,
) -> Bool {
  remove_extension_property(self.extensions, namespace_uri, name)
}

///|
/// A directed connection between two process nodes.
pub(all) struct SequenceFlow {
  id : String
  source : String
  target : String
  name : String
  condition : String?
  extensions : Array[ExtensionProperty]
}

///|
pub fn SequenceFlow::new(
  id : String,
  source : String,
  target : String,
) -> SequenceFlow {
  { id, source, target, name: "", condition: None, extensions: [], }
}

///|
pub fn SequenceFlow::named(
  id : String,
  source : String,
  target : String,
  name : String,
) -> SequenceFlow {
  { id, source, target, name, condition: None, extensions: [], }
}

///|
pub fn SequenceFlow::conditional(
  id : String,
  source : String,
  target : String,
  name : String,
  condition : String,
) -> SequenceFlow {
  { id, source, target, name, condition: Some(condition), extensions: [], }
}

///|
pub fn SequenceFlow::set_extension(
  self : SequenceFlow,
  namespace_uri : String,
  name : String,
  value : String,
) -> Unit {
  set_extension_property(
    self.extensions,
    ExtensionProperty::new(namespace_uri, name, value),
  )
}

///|
pub fn SequenceFlow::get_extension(
  self : SequenceFlow,
  namespace_uri : String,
  name : String,
) -> String? {
  get_extension_property(self.extensions, namespace_uri, name)
}

///|
pub fn SequenceFlow::remove_extension(
  self : SequenceFlow,
  namespace_uri : String,
  name : String,
) -> Bool {
  remove_extension_property(self.extensions, namespace_uri, name)
}

///|
/// A mutable builder-friendly representation of one BPMN process.
pub(all) struct ProcessModel {
  id : String
  name : String
  nodes : Array[ProcessNode]
  flows : Array[SequenceFlow]
  extensions : Array[ExtensionProperty]
}

///|
pub fn ProcessModel::new(id : String, name : String) -> ProcessModel {
  { id, name, nodes: [], flows: [], extensions: [], }
}

///|
pub fn ProcessModel::set_extension(
  self : ProcessModel,
  namespace_uri : String,
  name : String,
  value : String,
) -> Unit {
  set_extension_property(
    self.extensions,
    ExtensionProperty::new(namespace_uri, name, value),
  )
}

///|
pub fn ProcessModel::get_extension(
  self : ProcessModel,
  namespace_uri : String,
  name : String,
) -> String? {
  get_extension_property(self.extensions, namespace_uri, name)
}

///|
pub fn ProcessModel::remove_extension(
  self : ProcessModel,
  namespace_uri : String,
  name : String,
) -> Bool {
  remove_extension_property(self.extensions, namespace_uri, name)
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
