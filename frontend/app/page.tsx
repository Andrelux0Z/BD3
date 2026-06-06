"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import styles from "./page.module.css";

const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:5246";

export default function Home() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");
  const [isSuccess, setIsSuccess] = useState(false);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setMessage("");

    try {
      const res = await fetch(`${apiBase}/api/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ usuario: username, password })
      });

      const data = await res.json();

      if (res.ok && data.success) {
        setMessage("Login exitoso! Bienvenido.");
        setIsSuccess(true);
        localStorage.setItem("isAuthenticated", "true");
        localStorage.setItem("idUsuario", data.idUsuario.toString());
        router.push("/empleados");
      } else {
        if (data.message) {
          setMessage(data.message);
        } else {
          setMessage("Credenciales incorrectas");
        }
        setIsSuccess(false);
      }
    } catch (error) {
      console.error(error);
      setMessage("Error de conexion con el backend.");
      setIsSuccess(false);
    } finally {
      setLoading(false);
    }
  };

  const buttonText = loading ? "Cargando..." : "Confirmar";
  const messageColor = isSuccess ? "green" : "red";

  return (
    <div className={styles.page}>
      <main className={styles.card}>
        <h1 className={styles.title}>Iniciar sesion</h1>

        <form className={styles.form} onSubmit={handleLogin} aria-label="Formulario de inicio de sesion">
          <div className={styles.field}>
            <label className={styles.label} htmlFor="username">
              Usuario:
            </label>
            <input
              className={styles.input}
              id="username"
              type="text"
              name="username"
              placeholder="Ejemplo: usuario"
              autoComplete="username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
            />
          </div>

          <div className={styles.field}>
            <label className={styles.label} htmlFor="password">
              Contrasena:
            </label>
            <input
              className={styles.input}
              id="password"
              type="password"
              name="password"
              placeholder="********"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          {message && (
            <p style={{ color: messageColor, marginTop: "1rem", textAlign: "center" }}>
              {message}
            </p>
          )}

          <div className={styles.actions}>
            <button className={styles.button} type="submit" disabled={loading}>
              {buttonText}
            </button>
          </div>
        </form>
      </main>
    </div>
  );
}
