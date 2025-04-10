import { useState } from "react";
import properties from "../../game/monopoly.json";
import chanceImg from "../../assets/chance.svg";
import chestImg from "../../assets/chest.svg";
import { useCorePoly } from "../../context/CorePolyContext";

const groupColors = {
  Purple: "bg-purple-500",
  Violet: "bg-red-300",
  darkgreen: "bg-green-800",
  darkblue: "bg-blue-800",
  Orange: "bg-orange-500",
  Red: "bg-red-900",
  Yellow: "bg-yellow-400",
  lightgreen: "bg-green-400",
  Special: "",
  Utilities: "",
  Railroad: "",
};

const shouldHaveBorder = (group) =>
  !["Special", "Utilities", "Railroad"].includes(group);

const getSortedProperties = (min, max) =>
  properties.properties
    .filter((item) => item.position >= min && item.position <= max)
    .sort((a, b) => a.position - b.position);

const BoardCell = ({ item, position, isPlayerHere }) => {
  const colorClasses = {
    top: "bottom-0 left-0 w-full h-[6px]",
    bottom: "top-0 left-0 w-full h-[6px]",
    left: "right-0 top-0 h-full w-[6px]",
    right: "left-0 top-0 h-full w-[6px]",
  };

  const textRotation = {
    top: "rotate-180",
    bottom: "rotate-0",
    left: "rotate-90",
    right: "-rotate-90",
  };

  return (
    <div className="relative flex w-full h-full border border-dark bg-green-100 hover:bg-black/30">
      {shouldHaveBorder(item.group) && (
        <div
          className={`absolute ${colorClasses[position]} ${
            groupColors[item.group]
          }`}
        />
      )}
      <div
        className={`flex flex-col items-center justify-center text-[10px] w-full h-full transform ${textRotation[position]}`}
      >
        <h3 className="font-black text-center p-1">
          {isPlayerHere ? "🎯" : item.name}
        </h3>
        {item.price && <p>${item.price}</p>}
      </div>
    </div>
  );
};

export default function GameBoard() {
  const { playerPosition, dice1, dice2, rollDice } = useCorePoly();

  const bottomRow = getSortedProperties(0, 10).reverse();
  const topRow = getSortedProperties(20, 30);
  const leftRow = getSortedProperties(11, 19).reverse();
  const rightRow = getSortedProperties(31, 39);

  return (
    <div className="grid grid-cols-11 grid-rows-11 w-[80vw] h-[80vw] max-w-[800px] max-h-[800px] border border-dark bg-green-100">
      <div className="col-span-11 flex">
        {topRow.map((item) => (
          <div key={item.id} className="w-[9%]">
            <BoardCell
              item={item}
              position="top"
              isPlayerHere={item.position === playerPosition}
            />
          </div>
        ))}
      </div>

      <div className="row-span-9 flex flex-col">
        {leftRow.map((item) => (
          <div key={item.id} className="h-[11%]">
            <BoardCell
              item={item}
              position="left"
              isPlayerHere={item.position === playerPosition}
            />
          </div>
        ))}
      </div>

      <div className="col-span-9 row-span-9 flex flex-col items-center justify-center text-xl font-bold">
        <img
          src={chestImg}
          alt="Community Chest"
          className="mb-auto lg:w-[150px] md:w-[100px] mx-auto"
        />
        <div className="bg-red-700 rounded-xl p-4 text-white font-orbitron text-[40px]">
          <p>Corepoly</p>
        </div>
        <img
          src={chanceImg}
          alt="Chance"
          className="mt-auto lg:w-[150px] md:w-[100px] mx-auto"
        />
      </div>

      <div className="row-span-9 flex flex-col">
        {rightRow.map((item) => (
          <div key={item.id} className="h-[11%]">
            <BoardCell
              item={item}
              position="right"
              isPlayerHere={item.position === playerPosition}
            />
          </div>
        ))}
      </div>

      <div className="col-span-11 flex">
        {bottomRow.map((item) => (
          <div key={item.id} className="w-[9%]">
            <BoardCell
              item={item}
              position="bottom"
              isPlayerHere={item.position === playerPosition}
            />
          </div>
        ))}
      </div>
    </div>
  );
}
