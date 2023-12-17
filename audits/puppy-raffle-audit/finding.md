### [M-#] Looping through players array to check to duplicates in `PuppyRaffel::enterRaffel` is a potential denial of service (DoS) attack, incrementing gas costs for future etrants.

**Description:** The `PuppyRaffle::enterRaffle` function loops thrugh the `players` array to check for duplicates. However, the longer the `PuppyRaffle::players` array is, the more checks a new player will have to make. This means the gas costs for players who enter right when the raffle stats will be drmatically lower than those who entr later. Every additional address in the `players` array, is an additional check the loop will have to make.

**Impact:** The gas cost for raffle entrants will greatly increase as more players enter the raffle. Discouraging later user from entering, and causing a rush at the start of a raffle to be one of the first entrants in the queue.

An attacker might make the `PuppyRaffle::entrants` array so big, that no one else enters, quarenteeing themselves the win.

**Proof of Concep:**

If we have 2 sets of 100 players enter, the gas cost will be as such:

- 1st 100 players: -6252048 gas
- 2nd 100 players: -18068138 gas
  **Recomnended Mitigation:**
