///|
/// Stable issue codes produced while importing the supported BPMN XML subset.
pub(all) enum BpmnImportIssueCode {
  MissingProcess
  MissingAttribute
  UnsupportedElement
  MalformedXml
} derive(Eq, Debug)

///|
pub extend BpmnImportIssueCode with Eq::{equal, not_equal}

///|
pub extend BpmnImportIssueCode with Debug::{to_repr}

///|
pub(all) struct BpmnImportIssue {
  code : BpmnImportIssueCode
  element : String
  message : String
}

///|
pub(all) enum BpmnImportResult {
  ImportSuccess(ProcessModel, Array[BpmnImportIssue])
  ImportFailure(Array[BpmnImportIssue])
}

///|
fn import_issue(
  issues : Array[BpmnImportIssue],
  code : BpmnImportIssueCode,
  element : String,
  message : String,
) -> Unit {
  issues.push({ code, element, message, })
}

///|
fn decode_xml_text(value : String) -> String {
  value
  .replace_all(old="&quot;", new="\"")
  .replace_all(old="&apos;", new="'")
  .replace_all(old="&lt;", new="<")
  .replace_all(old="&gt;", new=">")
  .replace_all(old="&amp;", new="&")
}

///|
fn xml_attribute(tag : String, name : String) -> String? {
  let needle = name + "=\""
  match tag.find(needle) {
    None => None
    Some(offset) => {
      let start = offset + needle.length()
      let tail = tag[start:]
      match tail.find("\"") {
        None => None
        Some(length) => Some(decode_xml_text(tail[:length].to_owned()))
      }
    }
  }
}

///|
fn xml_local_name(tag : String) -> String {
  let raw_name = match tag.split_once(" ") {
    Some((name, _)) => name.to_owned()
    None => tag
  }
  let without_prefix = match raw_name.split_once(":") {
    Some((_, name)) => name.to_owned()
    None => raw_name
  }
  without_prefix.replace_all(old="/", new="")
}

///|
fn required_attribute(
  tag : String,
  element : String,
  name : String,
  issues : Array[BpmnImportIssue],
) -> String? {
  match xml_attribute(tag, name) {
    Some(value) => Some(value)
    None => {
      import_issue(
        issues,
        MissingAttribute,
        element,
        element + " requires attribute " + name,
      )
      None
    }
  }
}

///|
fn add_imported_node(
  process : ProcessModel,
  tag : String,
  kind : NodeKind,
  element : String,
  issues : Array[BpmnImportIssue],
) -> Unit {
  match required_attribute(tag, element, "id", issues) {
    None => ()
    Some(id) => {
      let name = match xml_attribute(tag, "name") {
        Some(name) => name
        None => ""
      }
      process.add_node(ProcessNode::new(id, name, kind))
    }
  }
}

///|
fn unsupported_bpmn_element(name : String) -> Bool {
  name == "serviceTask" ||
  name == "userTask" ||
  name == "scriptTask" ||
  name == "subProcess" ||
  name == "inclusiveGateway" ||
  name == "eventBasedGateway" ||
  name == "intermediateCatchEvent" ||
  name == "intermediateThrowEvent"
}

///|
fn set_last_flow_condition(
  process : ProcessModel,
  last_flow_index : Int?,
  expression : String,
) -> Unit {
  match last_flow_index {
    None => ()
    Some(index) => {
      let previous = process.flows[index]
      process.flows[index] = SequenceFlow::conditional(
        previous.id,
        previous.source,
        previous.target,
        previous.name,
        decode_xml_text(expression.trim().to_owned()),
      )
    }
  }
}

///|
/// Import the executable MoonBPMN subset from namespace-prefixed BPMN XML.
///
/// The importer accepts `process`, start/end events, tasks, exclusive/parallel
/// gateways, sequence flows, and plain-text or CDATA condition expressions.
/// Unsupported executable elements are reported instead of silently ignored.
pub fn import_bpmn_xml(xml : String) -> BpmnImportResult {
  let issues : Array[BpmnImportIssue] = []
  if xml.find("<") is None || xml.find(">") is None {
    import_issue(
      issues,
      MalformedXml,
      "",
      "document does not contain XML elements",
    )
    return ImportFailure(issues)
  }
  let mut process : ProcessModel? = None
  let mut last_flow_index : Int? = None
  for piece in xml.split("<") {
    match piece.split_once(">") {
      None => ()
      Some((header_view, body_view)) => {
        let header = header_view.trim().to_owned()
        if header == "" ||
          header.find("?") == Some(0) ||
          header.find("/") == Some(0) ||
          header.find("!--") == Some(0) {
          continue
        }
        if header.find("![CDATA[") == Some(0) {
          match header.find("]]") {
            Some(end) =>
              set_last_flow_condition(
                process.unwrap_or(ProcessModel::new("", "")),
                last_flow_index,
                header[8:end].to_owned(),
              )
            None =>
              import_issue(
                issues,
                MalformedXml,
                "conditionExpression",
                "unterminated CDATA condition",
              )
          }
          continue
        }
        let element_name = xml_local_name(header)
        if element_name == "process" {
          match required_attribute(header, "process", "id", issues) {
            None => ()
            Some(id) => {
              let name = match xml_attribute(header, "name") {
                Some(name) => name
                None => ""
              }
              process = Some(ProcessModel::new(id, name))
            }
          }
          continue
        }
        match process {
          None => ()
          Some(model) =>
            match element_name {
              "startEvent" =>
                add_imported_node(
                  model,
                  header,
                  StartEvent,
                  element_name,
                  issues,
                )
              "endEvent" =>
                add_imported_node(model, header, EndEvent, element_name, issues)
              "task" =>
                add_imported_node(model, header, Task, element_name, issues)
              "exclusiveGateway" =>
                add_imported_node(
                  model,
                  header,
                  ExclusiveGateway,
                  element_name,
                  issues,
                )
              "parallelGateway" =>
                add_imported_node(
                  model,
                  header,
                  ParallelGateway,
                  element_name,
                  issues,
                )
              "sequenceFlow" => {
                let id = required_attribute(header, element_name, "id", issues)
                let source = required_attribute(
                  header, element_name, "sourceRef", issues,
                )
                let target = required_attribute(
                  header, element_name, "targetRef", issues,
                )
                match (id, source, target) {
                  (Some(id), Some(source), Some(target)) => {
                    let name = match xml_attribute(header, "name") {
                      Some(name) => name
                      None => ""
                    }
                    model.add_flow(
                      SequenceFlow::named(id, source, target, name),
                    )
                    last_flow_index = Some(model.flows.length() - 1)
                  }
                  _ => ()
                }
              }
              "conditionExpression" => {
                let expression = body_view.trim().to_owned()
                if expression != "" {
                  set_last_flow_condition(model, last_flow_index, expression)
                }
              }
              _ =>
                if unsupported_bpmn_element(element_name) {
                  import_issue(
                    issues,
                    UnsupportedElement,
                    element_name,
                    "unsupported BPMN element: " + element_name,
                  )
                }
            }
        }
      }
    }
  }
  match process {
    None => {
      import_issue(issues, MissingProcess, "", "document has no BPMN process")
      ImportFailure(issues)
    }
    Some(model) => ImportSuccess(model, issues)
  }
}
