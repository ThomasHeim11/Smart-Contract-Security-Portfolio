/*
*  Verification of off-ramp contract
*/
rule getExecutionStateCorrectness {
  env env;
  uint64 sequenceNumber = e.input.uint64("sequenceNumber");
  Interanl.MessageExecutionState actualState = getExecutionState(sequenceNumber);
  assert(actualState == expectedState, "Execution state is not correct");
}

rule getExecutionStateBoundaryCondition{
  env e;
  uint64 sequenceNumber = e.input.uint64("sequenceNumber");

  bool isBoundary = sequenseNumber % 128 == 0;

  Interanl.MessageExecutionState actualState = getExecutionState(sequenceNumber);

  if (isBoundary){
    assert(actualState == boundaryExpectedState,"Incorrect execution state at boundary condition")
  }
}



