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

///|
test "condition evaluator compares integer variables" {
  let variables = @moonbpmn.VariableSet::new()
  variables.set(@moonbpmn.ProcessVariable::int("amount", 125))
  assert_eq(
    @moonbpmn.evaluate_condition("amount >= 100", variables),
    @moonbpmn.ConditionResult::ConditionMatched(true),
  )
  assert_eq(
    @moonbpmn.evaluate_condition("amount < 100", variables),
    @moonbpmn.ConditionResult::ConditionMatched(false),
  )
}

///|
test "condition evaluator compares quoted strings and negates booleans" {
  let variables = @moonbpmn.VariableSet::new()
  variables.set(@moonbpmn.ProcessVariable::string("region", "EU"))
  variables.set(@moonbpmn.ProcessVariable::bool("blocked", false))
  assert_eq(
    @moonbpmn.evaluate_condition("region == \"EU\"", variables),
    @moonbpmn.ConditionResult::ConditionMatched(true),
  )
  assert_eq(
    @moonbpmn.evaluate_condition("!blocked", variables),
    @moonbpmn.ConditionResult::ConditionMatched(true),
  )
}

///|
test "condition evaluator rejects literals with the wrong type" {
  let variables = @moonbpmn.VariableSet::new()
  variables.set(@moonbpmn.ProcessVariable::int("amount", 10))
  assert_eq(
    @moonbpmn.evaluate_condition("amount == \"ten\"", variables),
    @moonbpmn.ConditionResult::InvalidCondition(
      "integer comparison requires an integer literal",
    ),
  )
}
