///|
test "variable set replaces values by stable name" {
  let variables = @moonbpmn.VariableSet::new()
  variables.set(@moonbpmn.ProcessVariable::bool("approved", false))
  variables.set(@moonbpmn.ProcessVariable::bool("approved", true))
  assert_eq(variables.length(), 1)
  assert_eq(
    @moonbpmn.evaluate_condition("approved", variables),
    @moonbpmn.ConditionResult::ConditionMatched(true),
  )
}

///|
test "condition evaluator reports missing and non-boolean variables" {
  let variables = @moonbpmn.VariableSet::new()
  variables.set(@moonbpmn.ProcessVariable::int("amount", 42))
  assert_eq(
    @moonbpmn.evaluate_condition("missing", variables),
    @moonbpmn.ConditionResult::UnknownVariable("missing"),
  )
  assert_eq(
    @moonbpmn.evaluate_condition("amount", variables),
    @moonbpmn.ConditionResult::NonBooleanVariable("amount"),
  )
}

///|
test "condition literals are deterministic" {
  let variables = @moonbpmn.VariableSet::new()
  assert_eq(
    @moonbpmn.evaluate_condition("true", variables),
    @moonbpmn.ConditionResult::ConditionMatched(true),
  )
  assert_eq(
    @moonbpmn.evaluate_condition("false", variables),
    @moonbpmn.ConditionResult::ConditionMatched(false),
  )
}
