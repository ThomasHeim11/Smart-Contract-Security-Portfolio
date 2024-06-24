# Medium

### [M-1] Unused Return Values in External Contract Calls in LibWell.sol

## Summary

The code analysis identified a medium severity issue related to unused return values in two functions: getTwaReservesFromBeanstalkPump and getTwaLiquidityFromBeanstalkPump. Within these functions, an external contract call is made to ICumulativePump(pumps[0].target).readTwaReserves, but the return values are not stored or utilized further in the function logic. This can lead to inefficiencies and potential logic errors.

## Vulnerability Details

The vulnerable functions make external calls to retrieve TWAP (Time-Weighted Average Price) reserves from a contract. However, the return values from these calls are not assigned to any variable, resulting in unused computations. While the code handles potential exceptions with a try-catch block, it fails to utilize the retrieved data, indicating a disconnect between the intended logic and the actual implementation.

## Impact

The impact of this issue is considered medium severity. While it may not directly compromise the security of the system, it introduces inefficiencies and potential inaccuracies in the application. Failure to capture and utilize return values from external calls can lead to wasted gas costs and incorrect behavior if the returned data is expected to influence subsequent operations.

## Tools Used

Static code analysis tools were employed to detect this medium severity issue. By examining the code structure and identifying unused return values, these tools highlight potential areas for improvement in terms of code efficiency and reliability.

## Recommendations

It is recommended to refactor the affected functions to appropriately handle the return values from external calls. This involves storing the retrieved data in local or state variables and incorporating it into the function logic as intended. By ensuring that all relevant return values are utilized effectively, the codebase can be optimized for efficiency and correctness, mitigating the risks associated with unused computations.
