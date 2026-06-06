"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function EmpleadosPage() {
  const [username, setUsername] = useState("");
  const router = useRouter();

  useEffect(() => {
    const auth = localStorage.getItem("isAuthenticated");
    if (!auth) {
      router.push("/");
      return;
    }
    setUsername(localStorage.getItem("username") ?? "");
  }, [router]);

  const handleLogout = () => {
    localStorage.clear();
    router.push("/");
  };

  return (
    <main style={{
      minHeight: "100vh",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      fontFamily: "Tahoma, Verdana, sans-serif",
      background: "#f7f7f7",
      gap: "12px",
    }}>
      <h1 style={{ fontSize: "24px", fontWeight: 600 }}>
        Bienvenido{username ? `, ${username}` : ""}
      </h1>
      <p style={{ color: "#6a6a6a", fontSize: "14px" }}>Módulo Empleado</p>

      <button
        id="link-planilla"
        onClick={() => router.push("/planilla")}
        style={{
          padding: "8px 24px",
          borderRadius: "4px",
          border: "none",
          background: "#1aa04a",
          color: "#fff",
          fontSize: "14px",
          fontWeight: 600,
          cursor: "pointer",
        }}
      >
        Ver Planilla
      </button>

      <button
        onClick={handleLogout}
        style={{
          marginTop: "8px",
          padding: "8px 24px",
          borderRadius: "4px",
          border: "none",
          background: "#c53030",
          color: "#fff",
          fontSize: "14px",
          fontWeight: 600,
          cursor: "pointer",
        }}
      >
        Cerrar sesión
      </button>
    </main>
  );
}
