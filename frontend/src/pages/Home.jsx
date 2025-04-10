import React from 'react'
import Header from '../components/home/Header'
import Hero from '../components/home/Hero'
import Hiw from '../components/home/Hiw'
import JoinGame from '../components/home/JoinGame'
import Footer from '../components/home/Footer'

const Home = () => {
  return (
    <div className='bg-gradient-to-br from-primary to-dark/80 py-4'>
      <Header />
      <Hero />
      <Hiw />
      <JoinGame />
      <Footer />
    </div>
  )
}

export default Home