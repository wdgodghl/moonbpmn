///|
let linear_bpmn_xml =
  #|<?xml version="1.0" encoding="UTF-8"?>
  #|<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL">
  #|  <bpmn:process id="order" name="Order &amp; Review" isExecutable="true">
  #|    <bpmn:startEvent id="start" name="Submitted" />
  #|    <bpmn:task id="review" name="Review" />
  #|    <bpmn:endEvent id="done" name="Done" />
  #|    <bpmn:sequenceFlow id="f1" sourceRef="start" targetRef="review" />
  #|    <bpmn:sequenceFlow id="f2" sourceRef="review" targetRef="done" />
  #|  </bpmn:process>
  #|</bpmn:definitions>

///|
test "BPMN XML importer accepts a namespace-prefixed linear process" {
  match @moonbpmn.import_bpmn_xml(linear_bpmn_xml) {
    ImportFailure(_) => fail("expected BPMN import to succeed")
    ImportSuccess(process, issues) => {
      assert_eq(issues.length(), 0)
      assert_eq(process.id, "order")
      assert_eq(process.name, "Order & Review")
      assert_eq(process.node_count(), 3)
      assert_eq(process.flow_count(), 2)
      assert_true(@moonbpmn.validate(process).is_valid())
    }
  }
}

///|
test "BPMN XML importer captures plain condition expressions" {
  let xml =
    #|<definitions><process id="choice"><startEvent id="start"/><exclusiveGateway id="gate"/><endEvent id="yes"/><endEvent id="no"/><sequenceFlow id="f1" sourceRef="start" targetRef="gate"/><sequenceFlow id="f2" sourceRef="gate" targetRef="yes"><conditionExpression>approved</conditionExpression></sequenceFlow><sequenceFlow id="f3" sourceRef="gate" targetRef="no"/></process></definitions>
  match @moonbpmn.import_bpmn_xml(xml) {
    ImportFailure(_) => fail("expected BPMN import to succeed")
    ImportSuccess(process, _) =>
      match process.find_flow("f2") {
        None => fail("expected conditional flow")
        Some(flow) => assert_eq(flow.condition, Some("approved"))
      }
  }
}

///|
test "BPMN XML importer reports unsupported executable elements" {
  let xml =
    #|<definitions><process id="unsupported"><startEvent id="start"/><userTask id="work"/><endEvent id="done"/></process></definitions>
  match @moonbpmn.import_bpmn_xml(xml) {
    ImportFailure(_) => fail("process container should still import")
    ImportSuccess(_, issues) => {
      assert_eq(issues.length(), 1)
      assert_eq(
        issues[0].code,
        @moonbpmn.BpmnImportIssueCode::UnsupportedElement,
      )
      assert_eq(issues[0].element, "userTask")
    }
  }
}

///|
test "BPMN XML importer rejects documents without a process" {
  match @moonbpmn.import_bpmn_xml("<definitions></definitions>") {
    ImportSuccess(_, _) => fail("expected missing process failure")
    ImportFailure(issues) =>
      assert_eq(issues[0].code, @moonbpmn.BpmnImportIssueCode::MissingProcess)
  }
}
