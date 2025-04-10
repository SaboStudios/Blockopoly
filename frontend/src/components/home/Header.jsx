import React, { useEffect } from "react";
import logo from "../../assets/logo.svg";
import mobileLogo from "../../assets/f-logo.svg";
// import ConnectButton from "./ConnectButton";
import { useAppKit, useAppKitAccount } from "@reown/appkit/react";
import { useNavigate } from "react-router";

const Header = () => {
  const { address, isConnected, status } = useAppKitAccount();
  const { open } = useAppKit();

  const navigate = useNavigate();

  useEffect(() => {
    if (status === "connected") {
      navigate("/dashboard");
    } else {
      navigate("/");
    }
  }, [navigate, status]);

  let userAddress;
  if (isConnected) {
    userAddress = `${address?.slice(-4)}...${address?.slice(-6)}`;
  }
  return (
    <header className="py-8">
      <nav className="w-[90%] mx-auto flex justify-between items-center bg-white/15 lg:p-6 md:p-6 p-4 rounded-xl">
        <img
          src={logo}
          alt=""
          className="w-[220px] h-[45px] hidden lg:block md:block"
        />
        <img
          src={mobileLogo}
          alt=""
          className="w-[70px] h-[45px] block lg:hidden md:hidden"
        />
        <button
          onClick={() => open()}
          className="bg-secondary text-primary font-orbitron 
         py-2 px-6 rounded-full text-[16px] relative"
        >
          {!isConnected && "connect wallet"}
          {isConnected && (userAddress ?? "")}
        </button>
      </nav>
    </header>
  );
};

export default Header;
