### [M-#] Looping through players array to check to duplicates in `PuppyRaffel::enterRaffel` is a potential denial of service (DoS) attack, incrementing gas costs for future etrants.

**Description:** The `PuppyRaffle::enterRaffle` function loops thrugh the `players` array to check for duplicates. However, the longer the `PuppyRaffle::players` array is, the more checks a new player will have to make. This means the gas costs for players who enter right when the raffle stats will be drmatically lower than those who entr later. Every additional address in the `players` array, is an additional check the loop will have to make.

**Impact:**

**Proof of Concep:**

**Recomnended Mitigation:**
