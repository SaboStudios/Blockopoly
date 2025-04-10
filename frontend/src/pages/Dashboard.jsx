import React from "react";
import Header from "../components/home/Header";
import { MdGeneratingTokens } from "react-icons/md";
import { IoGameControllerOutline } from "react-icons/io5";
import { RiGamepadLine } from "react-icons/ri";
import { MdShoppingCart } from "react-icons/md";
import { NavLink } from 'react-router'

const Dashboard = () => {
  return (
    <div className="bg-gradient-to-br from-primary to-dark/80 py-4 h-auto lg:h-[100vh] md:h-[100vh]">
      <Header />
      <div className="hero-section py-8">
      <div className="bg-secondary text-primary shadow-[0_0_25px_#0FF0FC] hover:shadow-[0_0_40px_#0FF0FC] transition-all duration-300 w-[90%] lg:w-[30%] md:w-[30%] mx-auto rounded-xl p-6 mt-8">
        <img
          src="https://img.freepik.com/free-psd/abstract-background-design_1297-75.jpg?ga=GA1.1.770405697.1735080768&semt=ais_hybrid"
          alt=""
          className="w-[50px] h-[50px] object-cover object-center rounded-full mb-4 mx-auto"
        />
        <p className="font-orbitron font-[600] flex justify-between mb-4">
          Token Balance{" "}
          <span className="flex items-center">
            128 <MdGeneratingTokens />
          </span>
        </p>
        <p className="font-orbitron font-[600] flex justify-between">
          Ongoing Games <span>10</span>
        </p>
      </div>
      <div className="my-8">
        <NavLink to='/dashboard/game' className="flex items-center bg-secondary text-primary font-orbitron py-4 w-[90%] lg:w-[30%] md:w-[40%] justify-center px-6 rounded-full text-[16px] lg:text-[20px] md:text-[20px] shadow-[0_0_25px_#0FF0FC] hover:shadow-[0_0_40px_#0FF0FC] transition-all duration-300 mx-auto mb-6">
          Start New Game <IoGameControllerOutline className="ml-2" />
        </NavLink>
        <button className="flex items-center bg-secondary text-primary font-orbitron py-4 w-[90%] lg:w-[30%] md:w-[40%] justify-center px-6 rounded-full text-[16px] lg:text-[20px] md:text-[20px] shadow-[0_0_25px_#0FF0FC] hover:shadow-[0_0_40px_#0FF0FC] transition-all duration-300 mx-auto mb-6">
          Join Existing Game <RiGamepadLine className="ml-2" />
        </button>
        <button className="flex items-center bg-secondary text-primary font-orbitron py-4 w-[90%] lg:w-[30%] md:w-[40%] justify-center px-6 rounded-full text-[16px] lg:text-[20px] md:text-[20px] shadow-[0_0_25px_#0FF0FC] hover:shadow-[0_0_40px_#0FF0FC] transition-all duration-300 mx-auto mb-6">
          NFT Marketplace <MdShoppingCart className="ml-2" />
        </button>
      </div>
      </div>
    </div>
  );
};

export default Dashboard;