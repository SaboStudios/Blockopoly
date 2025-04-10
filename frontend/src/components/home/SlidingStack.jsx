import { useState } from "react";
import { motion } from "framer-motion";

const images = [
  "https://img.freepik.com/free-vector/realistic-magician-hat-with-magic-stick_1284-13004.jpg?ga=GA1.1.770405697.1735080768&semt=ais_hybrid",
  "https://img.freepik.com/free-photo/yellow-dices-yellow-background_23-2148952393.jpg?ga=GA1.1.770405697.1735080768&semt=ais_hybrid",
  "https://img.freepik.com/free-vector/cute-money-holding-money-bag-with-gold-coin-cartoon-vector-icon-illustration-people-finance-flat_138676-13128.jpg?ga=GA1.1.770405697.1735080768&semt=ais_hybrid",
  "https://img.freepik.com/free-vector/hand-drawn-board-games-element_23-2151071910.jpg?ga=GA1.1.770405697.1735080768&semt=ais_hybrid",
];

const SlidingStack = () => {
  const [cards, setCards] = useState(images);

  const handleSlide = () => {
    const updatedCards = [...cards];
    const firstCard = updatedCards.shift(); 
    updatedCards.push(firstCard); 
    setCards(updatedCards);
  };

  return (
    <div className="relative lg:w-[600px] lg:h-[450px] md:w-[500px] md:h-[400px] w-[300px] h-[250px] mt-20 mx-auto">
    {cards.map((img, index) => (
      <motion.img
          key={img}
          src={img}
          alt={`Card ${index + 1}`}
          className="absolute w-full h-full object-cover rounded-lg transition-all duration-500 bg-dark hidden lg:block md:block"
          initial={{
            x: index * 40,
            y: -index * 10,
            rotate: index * 5,
            opacity: 1,
            filter: index === 0 ? "brightness(1)" : "brightness(0.5)", 
          }}
          animate={{
            x: index * 40,
            y: -index * 10,
            rotate: index * 5,
            filter: index === 0 ? "brightness(1)" : "brightness(0.5)", 
            boxShadow:
              index === 0
                ? "0px 0px 25px #0FF0FC" 
                : "none",
          }}
          transition={{ duration: 0.5 }}
          style={{ zIndex: cards.length - index }}
          onClick={handleSlide}
        />
    ))}
         {cards.map((img, index) => (
        <motion.img
          key={img}
          src={img}
          alt={`Card ${index + 1}`}
          className={`absolute w-full h-full object-cover rounded-lg block bg-dark lg:hidden md:hidden shadow-lg transition-all duration-500 ${
            index === 0 ? "glow-effect" : "opacity-60 scale-[0.95]"
          }`}
          initial={{
            y: index * 10,
            scale: index === 0 ? 1 : 0.95, 
          }}
          animate={{
            y: index * 10,
            scale: index === 0 ? 1 : 0.95,
          }}
          transition={{ duration: 0.5 }}
          style={{ zIndex: cards.length - index }}
          onClick={handleSlide}
        />
      ))}
  </div>
  );
};

export default SlidingStack;
