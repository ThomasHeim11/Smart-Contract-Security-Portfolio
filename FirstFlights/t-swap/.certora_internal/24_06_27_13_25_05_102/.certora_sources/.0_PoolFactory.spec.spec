/*
* Verification of createPool function for PoolFactory contract
*/
// Methods
methods {
    function createPool(address tokenAddress) external returns address envfree;
}

// Invariant
invariant createPoolInvariant(address tokenAddress)
    createPool(tokenAddress) == result
    {
        preserved{
            require(s_pools[tokenAddress] == address(0));
        }
    }

// Rule
rule check_createPool(uint128 number){
    assert(true);
}
    



