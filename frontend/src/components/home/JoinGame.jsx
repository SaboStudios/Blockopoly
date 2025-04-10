import React from 'react'
import bg from '../../assets/bg.svg'
import { FaDiamond } from "react-icons/fa6";
import { IoGameControllerOutline } from "react-icons/io5";

const JoinGame = () => {
  return (
   <section style={{ backgroundImage: `url(${bg})`}} className='bg-cover bg-center bg-dark/80 bg-blend-overlay text-white text-center py-14 mt-18 px-6'>
<h2 className="text-[22px] lg:text-[42px] md:text-[42px] font-bold font-orbitron mb-6">Join a Game</h2>
<p className='flex justify-center lg:items-center md:items-center  mb-3'><FaDiamond className='lg:mr-4 md:mr-3 mr-2'/> No downloads required – just connect & start playing!</p>
<p className='flex justify-center lg:items-center md:items-center  mb-3'><FaDiamond className='lg:mr-4 md:mr-3 mr-2'/>Compete with friends & global players in real-time.</p>
<p className='flex justify-center lg:items-center md:items-center  mb-3'><FaDiamond className='lg:mr-4 md:mr-3 mr-2'/>Own & monetize properties like never before!</p>
  <button className="flex items-center bg-secondary text-primary font-orbitron py-3 w-[100%] lg:w-[20%] md:w-[40%] justify-center px-6 rounded-full text-[20px] shadow-[0_0_25px_#0FF0FC] hover:shadow-[0_0_40px_#0FF0FC] transition-all duration-300 mx-auto mt-6">
          Join Game <IoGameControllerOutline className="ml-2" />
        </button>
   </section>
  )
}

export default JoinGame