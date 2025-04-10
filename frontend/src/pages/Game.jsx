import React from "react";
import GameBoard from "../components/dashboard/Gameboard";
import ScreenRule from "../components/dashboard/ScreenRule";
import ScoreChart from "../components/dashboard/ScoreChart";
import CurrentProperty from "../components/dashboard/CurrentProperty";

const Game = () => {
  return (
    <div>
      <ScreenRule>
        <div className="flex">
          <GameBoard />
          <div>
            <ScoreChart />
            <CurrentProperty />
          </div>
        </div>
      </ScreenRule>
    </div>
  );
};

export default Game;
