use starknet::{ContractAddress, EthAddress, ClassHash};

#[starknet::interface]
trait IMinter<TContractState> {
    fn mint(
        ref self: TContractState,
        class_hash: ClassHash,
        contract_address_salt: felt252,
        initialize_calldata: Span<felt252>
    ) -> ContractAddress;

    fn withdraw(
        ref self: TContractState,
            nft_address: ContractAddress,
            token_id: u256,
            claim_to: EthAddress
    );
}

#[starknet::contract]
mod Minter {
    use openzeppelin::token::erc721::interface::IERC721DispatcherTrait;
use super::IMinter;
    use c2c::nft::{NFT, INFTDispatcher, INFTDispatcherTrait};
    use openzeppelin::token::erc721::ERC721::interface::IERC721Dispatcher;
    use starknet::{
        ContractAddress, ClassHash, get_caller_address, EthAddress,
        syscalls::{deploy_syscall, send_message_to_l1_syscall}
    };
    use c2c::nft;
    use traits::TryInto;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NFTDeployed: NFTDeployed
    }

    #[derive(Drop, starknet::Event)]
    struct NFTDeployed {
        class_hash: ClassHash,
        nft_address: ContractAddress
    }

    #[storage]
    struct Storage {
        claimer: EthAddress
    }

    #[constructor]
    fn constructor(ref self: ContractState, _claimer: EthAddress) {
        self.claimer.write(_claimer);
    }

    #[external(v0)]
    impl Minter of IMinter<ContractState> {
        fn mint(
            ref self: ContractState,
            class_hash: ClassHash,
            contract_address_salt: felt252,
            initialize_calldata: Span<felt252>) -> ContractAddress {
                let (nft_address, _) = deploy_syscall(
                        class_hash, contract_address_salt, array![].span(), false
                    ).unwrap();

                self.emit(Event::NFTDeployed(NFTDeployed { class_hash, nft_address }));

                nft_address
            }

        fn withdraw(
            ref self: ContractState,
            nft_address: ContractAddress,
            token_id: u256,
            claim_to: EthAddress
        ) {
            let owner = IERC721Dispatcher { contract_address: nft_address }.owner_of(token_id);
            assert(get_caller_address() == owner, 'Only factory can burn');

            let commithash = INFTDispatcher { contract_address: nft_address }.commithash();
            let minter = INFTDispatcher { contract_address: nft_address }.minter();

            INFTDispatcher { contract_address: nft_address }.burn(token_id);
            
            let mut payload: Array<felt252> = ArrayTrait::new();
            
            payload.append(commithash.low.into());
            payload.append(commithash.high.into());
            payload.append(minter.into());
            payload.append(claim_to.into());

            send_message_to_l1_syscall(self.claimer.read().into(), payload: payload.span());
        }
    }
}