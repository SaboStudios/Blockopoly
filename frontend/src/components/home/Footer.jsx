import React from 'react'
import fLogo from '../../assets/f-logo.svg'
import { FaSquareFacebook } from "react-icons/fa6";
import { AiFillInstagram } from "react-icons/ai";
import { FaYoutube } from "react-icons/fa";
import { FaSquareXTwitter } from "react-icons/fa6";

const Footer = () => {
  return (
    <footer className='text-white py-2'>
      <nav className='flex justify-between items-center w-[90%] mx-auto flex-col lg:flex-row md:flex-row'>
      <img src={fLogo} alt="" className='w-[80px] h-[80px] mb-3'/>
      <p className='order-3 lg:order-2 md:order-2 text-center mb-3'>&copy; All Rights Reserved - CorePoly 2025</p>
      <div className='flex text-3xl order-2 lg:order-3 md:order-3 mb-3'>
        <FaSquareFacebook className='mr-6'/>
        <AiFillInstagram className='mr-6' />
        <FaYoutube className='mr-6' />
        <FaSquareXTwitter />
      </div>
      </nav>
    </footer>
  )
}

export default Footer