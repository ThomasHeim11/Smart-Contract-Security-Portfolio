/*
* Verification of off-ramp contract
*/

rule getExecutionStateCorrectness {
  env e;
  uint64 sequenceNumber = e.input.uint64("sequenceNumber");
  
  // Assuming 'OffRamp' is the name of your contract
  Internal.MessageExecutionState actualState = OffRamp.getExecutionState(sequenceNumber);
  
  // Simplified logic for demonstration: Even sequence numbers are expected to be in one state, odd in another
  Internal.MessageExecutionState expectedState = sequenceNumber % 2 == 0 ? Internal.MessageExecutionState.StateA : Internal.MessageExecutionState.StateB;

  assert(actualState == expectedState, "Execution state is not correct");
}

rule getExecutionStateBoundaryCondition {
  env e;
  uint64 sequenceNumber = e.input.uint64("sequenceNumber");

  bool isBoundary = sequenceNumber % 128 == 0;

  // Assuming 'OffRamp' is the name of your contract
  Internal.MessageExecutionState actualState = OffRamp.getExecutionState(sequenceNumber);

  // Simplified logic for demonstration: At boundary conditions, expect a specific state
  Internal.MessageExecutionState boundaryExpectedState = Internal.MessageExecutionState.SpecialState;

  if (isBoundary) {
    assert(actualState == boundaryExpectedState, "Incorrect execution state at boundary condition");
  }
}
