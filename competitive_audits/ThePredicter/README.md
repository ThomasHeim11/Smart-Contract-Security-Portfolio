# The Predicter

### Prize Pool

- High - 100xp
- Medium - 20xp
- Low - 2xp

- Starts: July 18, 2024 Noon UTC
- Ends: July 25, 2024 Noon UTC

### Stats

- nSLOC: 191
- Complexity Score: 119

## Disclaimer

_This code was created for CodeHawks as a Community First Flight. It is made with bugs and flaws on purpose._

_Do NOT use any part of this code without reviewing it and auditing it._

[//]: # (contest-details-open)

# Contest Details

_Created by [NightHawK](https://www.codehawks.com/profile/clvmfeh090004jbg1f2oa6srl)_

[Twitter](https://twitter.com/HawkApprovedDA)

## About

Ivan and his 15 friends are big football fans and they decided to watch the matches of a football tournament together. Ivan has found a suitable hall with a capacity of 30 people in which they can watch the matches. To make it more interesting, and to pay the hall rent, Ivan decides to organize betting on the matches, as well as to invite up to 14 other completely random people to join in watching and betting.

Ivan and his 15 friends are always honest and well-intentioned, but nothing is known about the other people and their intentions, so, Ivan decided to use the modern Web 3 technologies to develop the betting system. He is a novice Web 3 developer and therefore Ivan needs your help to audit the protocol he has developed.

The protocol have the following roles: Organizer, User and Player. Everyone can be a User and after approval of the Organizer can become a Player. Ivan has the roles of both Organizer and Player. Ivan's 15 friends are Players. These 16 people are considered honest and trusted. They will not intentionally take advantage of vulnerabilities in the protocol. The Users and the other 14 people with the role of Players are unknown and the protocol must be protected from any malicious actions by them.

The entrance fees paid at the beginning form the prize fund, which after the end of the tournament is distributed among all Players who paid at least one prediction fee and depending on theirs collected number of points.

When Player is making prediction, a prediction fee is required to be paid. Ivan also has to pay this fee. No second prediction fee is due if any Player desires to change an already paid prediction. The funds collected from this prediction fees are used to cover the costs of the hall and the Organizer must be able to withdraw those funds at any time.

The entrance fee and prediction fee are parameters of the protocol that are set when it is deployed on the Arbitrum blockchain.

The start of the tournament is set to Thu Aug 15 2024 20:00:00 UTC. A total of 9 matches will be played.

Until 16:00:00 UTC on the day of the start of the tournament, Users can register by paying the entry fee. Anyone registered must be approved by the Organizer to become a Player. As the Organizer, Ivan will give priority approval to him and his other 15 friends. He will then approve some of the remaining registered Users until the maximum number is filled. Ivan and all 15 of his friends will register.

User who is not approved can withdraw the deposited entry fee at any time.

Two teams take part in the matches. Each match can end with:

- first team win (prediction First);
- second team win (prediction Second);
- or with a tie (prediction Draw).

Every day from 20:00:00 UTC one match is played. Until 19:00:00 UTC on the day of the match, predictions can be made by any approved Player. Players pay prediction fee when making their first prediction for each match.

After the end of each match the Organizer will enter the match result.

The prediction of the Player is correct if it is equal to the entered final result from the Organizer. The Player will:

- receive 2 points for a correct prediction for which a prediction fee has been paid;
- lose 1 point for a wrong prediction for which a prediction fee has been paid;
- neighter receive nor lose any points if he has not given a prediction or the corresponding prediction fee has not been paid.

After the Organizer has entered the result from the last match (the 9th match), Players can take their rewards from the prize pool. Players can receive an amount from the prize fund only if their total number of points is a positive number and if they had paid at least one prediction fee. The prize fund is distributed in proportion to the points collected by all Players with a positive number of points. If all Players have a negative number of points, they will receive back the value of the entry fee.

The protocol consists the following contracts.

## ScoreBoard.sol

The `ScoreBoard` contract is responsible for keeping the predictions of the Players and the final results of all the matches. This contract provides the calculation of the final score (number of points) of all the Players.

- `setResult` allows the Organizer to set the final result of any match.
- `confirmPredictionPayment` is executed by `ThePredicter` contract in order to mark the corresponding prediction of the Player as paid.
- `setPrediction` sets the prediction of the Player for the given match. This function is called when the Player pays the prediction fee. It can be called again by the Players to alter their predictions without a second payment of the prediction fee which is according to the rules.
- `clearPredictionsCount` is used to make the Player ineligible for a second reward after reward collection.
- `getPlayerScore` is used to calculate the score of any Player.
- `isEligibleForReward` returns whether the Player is compliant with the rules for getting a reward.

## ThePredicter.sol

The `ThePredicter` contract is supposed to manage the registration of the players, to collect the entrance and prediction fees and to distribute the rewards.

- `register` allows Users to pay the entrance fee and become cadidates for Players.
- `cancelRegistration` allows the Users which are still not approved for Players to cancel their registration and to withdraw the paid entrance fee.
- `approvePlayer` allows the Organizer to approve any user to be a Player.
- `makePrediction` allows the Players to pay the prediction fee and in the same time to set their prediction for the corresponding match.
- `withdrawPredictionFees` allows the Organizer to withdraw the current amount of the prediction fees.
- `withdraw` allows the Players to withdraw their rewards after the end of the tournament.

[//]: # (contest-details-close)

[//]: # (getting-started-open)

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (4aa17bc 2024-05-14T00:16:59.874867353Z)`

## Usage

## Setup

```
git clone https://github.com/Cyfrin/2024-07-the-predicter
code 2024-07-the-predicter
make install
make test
```

## Testing

```
forge test
```

### Test Coverage

```
forge coverage
```

and for coverage based testing:

```
forge coverage --report debug
```

[//]: # (getting-started-close)

[//]: # (scope-open)

# Audit Scope Details

- In Scope:

```
├── src
│   ├── Scoreboard.sol
│   ├── ThePredicter.sol
```

## Compatibilities

- Solc Version: `0.8.20`
- Chain(s) to deploy contract to:
  - Arbitrum

[//]: # (scope-close)

[//]: # (known-issues-open)

# Known Issues

None

[//]: # (known-issues-close)
