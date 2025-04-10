import { useAppKit, useAppKitAccount } from "@reown/appkit/react";
import { useEffect } from "react";
import { useNavigate } from "react-router";

export default function ConnectButton() {
  const { status } = useAppKitAccount();
  const { open, close } = useAppKit();

  const navigate = useNavigate();

  useEffect(() => {
    if (status === "connected") {
      navigate("/dashboard");
    } else {
      navigate("/");
    }
  }, [navigate, status]);

  return (
    <div
      onClick={() => open()}
      className="opacity- w-full absolute top-0 px-6 border"
    >
      <appkit-button />
    </div>
  );
}
