///|
test "process metadata replaces values by namespace and name" {
  let process = @moonbpmn.ProcessModel::new("metadata", "Metadata")
  process.set_extension("urn:example:audit", "owner", "alice")
  process.set_extension("urn:example:audit", "owner", "bob")
  process.set_extension("urn:example:ui", "owner", "team-blue")
  assert_eq(process.extensions.length(), 2)
  assert_eq(process.get_extension("urn:example:audit", "owner"), Some("bob"))
  assert_eq(process.get_extension("urn:example:ui", "owner"), Some("team-blue"))
}

///|
test "node and flow metadata are independent and removable" {
  let node = @moonbpmn.ProcessNode::task("review", "Review")
  let flow = @moonbpmn.SequenceFlow::new("f1", "start", "review")
  node.set_extension("urn:example", "form", "review-form")
  flow.set_extension("urn:example", "priority", "high")
  assert_eq(node.get_extension("urn:example", "form"), Some("review-form"))
  assert_eq(flow.get_extension("urn:example", "form"), None)
  assert_true(flow.remove_extension("urn:example", "priority"))
  assert_false(flow.remove_extension("urn:example", "priority"))
}
