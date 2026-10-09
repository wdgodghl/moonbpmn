///|
/// Values that can be supplied to workflow execution.
pub(all) enum VariableValue {
  BoolValue(Bool)
  IntValue(Int)
  StringValue(String)
} derive(Eq, Debug)

///|
pub extend VariableValue with Eq::{equal, not_equal}

///|
pub extend VariableValue with Debug::{to_repr}

///|
pub(all) struct ProcessVariable {
  name : String
  value : VariableValue
}

///|
pub fn ProcessVariable::bool(name : String, value : Bool) -> ProcessVariable {
  { name, value: BoolValue(value), }
}

///|
pub fn ProcessVariable::int(name : String, value : Int) -> ProcessVariable {
  { name, value: IntValue(value), }
}

///|
pub fn ProcessVariable::string(
  name : String,
  value : String,
) -> ProcessVariable {
  { name, value: StringValue(value), }
}

///|
/// An ordered variable collection with deterministic replacement semantics.
pub(all) struct VariableSet {
  values : Array[ProcessVariable]
}

///|
pub fn VariableSet::new() -> VariableSet {
  { values: [], }
}

///|
pub fn VariableSet::set(self : VariableSet, variable : ProcessVariable) -> Unit {
  for index, existing in self.values {
    if existing.name == variable.name {
      self.values[index] = variable
      return
    }
  }
  self.values.push(variable)
}

///|
pub fn VariableSet::get(self : VariableSet, name : String) -> VariableValue? {
  for variable in self.values {
    if variable.name == name {
      return Some(variable.value)
    }
  }
  None
}

///|
pub fn VariableSet::length(self : VariableSet) -> Int {
  self.values.length()
}

///|
/// Create an independent copy suitable for runtime snapshots.
pub fn VariableSet::copy(self : VariableSet) -> VariableSet {
  { values: self.values.copy(), }
}

///|
/// Result of evaluating the intentionally small first-release condition language.
pub(all) enum ConditionResult {
  ConditionMatched(Bool)
  UnknownVariable(String)
  NonBooleanVariable(String)
  InvalidCondition(String)
} derive(Eq, Debug)

///|
pub extend ConditionResult with Eq::{equal, not_equal}

///|
pub extend ConditionResult with Debug::{to_repr}

///|
fn parse_decimal(value : String) -> Int? {
  let text = value.trim().to_owned()
  if text == "" {
    return None
  }
  let mut sign = 1
  let mut index = 0
  if text.unsafe_get(0).to_int() == 45 {
    sign = -1
    index = 1
  }
  if index == text.length() {
    return None
  }
  let mut result = 0
  while index < text.length() {
    let code = text.unsafe_get(index).to_int()
    if code < 48 || code > 57 {
      return None
    }
    result = result * 10 + code - 48
    index = index + 1
  }
  Some(result * sign)
}

///|
fn quoted_string(value : String) -> String? {
  let text = value.trim().to_owned()
  if text.length() < 2 ||
    text.unsafe_get(0).to_int() != 34 ||
    text.unsafe_get(text.length() - 1).to_int() != 34 {
    return None
  }
  Some(
    text[1:text.length() - 1]
    .to_owned()
    .replace_all(old="\\\"", new="\"")
    .replace_all(old="\\\\", new="\\"),
  )
}

///|
fn compare_int(left : Int, operator : String, right : Int) -> Bool? {
  match operator {
    "==" => Some(left == right)
    "!=" => Some(left != right)
    ">" => Some(left > right)
    ">=" => Some(left >= right)
    "<" => Some(left < right)
    "<=" => Some(left <= right)
    _ => None
  }
}

///|
fn compare_bool(left : Bool, operator : String, right : Bool) -> Bool? {
  match operator {
    "==" => Some(left == right)
    "!=" => Some(left != right)
    _ => None
  }
}

///|
fn compare_string(left : String, operator : String, right : String) -> Bool? {
  match operator {
    "==" => Some(left == right)
    "!=" => Some(left != right)
    _ => None
  }
}

///|
fn evaluate_comparison(
  name : String,
  operator : String,
  literal : String,
  variables : VariableSet,
) -> ConditionResult {
  let variable_name = name.trim().to_owned()
  if variable_name == "" {
    return InvalidCondition("comparison has no variable name")
  }
  match variables.get(variable_name) {
    None => UnknownVariable(variable_name)
    Some(IntValue(left)) =>
      match parse_decimal(literal) {
        None =>
          InvalidCondition("integer comparison requires an integer literal")
        Some(right) =>
          match compare_int(left, operator, right) {
            Some(result) => ConditionMatched(result)
            None =>
              InvalidCondition("unsupported integer comparison: " + operator)
          }
      }
    Some(BoolValue(left)) => {
      let right = match literal.trim().to_owned() {
        "true" => Some(true)
        "false" => Some(false)
        _ => None
      }
      match right {
        None => InvalidCondition("boolean comparison requires true or false")
        Some(right) =>
          match compare_bool(left, operator, right) {
            Some(result) => ConditionMatched(result)
            None =>
              InvalidCondition("unsupported boolean comparison: " + operator)
          }
      }
    }
    Some(StringValue(left)) =>
      match quoted_string(literal) {
        None => InvalidCondition("string comparison requires a quoted literal")
        Some(right) =>
          match compare_string(left, operator, right) {
            Some(result) => ConditionMatched(result)
            None =>
              InvalidCondition("unsupported string comparison: " + operator)
          }
      }
  }
}

///|
fn split_comparison(expression : String) -> (String, String, String)? {
  for operator in [">=", "<=", "==", "!=", ">", "<"] {
    match expression.split_once(operator) {
      Some((left, right)) =>
        return Some((left.to_owned(), operator, right.to_owned()))
      None => ()
    }
  }
  None
}

///|
/// Evaluate a portable condition expression.
///
/// Supported forms are boolean literals, a boolean variable, `!variable`, and
/// typed comparisons such as `amount >= 100` or `region == "EU"`.
pub fn evaluate_condition(
  expression : String,
  variables : VariableSet,
) -> ConditionResult {
  let normalized = expression.trim().to_owned()
  if normalized == "true" {
    return ConditionMatched(true)
  }
  if normalized == "false" {
    return ConditionMatched(false)
  }
  match split_comparison(normalized) {
    Some((name, operator, literal)) =>
      return evaluate_comparison(name, operator, literal, variables)
    None => ()
  }
  if normalized.length() > 1 && normalized.unsafe_get(0).to_int() == 33 {
    let name = normalized[1:].trim().to_owned()
    return match variables.get(name) {
      Some(BoolValue(value)) => ConditionMatched(!value)
      Some(_) => NonBooleanVariable(name)
      None => UnknownVariable(name)
    }
  }
  match variables.get(normalized) {
    Some(BoolValue(value)) => ConditionMatched(value)
    Some(_) => NonBooleanVariable(normalized)
    None => UnknownVariable(normalized)
  }
}
