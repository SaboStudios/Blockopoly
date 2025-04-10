import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.jsx";
import { AppKitProvider } from "./KitProvider.jsx";
import { CorepolyProvider } from "./context/CorePolyContext.jsx";

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <AppKitProvider>
      <CorepolyProvider>
        <App />
      </CorepolyProvider>
    </AppKitProvider>
  </StrictMode>
);
