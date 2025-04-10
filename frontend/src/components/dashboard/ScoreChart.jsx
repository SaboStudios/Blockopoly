import React from "react";
import { useCorePoly } from "../../context/CorePolyContext";
import { useWriteContract } from "wagmi";
import { nftAddress } from "../../context/Contract";
import nftabi from "../../game/NFT.json";
const ScoreChart = () => {
  const { playerPosition, dice1, dice2, rollDice, player1bal, player2bal } =
    useCorePoly();
  const { data: hash, writeContract } = useWriteContract();

  async function handler() {
    // writeContract({
    //   address: nftAddress,
    //   abi: nftabi,
    //   functionName: "populateRent",
    //   // args: ["0x09c5096AD92A3eb3b83165a4d177a53D3D754197"],
    //   args: [],
    // });
    rollDice();
  }
  return (
    <div className="text-white px-6 w-[20vw]">
      <div>
        <h2 className="lg:text-[30px] md:text-[30px] text-[24px] mb-6 font-orbitron bg-gradient-to-r  from-secondary to-grey bg-clip-text text-transparent inline-block">
          Players
        </h2>
        <p className="flex justify-between items-center my-4">
          Player 1 <span className="border p-2">${player1bal}</span>
        </p>
        <p className="flex justify-between items-center my-4">
          Player 2 <span className="border p-2">${player2bal}</span>
        </p>
      </div>
      <div>
        <h2 className="lg:text-[22px] md:text-[22px] text-[24px] font-orbitron bg-gradient-to-r  from-secondary to-grey bg-clip-text text-transparent inline-block">
          Bank
        </h2>
        <p className="flex justify-between items-center my-4">
          Balance <span className="border p-2">${player2bal}</span>
        </p>
      </div>
      <button
        className="bg-secondary text-primary font-orbitron 
         py-2 px-6 rounded-full text-[16px] w-[100%] font-bold hover:border hover:bg-primary hover:border-secondary hover:text-secondary"
        onClick={handler}
      >
        Roll Dice
      </button>
      <p className="flex justify-between items-center my-4">
        dice1: {dice1} dice2: {dice2}
      </p>
    </div>
  );
};

export default ScoreChart;
