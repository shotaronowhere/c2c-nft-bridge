use starknet::{ContractAddress, EthAddress, ClassHash};

#[starknet::interface]
trait INFT<TContractState> {
    fn burn(
        ref self: TContractState,
        token_id: u256,
    );
    fn commithash(ref self: TContractState) -> u256;
    fn minter(ref self: TContractState) -> ContractAddress;
}

#[starknet::contract]
mod NFT {
    use super::INFT;
    use starknet::{ContractAddress, EthAddress, get_caller_address, syscalls::deploy_syscall};
    use openzeppelin::token::erc721::ERC721;

    #[storage]
    struct Storage {
        commithash: u256,
        l1Address: EthAddress, // L1 nft contract address
        minter: ContractAddress, // msg.sender of mint()
        factory: ContractAddress, // factory contract address
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        _commithash: u256, // for withdrawal uint256(keccack256(abi.encodepacked(_L1Address, token_id, nonce)))
        _minter: ContractAddress,
        _l1Address: EthAddress, // convinience metadata
        _recipient: ContractAddress, // mint to
    ) {
        let name = 'C2C_Bridged_Nft';
        let symbol = 'C2CNFT';
        let caller = get_caller_address();

        self.commithash.write(_commithash);
        self.minter.write(_minter);
        self.l1Address.write(_l1Address);
        self.factory.write(caller);

        let mut unsafe_state = ERC721::unsafe_new_contract_state();

        ERC721::InternalImpl::initializer(ref unsafe_state, name, symbol);
        ERC721::InternalImpl::_mint(ref unsafe_state, _recipient, _commithash);
    }

    #[external(v0)]
    impl NFT of INFT<ContractState> {
        fn burn (
            ref self: ContractState,
            token_id: u256) {
            assert(get_caller_address() == self.factory.read(), 'Only factory can burn');
            let mut unsafe_state = ERC721::unsafe_new_contract_state();

            ERC721::InternalImpl::_burn(ref unsafe_state, token_id);
        }

        fn commithash(ref self: ContractState) -> u256 {
            self.commithash.read()
        }

        fn minter(ref self: ContractState) -> ContractAddress {
            self.minter.read()
        }
    }
}