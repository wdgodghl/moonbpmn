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
} derive(Eq, Debug)

///|
pub extend ConditionResult with Eq::{equal, not_equal}

///|
pub extend ConditionResult with Debug::{to_repr}

///|
/// Evaluate `true`, `false`, or the name of a boolean process variable.
///
/// Keeping this language deliberately small makes execution portable and
/// deterministic on every MoonBit backend. Richer expressions can be added
/// without making sequence-flow selection depend on a host language.
pub fn evaluate_condition(
  expression : String,
  variables : VariableSet,
) -> ConditionResult {
  if expression == "true" {
    return ConditionMatched(true)
  }
  if expression == "false" {
    return ConditionMatched(false)
  }
  match variables.get(expression) {
    Some(BoolValue(value)) => ConditionMatched(value)
    Some(_) => NonBooleanVariable(expression)
    None => UnknownVariable(expression)
  }
}
