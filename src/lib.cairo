pub mod systems {
    pub mod actions;
    pub mod Blockopoly;
    pub mod BlockopolyNFT;
}
pub mod interfaces {
    pub mod IActions;
    pub mod IBlockopoly;
    pub mod IBlockopolyNFT;
}

pub mod model {
    pub mod game_model;
    pub mod player_model;
}

pub mod tests {
    mod test_world;
}

pub mod components{
    pub mod player{
        pub mod player;
        pub mod mock;
        pub mod interface;
        pub mod types;
        pub mod test;
    }
}