import React, { useState, useEffect } from "react";
import { PiWarningCircleFill } from "react-icons/pi";

const ScreenRule = ({ children }) => {
  const [isDesktop, setIsDesktop] = useState(false);

  useEffect(() => {
    const checkScreenSize = () => setIsDesktop(window.innerWidth >= 1000);

    if (typeof window !== "undefined") {
      checkScreenSize(); 
      window.addEventListener("resize", checkScreenSize);
    }

    return () => {
      window.removeEventListener("resize", checkScreenSize);
    };
  }, []);

  return (
    <div className="relative w-full h-full">
      {!isDesktop && (
        <div className="fixed inset-0 flex items-center justify-center bg-black/90 bg-opacity-50 z-50">
         
            <div className="flex items-center">
              <PiWarningCircleFill className="text-[70px] mr-2 text-red-500" />
              <p className="text-white w-[50%] text-[14px]">
                This application is optimized for desktop screens. Please switch
                to a larger screen for the best experience.
              </p>
            </div>
        </div>
      )}

      <div
        style={{
          filter: isDesktop ? "none" : "blur(8px)",
          pointerEvents: isDesktop ? "auto" : "none",
        }}
        className="relative w-full h-full"
      >
        {children}
      </div>
    </div>
  );
};

export default ScreenRule;
