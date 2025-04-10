import { createContext } from "react";
import { useReadContract, useWriteContract } from "wagmi";
import nftabi from "../game/NFT.json";

const nftAddress = "0xd2F6fc7c62c3458849b14167540d098D86c100E3";
// const ContractContext = createContext();

function ReadContract() {
  const { data: name } = useReadContract({
    address: nftAddress,
    abi: nftabi,
    functionName: "name",
    args: [],
  });

  console.log(name);

  //   return <div>Balance: {name?.toString()}</div>;
}
