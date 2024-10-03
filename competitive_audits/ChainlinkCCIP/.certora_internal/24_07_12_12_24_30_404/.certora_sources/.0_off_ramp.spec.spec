/*
* Verification of off-ramp contract
*/

rule getExecutionStateCorrectness {
  env e;
  uint64 sequenceNumber = e.input.uint64("sequenceNumber");
  
  // Assuming 'OffRamp' is the name of your contract
  // Replace 'OffRamp' with the actual contract name
  Internal.MessageExecutionState actualState = OffRamp.getExecutionState(sequenceNumber);
  
  // You need to define or obtain 'expectedState' based on your contract's logic
  assert(actualState == expectedState, "Execution state is not correct");
}

rule getExecutionStateBoundaryCondition {
  env e;
  uint64 sequenceNumber = e.input.uint64("sequenceNumber");

  bool isBoundary = sequenceNumber % 128 == 0;

  // Assuming 'OffRamp' is the name of your contract
  // Replace 'OffRamp' with the actual contract name
  Internal.MessageExecutionState actualState = OffRamp.getExecutionState(sequenceNumber);

  if (isBoundary) {
    // You need to define or obtain 'boundaryExpectedState' based on your contract's logic
    assert(actualState == boundaryExpectedState, "Incorrect execution state at boundary condition");
  }
}


