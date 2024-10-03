rule getExecutionStateCorrectness {
  env e;
  uint64 sequenceNumber = e.input.uint64("sequenceNumber");
  
  // Correctly reference the contract method
  Internal.MessageExecutionState actualState = OffRamp.getExecutionState(sequenceNumber);
  
  // Placeholder for expected state logic
  assert(actualState == /* logic to determine expectedState */, "Execution state is not correct");
}

rule getExecutionStateBoundaryCondition {
  env e;
  uint64 sequenceNumber = e.input.uint64("sequenceNumber");

  bool isBoundary = sequenceNumber % 128 == 0;

  // Correctly reference the contract method
  Internal.MessageExecutionState actualState = OffRamp.getExecutionState(sequenceNumber);

  if (isBoundary) {
    // Placeholder for boundary condition logic
    assert(actualState == /* logic to determine boundaryExpectedState */, "Incorrect execution state at boundary condition");
  }
}
