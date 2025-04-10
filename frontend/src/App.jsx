import React from "react";
import {
  createBrowserRouter,
  Route,
  createRoutesFromElements,
  RouterProvider,
} from "react-router";
import Home from "./pages/Home";
import Dashboard from "./pages/Dashboard";
import Game from "./pages/Game";

const router = createBrowserRouter(
  createRoutesFromElements(
    <Route>
      <Route index element={<Home />} />
      <Route path="/dashboard" element={<Dashboard />} />
      <Route path="/dashboard/game" element={<Game />} />
    </Route>
  )
);

const App = () => {
  return (
    <div className="max-w-[1440px] mx-auto font-dmsans ">
      <RouterProvider router={router} />
    </div>
  );
};

export default App;
