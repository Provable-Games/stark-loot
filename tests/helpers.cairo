use snforge_std::{DeclareResultTrait, declare};
use stark_loot::contract::IStarkLootLibraryDispatcher;

pub fn library() -> IStarkLootLibraryDispatcher {
    let contract = declare("stark_loot").unwrap().contract_class();
    IStarkLootLibraryDispatcher { class_hash: *contract.class_hash }
}
