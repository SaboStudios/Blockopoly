import { useReadContract, useWriteContract } from "wagmi";
import nftabi from "../game/NFT.json";
import bankabi from "../game/Bank.json";
import { data } from "react-router";

export const nftAddress = "0xd2F6fc7c62c3458849b14167540d098D86c100E3";
export const bankAddress = "0x663Cd2903055c4dff669A977f958d31c4AC9d25e";

export function useRead(fnName) {
  const { data, isFetching } = useReadContract({
    abi: nftabi,
    address: nftAddress,
    functionName: fnName,
  });

  return { data, isFetching };
}

export function useReadBank(fnName) {
  const { data, isFetching } = useReadContract({
    abi: bankabi,
    address: bankAddress,
    functionName: fnName,
  });

  return { data, isFetching };
}

export function useReadBalance(addr) {
  const { data, isFetching } = useReadContract({
    abi: bankabi,
    address: bankAddress,
    functionName: "bal",
    args: [addr],
  });

  return { data, isFetching };
}

export function useWrite({ tokenId }) {
  const { data: hash, writeContract } = useWriteContract();

  async function writeHandler() {
    writeContract({
      address: nftAddress,
      abi: nftabi,
      functionName: "mint",
      args: [tokenId],
    });
  }

  writeHandler();
  //return { data, hash };
}
