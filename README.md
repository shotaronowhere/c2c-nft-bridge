# c2c-nft-bridge
mainnet -> starknet nft bridge based on counterfactual deployments.

This project is based on an idea from [fredlacs](https://github.com/fredlacs/c2c-nft-bridge) which proposes using counterfactual contract deployments as a mechanism for nft transfer which is cheap, elegant, and simple. Fred's POC considers EVM chains only. 

This project implements a POC where the destination chain is on starknet, and the sending chain is ethereum.

<img width="600" alt="image" src="https://github.com/shotaronowhere/c2c-nft-bridge/assets/10378902/9c275f3b-ded6-48f5-b1db-0e29985945d0">

# how does it work?

The user on the sending chain (L1) sends their nft to a pre-calculated deployment address where an escrow contract can be deployed in the future via the CREATE2 opcode. Correspondingly, the user mints an NFT on L2 which gives the owner the right to deploy an escrow contract to the L1 address where the NFT was sent via an L2 -> L1 message. This construction provides the cheapest NFT transfers as the sending chain cost is a simple transfer and the destination chain cost is minting.

<img width="600" alt="image" src="https://github.com/shotaronowhere/c2c-nft-bridge/assets/10378902/3d89cb92-8d98-47de-b450-0a9a91f8b16d">

To recover the original nft on L1, the user burns their L2 nft and initiates an L2 -> L1 message.

<img width="600" alt="image" src="https://github.com/shotaronowhere/c2c-nft-bridge/assets/10378902/c116feea-54e5-4e5c-a7ea-3db8e0ee556a">

On L1, consuming the L2 message via the [starknetcore](https://docs.starknet.io/documentation/tools/important_addresses/) deploys an escrow contract to the location of the NFT which transfers the NFT to the recipient then destroys the contract (gas savings).

<img width="600" alt="image" src="https://github.com/shotaronowhere/c2c-nft-bridge/assets/10378902/fa70b68b-147c-44dc-9668-44fa9d05d40a">

# what's the point?

Counterfactual NFT tranfers enables L1 / L2 <-> L1 / L2 nft transfers without ever touching L1.

<img width="600" alt="image" src="https://github.com/shotaronowhere/c2c-nft-bridge/assets/10378902/6c3c5902-f3eb-4a19-a9a3-9f289be02a2b">

# future work

Counterfactual deployments can be used for bidirectional nft cross-chain transfers.

<img width="600" alt="image" src="https://github.com/shotaronowhere/c2c-nft-bridge/assets/10378902/a7caef9e-162e-4271-8030-69d27b5393f5">

However, the more transfers, the more native bridge message passing calls routing through L1 are required to 'settle'.

<img width="600" alt="image" src="https://github.com/shotaronowhere/c2c-nft-bridge/assets/10378902/c8f56a32-df72-4716-89f3-eab5420fc132">

We can use storage proofs with Herodotus to eliminate the need to call native bridges by reading the stateroot of other chains directly. The cost to settle will then scale with the cost of batching storage proofs of multiple storage slots, but certainly more time and cost efficient than calling native bridges hitting L1 to settle sequentially.

<img width="600" alt="image" src="https://github.com/shotaronowhere/c2c-nft-bridge/assets/10378902/768b5f34-525b-4fcc-8a21-941637f40174">
