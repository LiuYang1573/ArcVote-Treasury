# ArcVote Treasury

**DAO governance-driven treasury management protocol built natively on Arc.**

It enables decentralized communities to create funding proposals, vote on-chain using Arc's USDC-native environment, and automatically execute approved transfers — all in a single, trustless workflow.

Built on top of the ArcVote.sol governance concept (previously deployed on Arc testnet), this project extends on-chain voting with programmable USDC treasury execution using Circle's Contracts and Wallets infrastructure.

**Track:** DeFi  
**Stack:** Solidity, Arc L1, Circle Wallets API, ethers.js, HTML/JS frontend

## Current Progress (Mid-submission Checkpoint - Aug 2026)

- [x] Core smart contract: Proposal → On-chain vote → Automatic USDC execution
- [x] Basic frontend (wallet connect, create proposal, vote, execute)
- [ ] Full Circle Wallets API + Contracts integration
- [ ] Deployed & verified on Arc Testnet
- [ ] Polished UI + real-time events

## Network Info (Arc Testnet)

| Item | Value |
|------|-------|
| Chain ID | 5042002 |
| RPC | https://rpc.testnet.arc.io |
| Explorer | https://testnet.arcscan.app |
| USDC | 0x3600000000000000000000000000000000000000 |
| Faucet | https://faucet.circle.com |

## How to run locally

1. Deploy `contracts/ArcVoteTreasury.sol` to Arc Testnet (Remix recommended)
2. Fund the contract with testnet USDC
3. Open `frontend/index.html` in browser
4. Connect MetaMask (add Arc Testnet first)

## Next Steps

- Integrate Circle Developer-Controlled Wallets for automated treasury execution
- Add voting weight / time-lock / multi-sig
- Full demo video for final submission
