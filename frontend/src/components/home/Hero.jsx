import React from "react";
import dice from "../../assets/dice.gif";
import { IoGameControllerOutline } from "react-icons/io5";

const Hero = () => {
  return (
    <section className="text-center my-12 hero-section">
      <div className="w-[90%] lg:w-[70%] md:w-[70%] mx-auto">
        <h1 className="text-[32px] lg:text-[52px] md:text-[52px] font-bold font-orbitron bg-gradient-to-r  from-secondary to-grey bg-clip-text text-transparent inline-block">
          Own the Future of Monopoly – Play, Trade & Earn in Web3!
        </h1>
        <p className="w-[100%] lg:w-[50%] md:w-[50%]  mx-auto text-[18px] lg:text-[20px] md:text-[20px] my-4 font-[300] leading-10 text-white">
          Build, Buy, and Trade Properties as NFTs. Roll the Dice, Earn Crypto,
          and Dominate the Board in a Web3-Powered Monopoly Experience.
        </p>
        <img src={dice} alt="" className="w-[50%] mx-auto" />
        <button className="flex items-center bg-secondary text-primary font-orbitron py-4 w-[100%] lg:w-[30%] md:w-[40%] justify-center px-6 rounded-full text-[20px] shadow-[0_0_25px_#0FF0FC] hover:shadow-[0_0_40px_#0FF0FC] transition-all duration-300 mx-auto">
          Play Game <IoGameControllerOutline className="ml-2" />
        </button>
      </div>
    </section>
  );
};

export default Hero;
