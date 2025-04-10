import React from 'react'
import SlidingStack from './SlidingStack'

const Hiw = () => {
  return (
   <section className='w-[90%] mx-auto text-center my-12 overflow-hidden'>
     <h2 className="text-[22px] lg:text-[42px] md:text-[42px] font-bold font-orbitron bg-gradient-to-r  from-secondary to-grey bg-clip-text text-transparent inline-block mb-16">
     How it Works
        </h2>
        <div className='flex justify-between flex-col lg:flex-row md:flex-row'>
            <div className='w-[100%] lg:w-[35%] md:w-[35%] text-white font-orbitron text-left my-auto'>
                <p className='bg-white/15 rounded-full py-5 px-6 mb-4 text-[14px] lg:text-[18px] md:text-[18px]'><span className='bg-secondary shadow-[0_0_15px_#0FF0FC] hover:shadow-[0_0_25px_#0FF0FC] transition-all duration-300 font-bold text-primary py-3 px-5 rounded-full mr-4'>1</span>Connect your Wallet</p>
                <p className='bg-white/15 rounded-full py-5 px-6 mb-4 text-[14px] lg:text-[18px] md:text-[18px]'><span className='bg-secondary shadow-[0_0_15px_#0FF0FC] hover:shadow-[0_0_25px_#0FF0FC] transition-all duration-300 font-bold text-primary py-3 px-5 rounded-full mr-4'>2</span>Join a Game & Play</p>
                <p className='bg-white/15 rounded-full py-5 px-6 mb-4 text-[14px] lg:text-[18px] md:text-[18px]'><span className='bg-secondary shadow-[0_0_15px_#0FF0FC] hover:shadow-[0_0_25px_#0FF0FC] transition-all duration-300 font-bold text-primary py-3 px-5 rounded-full mr-4'>3</span>Trade, Strategize & Dominate</p>
                <p className='bg-white/15 rounded-full py-5 px-6 mb-4 text-[14px] lg:text-[18px] md:text-[18px]'><span className='bg-secondary shadow-[0_0_15px_#0FF0FC] hover:shadow-[0_0_25px_#0FF0FC] transition-all duration-300 font-bold text-primary py-3 px-5 rounded-full mr-4'>4</span>Climb the Leaderboard</p>
            </div>
            <div className='w-[100%] lg:w-[62%] md:w-[62%]'>
            <SlidingStack />
            </div>
        </div>
   </section>
  )
}

export default Hiw