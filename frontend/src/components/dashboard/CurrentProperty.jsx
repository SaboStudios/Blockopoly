import { useCorePoly } from "../../context/CorePolyContext";

import properties from "../../game/monopoly.json";

const CurrentProperty = () => {
  const { playerPosition } = useCorePoly();

  // Find the property at the player's current position
  const currentProperty = properties.properties.find(
    (property) => property.position === playerPosition
  );

  if (!currentProperty)
    return <p className="text-center">No property found.</p>;

  return (
    <div className="border p-4 rounded-xl bg-gray-100 shadow-lg w-80 text-center">
      <h2 className="text-xl font-bold mb-2">🏠 {currentProperty.name}</h2>
      <p className="text-gray-700">Owner: {currentProperty.owner || "Bank"}</p>
      <p className="text-gray-700">
        Market Value: ${currentProperty.price || 0}
      </p>
      <p className="text-gray-700">Rent: ${currentProperty.rent || 0}</p>

      {currentProperty.owner === "Bank" ? (
        <button
          className="bg-green-500 text-white px-4 py-2 rounded mt-2 hover:bg-green-600"
          onClick={() =>
            alert(
              `Purchased ${currentProperty.name} for $${currentProperty.price}!`
            )
          }
        >
          Buy for ${currentProperty.price}
        </button>
      ) : (
        <div>
          <button
            className="bg-green-500 text-white px-4 py-2 rounded mt-2 hover:bg-blue-600"
            onClick={() =>
              alert(`Paid rent of $${currentProperty.price} to "Bank`)
            }
          >
            buy Property (${currentProperty.price})
          </button>
          <button
            className="bg-red-500 text-white px-4 py-2 rounded mt-2 hover:bg-blue-600"
            onClick={() =>
              alert(
                `Paid rent of $${currentProperty.rent} to ${currentProperty.owner}`
              )
            }
          >
            Pay Rent (${currentProperty.rent})
          </button>
          <button
            className="bg-red-500 text-white px-4 py-2 rounded mt-2 hover:bg-blue-600"
            onClick={() =>
              alert(
                `Paid rent of $${currentProperty.rent} to ${currentProperty.owner}`
              )
            }
          >
            Mortgage Property (${currentProperty.price / 2})
          </button>
          <button
            className="bg-green-500 text-white px-4 py-2 rounded mt-2 hover:bg-blue-600"
            onClick={() =>
              alert(
                `Paid rent of $${currentProperty.rent} to ${currentProperty.owner}`
              )
            }
          >
            UnMortgage Property (${currentProperty.price})
          </button>
        </div>
      )}
    </div>
  );
};

export default CurrentProperty;
