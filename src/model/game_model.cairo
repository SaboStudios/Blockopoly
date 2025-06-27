use starknet::{ContractAddress, contract_address_const};
// Keeps track of the state of the game

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct GameCounter {
    #[key]
    pub id: felt252,
    pub current_val: u256,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct GameBalance {
    #[key]
    pub playe_address: ContractAddress,
    #[key]
    pub game_id: u256,
    pub balance: u256,
}


#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct GameListOfPlayers {
    #[key]
    pub game_id: u256,
    list_of_addresses: Array<ContractAddress>
}


#[derive(Drop, Clone, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub id: u256, // Unique id of the game
    pub created_by: felt252, // Address of the game creator
    pub is_initialised: bool, // Indicate whether game with given Id has been created/initialised
    pub status: GameStatus, // Status of the game
    pub mode: GameType, // Mode of the game
    pub ready_to_start: bool, // Indicate whether game can be started
    pub winner: felt252, // First winner position 
    pub next_player: felt252, // Address of the player to make the next move
    pub number_of_players: u8, // Number of players in the game
    pub rolls_count: u256, //  Sum of all the numbers rolled by the dice
    pub rolls_times: u256, // Total number of times the dice has been rolled
    pub dice_face: u8, // Last value of dice thrown
    pub player_chance: ContractAddress, // Next player to make move
    pub has_thrown_dice: bool, // Whether the dice has been thrown or not
    pub game_condition: Array<u32>,
    pub hat: felt252, // item on the board
    pub car: felt252, // item on the board
    pub dog: felt252, // item on the board
    pub thimble: felt252, // item on the board
    pub iron: felt252, // item on the board
    pub battleship: felt252, // item on the board
    pub boot: felt252, // item on the board
    pub wheelbarrow: felt252, // item on the board
    pub player_hat: felt252, // item use address on the board
    pub player_car: felt252, // item use address on the board
    pub player_dog: felt252, // item use address on the board
    pub player_thimble: felt252, // item use address on the board
    pub player_iron: felt252, // item use address on the board
    pub player_battleship: felt252, // item use address on the board
    pub player_boot: felt252, // item use address on the board
    pub player_wheelbarrow: felt252,
    pub players_joined: u8,
}

pub trait GameTrait {
    // Create and return a new game
    fn new(
        id: u256,
        created_by: felt252,
        game_type: GameType,
        player_hat: felt252,
        player_car: felt252,
        player_dog: felt252,
        player_thimble: felt252,
        player_iron: felt252,
        player_battleship: felt252,
        player_boot: felt252,
        player_wheelbarrow: felt252,
        number_of_players: u8,
    ) -> Game;
    fn restart(ref self: Game);
    fn terminate_game(ref self: Game);
}


// Represents the status of the game
// Can either be Ongoing or Ended
#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum GameStatus {
    Pending, // Waiting for players to join (in multiplayer mode)
    Ongoing, // Game is ongoing
    Ended // Game has ended
}

// Represents the game mode
// Can either be SinglePlayer or Multiplayer
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum GameType {
    PublicGame, // Play with computer
    PrivateGame // Play online with friends
}


impl GameImpl of GameTrait {
    fn new(
        id: u256,
        created_by: felt252,
        game_type: GameType,
        player_hat: felt252,
        player_car: felt252,
        player_dog: felt252,
        player_thimble: felt252,
        player_iron: felt252,
        player_battleship: felt252,
        player_boot: felt252,
        player_wheelbarrow: felt252,
        number_of_players: u8,
    ) -> Game {
        let zero_address = contract_address_const::<0x0>();
        Game {
            id,
            created_by,
            is_initialised: true,
            status: GameStatus::Pending,
            mode: game_type,
            ready_to_start: false,
            player_hat,
            player_car,
            player_dog,
            player_thimble,
            player_iron,
            player_battleship,
            player_boot,
            player_wheelbarrow,
            next_player: zero_address.into(),
            winner: zero_address.into(),
            rolls_times: 0,
            rolls_count: 0,
            number_of_players,
            dice_face: 0,
            player_chance: zero_address.into(),
            has_thrown_dice: false,
            game_condition: array![
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
                0_u32,
            ],
            hat: 'hat',
            car: 'car',
            dog: 'dog',
            thimble: 'thimble',
            iron: 'iron',
            battleship: 'battleship',
            boot: 'boot',
            wheelbarrow: 'wheelbarrow',
            players_joined: 0,
        }
    }

    fn restart(ref self: Game) {
        let zero_address = contract_address_const::<0x0>();
        self.next_player = zero_address.into();
        self.rolls_times = 0;
        self.rolls_count = 0;
        self.number_of_players = 0;
        self.dice_face = 0;
        self.player_chance = zero_address.into();
        self.has_thrown_dice = false;
    }

    fn terminate_game(ref self: Game) {
        self.status = GameStatus::Ended;
    }
}


#[generate_trait]
pub impl GameBalanceImpl of IGameBalance {
    fn deduct_game_balance(ref self: GameBalance, amount: u256) -> bool {
        true
    }

    fn increase_game_balance(ref self: GameBalance, amount: u256) -> bool {
        true
    }
}

