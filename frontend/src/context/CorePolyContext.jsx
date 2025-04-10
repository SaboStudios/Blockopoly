import {
  createContext,
  useReducer,
  useEffect,
  useContext,
  useCallback,
} from "react";

import { useRead, useReadBalance, useReadBank, useWrite } from "./Contract";
import { useReadContract, useWriteContract } from "wagmi";
import nftabi from "../game/NFT.json";

const nftAddress = "0xd2F6fc7c62c3458849b14167540d098D86c100E3";
const CorepolyContext = createContext();

const players = [
  {
    address: "0x1234...",
    name: "Alice",
    balance: 1000,
    properties: [],
    isCurrentPlayer: true,
  },
  {
    address: "0x5678...",
    name: "Bob",
    balance: 800,
    properties: [],
    isCurrentPlayer: false,
  },
];

const initialState = {
  playerPosition: 0,
  diceRoll: [],
  dice1: 1,
  dice2: 1,
  currentProperty: 1,
  player1: "0x09c5096AD92A3eb3b83165a4d177a53D3D754197",
  player2: "0xE870b4814Ec306B88F77833cd6c98Eb388A30cbc",
};

function reducer(state, action) {
  switch (action.type) {
    case "rolldice": {
      const dice1 = Math.floor(Math.random() * 6) + 1;
      const dice2 = Math.floor(Math.random() * 6) + 1;
      const newPosition = (state.playerPosition + dice1 + dice2) % 40;

      return {
        ...state,
        playerPosition: newPosition,
        diceRoll: [dice1, dice2],
        dice1,
        dice2,
        currentProperty: newPosition,
      };
    }

    default:
      throw new Error("Unknown action type");
  }
}

function CorepolyProvider({ children }) {
  const [
    {
      playerPosition,
      diceRoll,
      dice1,
      dice2,
      currentProperty,
      player1,
      player2,
    },
    dispatch,
  ] = useReducer(reducer, initialState);

  const rollDice = () => {
    dispatch({ type: "rolldice" });
  };
  const { data, isFetching } = useRead("MAX_SUPPLY");
  const { data: a, b } = useReadBank("name");
  const { data: player1bal, c } = useReadBalance(
    "0x09c5096AD92A3eb3b83165a4d177a53D3D754197"
  );
  const { data: player2bal, d } = useReadBalance(
    "0xE870b4814Ec306B88F77833cd6c98Eb388A30cbc"
  );

  useEffect(() => {
    //asyncWriteData();
    console.log(data);
    console.log(a);
    console.log(player1bal);
    console.log(player2bal);
  }, [isFetching, data, a, b, player1bal, player2bal, c, d]);

  return (
    <CorepolyContext.Provider
      value={{
        playerPosition,
        diceRoll,
        dice1,
        dice2,
        currentProperty,
        rollDice,
        player1,
        player2,
        player1bal,
        player2bal,
      }}
    >
      {children}
    </CorepolyContext.Provider>
  );
}

function useCorePoly() {
  const context = useContext(CorepolyContext);
  if (context === undefined) {
    throw new Error(" UseCorePoly must be used within CorePoly provider");
  }
  return context;
}

export { CorepolyProvider, useCorePoly };
