///|
fn push_error(
  diagnostics : Array[Diagnostic],
  code : DiagnosticCode,
  element_id : String,
  message : String,
) -> Unit {
  diagnostics.push(Diagnostic::error(code, element_id, message))
}

///|
fn push_warning(
  diagnostics : Array[Diagnostic],
  code : DiagnosticCode,
  element_id : String,
  message : String,
) -> Unit {
  diagnostics.push(Diagnostic::warning(code, element_id, message))
}

///|
fn validate_process_identity(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  if process.id == "" {
    push_error(diagnostics, EmptyProcessId, "", "process id must not be empty")
  }
}

///|
fn validate_node_identity(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  for index, node in process.nodes {
    if node.id == "" {
      push_error(diagnostics, EmptyNodeId, "", "node id must not be empty")
    }
    for previous_index = 0
        previous_index < index
        previous_index = previous_index + 1 {
      if process.nodes[previous_index].id == node.id {
        push_error(
          diagnostics,
          DuplicateNodeId,
          node.id,
          "node id appears more than once",
        )
        break
      }
    }
  }
}

///|
fn validate_flow_identity(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  for index, flow in process.flows {
    if flow.id == "" {
      push_error(
        diagnostics,
        EmptyFlowId,
        "",
        "sequence flow id must not be empty",
      )
    }
    for previous_index = 0
        previous_index < index
        previous_index = previous_index + 1 {
      if process.flows[previous_index].id == flow.id {
        push_error(
          diagnostics,
          DuplicateFlowId,
          flow.id,
          "sequence flow id appears more than once",
        )
        break
      }
    }
  }
}

///|
fn validate_flow_endpoints(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  for flow in process.flows {
    if process.find_node(flow.source) is None {
      push_error(
        diagnostics,
        MissingSource,
        flow.id,
        "sequence flow source does not exist: " + flow.source,
      )
    }
    if process.find_node(flow.target) is None {
      push_error(
        diagnostics,
        MissingTarget,
        flow.id,
        "sequence flow target does not exist: " + flow.target,
      )
    }
  }
}

///|
fn validate_event_counts(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  let mut starts = 0
  let mut ends = 0
  for node in process.nodes {
    match node.kind {
      StartEvent => starts = starts + 1
      EndEvent => ends = ends + 1
      _ => ()
    }
  }
  if starts == 0 {
    push_error(
      diagnostics,
      MissingStartEvent,
      process.id,
      "process has no start event",
    )
  } else if starts > 1 {
    push_error(
      diagnostics,
      MultipleStartEvents,
      process.id,
      "the initial executable subset requires exactly one start event",
    )
  }
  if ends == 0 {
    push_error(
      diagnostics,
      MissingEndEvent,
      process.id,
      "process has no end event",
    )
  }
}

///|
fn validate_node_degrees(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  for node in process.nodes {
    let incoming = process.incoming_count(node.id)
    let outgoing = process.outgoing_count(node.id)
    match node.kind {
      StartEvent => {
        if incoming > 0 {
          push_error(
            diagnostics,
            StartHasIncoming,
            node.id,
            "start event must not have incoming flows",
          )
        }
        if outgoing == 0 {
          push_error(
            diagnostics,
            StartHasNoOutgoing,
            node.id,
            "start event must have an outgoing flow",
          )
        }
      }
      EndEvent => {
        if outgoing > 0 {
          push_error(
            diagnostics,
            EndHasOutgoing,
            node.id,
            "end event must not have outgoing flows",
          )
        }
        if incoming == 0 {
          push_error(
            diagnostics,
            EndHasNoIncoming,
            node.id,
            "end event must have an incoming flow",
          )
        }
      }
      Task => {
        if incoming == 0 {
          push_error(
            diagnostics,
            TaskHasNoIncoming,
            node.id,
            "task must have an incoming flow",
          )
        }
        if outgoing == 0 {
          push_error(
            diagnostics,
            TaskHasNoOutgoing,
            node.id,
            "task must have an outgoing flow",
          )
        }
      }
      ExclusiveGateway | ParallelGateway => {
        if incoming == 0 {
          push_error(
            diagnostics,
            GatewayHasNoIncoming,
            node.id,
            "gateway must have an incoming flow",
          )
        }
        if outgoing == 0 {
          push_error(
            diagnostics,
            GatewayHasNoOutgoing,
            node.id,
            "gateway must have an outgoing flow",
          )
        }
      }
    }
  }
}

///|
fn validate_gateway_defaults(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  for node in process.nodes {
    if node.kind == ExclusiveGateway {
      let outgoing = process.outgoing_flows(node.id)
      if outgoing.length() > 1 {
        let mut defaults = 0
        for flow in outgoing {
          if flow.condition is None {
            defaults = defaults + 1
          }
        }
        if defaults > 1 {
          push_error(
            diagnostics,
            MultipleDefaultFlows,
            node.id,
            "exclusive split may have at most one unconditional default flow",
          )
        }
      }
    }
  }
}

///|
fn contains_id(ids : Array[String], id : String) -> Bool {
  for candidate in ids {
    if candidate == id {
      return true
    }
  }
  false
}

///|
fn validate_reachability(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  let queue : Array[String] = []
  let visited : Array[String] = []
  for node in process.nodes {
    if node.kind == StartEvent {
      queue.push(node.id)
    }
  }
  let mut cursor = 0
  while cursor < queue.length() {
    let current = queue[cursor]
    cursor = cursor + 1
    if !contains_id(visited, current) {
      visited.push(current)
      for flow in process.flows {
        if flow.source == current && !contains_id(visited, flow.target) {
          queue.push(flow.target)
        }
      }
    }
  }
  for node in process.nodes {
    if !contains_id(visited, node.id) {
      push_error(
        diagnostics,
        UnreachableNode,
        node.id,
        "node is not reachable from a start event",
      )
    }
  }
}

///|
fn validate_path_to_end(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  let queue : Array[String] = []
  let can_complete : Array[String] = []
  for node in process.nodes {
    if node.kind == EndEvent {
      queue.push(node.id)
    }
  }
  let mut cursor = 0
  while cursor < queue.length() {
    let current = queue[cursor]
    cursor = cursor + 1
    if !contains_id(can_complete, current) {
      can_complete.push(current)
      for flow in process.flows {
        if flow.target == current && !contains_id(can_complete, flow.source) {
          queue.push(flow.source)
        }
      }
    }
  }
  for node in process.nodes {
    if !contains_id(can_complete, node.id) {
      push_error(
        diagnostics,
        NoPathToEnd,
        node.id,
        "node has no directed path to an end event",
      )
    }
  }
}

///|
fn has_nonempty_path(
  process : ProcessModel,
  source_id : String,
  target_id : String,
) -> Bool {
  let queue : Array[String] = []
  let visited : Array[String] = []
  for successor in process.successor_ids(source_id) {
    queue.push(successor)
  }
  let mut cursor = 0
  while cursor < queue.length() {
    let current = queue[cursor]
    cursor = cursor + 1
    if current == target_id {
      return true
    }
    if !contains_id(visited, current) {
      visited.push(current)
      for successor in process.successor_ids(current) {
        if !contains_id(visited, successor) {
          queue.push(successor)
        }
      }
    }
  }
  false
}

///|
fn validate_cycles(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  for node in process.nodes {
    if has_nonempty_path(process, node.id, node.id) {
      push_warning(
        diagnostics,
        CycleDetected,
        node.id,
        "node participates in a directed cycle; use a runtime step limit",
      )
    }
  }
}

///|
fn validate_parallel_join_deadlocks(
  process : ProcessModel,
  diagnostics : Array[Diagnostic],
) -> Unit {
  for node in process.nodes {
    if node.kind != ParallelGateway {
      continue
    }
    let incoming = process.incoming_flows(node.id)
    if incoming.length() < 2 {
      continue
    }
    let common_source = incoming[0].source
    let mut same_source = true
    for flow in incoming {
      if flow.source != common_source {
        same_source = false
      }
    }
    if same_source {
      match process.find_node(common_source) {
        Some(source) =>
          if source.kind == ExclusiveGateway {
            push_error(
              diagnostics,
              ParallelJoinCannotSynchronize,
              node.id,
              "parallel join waits for mutually exclusive incoming flows",
            )
          }
        None => ()
      }
    }
  }
}
