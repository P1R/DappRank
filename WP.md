# DappRank DeFi Model Whitepaper

The DappRank DeFi model introduces a revolutionary decentralized ranking system
for dApps using a novel voting mechanism called Square Root Weighted Voting
(SRWV). This system addresses the critical issue of whale manipulation in
decentralized governance while establishing the foundation for an
"ultrasound money model" that aims to decrease token supply over time,
similar to how Ethereum's supply decreases through the "ultrasound money"
concept [8].

## Core Innovation: Square Root Weighted Voting (SRWV)

The SRWV system fundamentally changes how voting power is calculated in
decentralized systems. Unlike traditional linear voting systems where 100
tokens equal 100 votes, SRWV implements a mathematical transformation that
significantly reduces the influence of large token holdings.

### Mathematical Foundation

Let us define the key variables involved in the SRWV system:

- $T_i$: The number of tokens staked by voter $i$.
- $V_i$: The voting rate assigned by voter $i$, where $0 < V_i \leq 100$.
- $W_i$: The fan weight (voting power) of voter $i$, calculated as $W_i = \sqrt{T_i}$.
- $D$: The dApp being voted on.
- $D_r$: The final rating of dApp $D$.
- $S_{vw}$: The sum of weighted votes, defined as $S_{vw} = \sum_{i} (V_i \times W_i)$.
- $S_{wt}$: The sum of total weights, defined as $S_{wt} = \sum_{i} W_i$.

The final rating of the dApp, $D_r$, is computed as the ratio
of the sum of weighted votes to the sum of total weights:

$$
D_r = \frac{S_{vw}}{S_{wt}} = \frac{\sum_{i} (V_i \times \sqrt{T_i})}{\sum_{i} \sqrt{T_i}}
$$

### Process Description

1. **Token Staking**: Each voter $i$ stakes $T_i$ tokens to vote on a dApp. The
   system verifies that the voter has sufficient balance and has approved the
   transfer of tokens to the `DappsManager` contract [3].

2. **Fan Weight Calculation**: The fan weight $W_i$ is calculated using the
   square root of the staked tokens:

$$
W_i = \sqrt{T_i}
$$

   This ensures that the voting power grows sublinearly with the number of
   tokens, reducing the influence of large stakeholders [2].

3. **Weighted Vote Summation**: For each vote, the system computes the product
   of the voting rate $V_i$ and the fan weight $W_i$, and accumulates this
   value into $S_{vw}$. Simultaneously, the fan weight $W_i$ is added to $S_{wt}$ [2].

4. **Final Rating Calculation**: The dApp's final rating $D_r$ is determined
   by dividing the sum of weighted votes $S_{vw}$ by the sum of total weights
   $S_{wt}$. This results in a weighted average that reflects the collective
   sentiment of the community while minimizing the impact of large token
   holders [2].

### Example Calculation

Consider a scenario where three voters participate in voting for a dApp:

- Voter 1 stakes $T_1 = 100$ tokens and assigns $V_1 = 50$.
- Voter 2 stakes $T_2 = 10,000$ tokens and assigns $V_1 = 80$.
- Voter 3 stakes $T_3 = 1,000,000$ tokens and assigns $V_2 = 90$.

The fan weights are calculated as follows:
- $W_1 = \sqrt{100} = 10$
- $W_2 = \sqrt{10,000} = 100$
- $W_3 = \sqrt{1,000,000} = 1,000$

The sum of weighted votes is:

$$
S_{vw} = (50 \times 10) + (80 \times 100) + (90 \times 1,000) = 500 + 8,000 + 90,000 = 98,500
$$

The sum of total weights is:

$$
S_{wt} = 10 + 100 + 1,000 = 1,110
$$

The final rating of the dApp is:

$$
D_r = \frac{98,500}{1,110} \approx 88.74
$$

This example demonstrates how the SRWV system effectively balances the
influence of different stakeholders, ensuring that no single voter can dominate
the outcome [2].

### Game Theory Protection Against Whale Manipulation

The SRWV system creates a natural disincentive for whale manipulation through
mathematical properties:

1. **Diminishing Returns**: As token holdings increase, the marginal voting
power gained decreases exponentially [7]
2. **Equity Distribution**: Small token holders maintain significant influence
relative to large holders
3. **Cost-Benefit Analysis**: Whales face higher costs to gain disproportionate
influence

The mathematical relationship ensures that a whale with 10,000 tokens only
gains 100 votes, while a user with 100 tokens gains 10 votes. This prevents
whales from having overwhelming control over governance decisions.

## System Architecture

### Tokenomics

The DRNK token incorporates both a minting mechanism for distribution and a
burning mechanism for supply reduction [1]. This dual approach creates a
deflationary pressure that supports long-term token value retention.

### Voting Process

When users vote on dApps, the system applies the SRWV algorithm:

1. User deposits tokens for voting
2. The system calculates voting power using √token_amount
3. Votes are weighted based on this square root calculation
4. Final dApp ranking is calculated using the weighted sum of all votes

### Revenue Distribution and Burning

Dapp owners can cash out rewards, but a portion is automatically burned to
reduce total supply [3]. This mechanism directly supports the ultrasound money
model concept, where token scarcity increases over time.

## Ultrasound Money Model Integration

The DappRank system is designed as a foundational layer for implementing an
ultrasound money model [8]. By incorporating automatic burning mechanisms and
strategic fee structures, the system creates deflationary pressure that reduces
token supply over time. This approach mirrors Ethereum's "ultrasound money"
concept where decreasing supply increases value retention [9].

## Technical Implementation

The system uses a combination of:
- ERC20 token standard with burn capabilities [1]
- Access control for role management
- Voting mechanisms with weighted calculations
- Game theory-based incentive structures

## Conclusion

The DappRank DeFi model represents a significant advancement in decentralized
governance by solving the whale manipulation problem through mathematical
innovation. The SRWV system creates a fairer, more democratic voting process
while establishing the technical foundation for a sustainable ultrasound money
model that can drive long-term value creation in the decentralized
ecosystem.

This model demonstrates how blockchain technology can be leveraged to create
more equitable and sustainable decentralized systems through thoughtful
mathematical design and game theory principles.

## References

1. [DRNK](./src-sc/DRNK.sol)

2. [DappsManager](./src-sc/DappsManager.sol)

3. [Demo test](./test/DappsManager.t.sol)

4. https://github.com/Krish-Depani/Decentralized-Voting-System

5. https://arxiv.org/abs/2503.11940

6. http://dimacs.rutgers.edu/Workshops/DecisionTheory3/Aziz.pdf

7. https://arxiv.org/pdf/2504.12859

8. https://ultrasound.money/

9. https://thenewautonomy.medium.com/is-ethereum-ultrasound-money-a-deep-dive-into-crypto-as-currency-9d180991f4ee
