"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

const API = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:5246";

interface Empleado {
  id: number;
  nombre: string;
  documentoIdentidad: string;
  puesto: string;
}

const fieldStyle: React.CSSProperties = {
  display: "flex",
  gap: "8px",
  alignItems: "center",
  width: "100%",
  maxWidth: "480px",
};

function inputStyle(): React.CSSProperties {
  return {
    padding: "8px 10px",
    borderRadius: "4px",
    border: "1px solid #ccc",
    fontSize: "14px",
    flex: 1,
    boxSizing: "border-box",
    outline: "none",
  };
}

export default function AdminPage() {
  const router = useRouter();
  const [username, setUsername] = useState("");
  const [empleados, setEmpleados] = useState<Empleado[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [filtro, setFiltro] = useState("");

  useEffect(() => {
    const auth = localStorage.getItem("isAuthenticated");
    const tipo = localStorage.getItem("tipo");
    if (!auth) { router.push("/"); return; }
    if (tipo !== "1") { router.push("/empleado"); return; }
    setUsername(localStorage.getItem("username") ?? "");
    cargarEmpleados();
  }, [router]);

  const cargarEmpleados = async (filtroTexto?: string) => {
    setLoading(true);
    setError("");
    const idUsuario = localStorage.getItem("idUsuario") ?? "1";
    try {
      let url: string;
      if (filtroTexto && filtroTexto.trim()) {
        url = `${API}/api/empleados/filtro?filtro=${encodeURIComponent(filtroTexto.trim())}&idUsuario=${idUsuario}`;
      } else {
        url = `${API}/api/empleados?idUsuario=${idUsuario}`;
      }
      const res = await fetch(url);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setEmpleados(await res.json());
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Error al cargar empleados");
    } finally {
      setLoading(false);
    }
  };

  const handleFiltrar = (e: React.FormEvent) => {
    e.preventDefault();
    cargarEmpleados(filtro);
  };

  const handleLimpiar = () => {
    setFiltro("");
    cargarEmpleados();
  };

  const handleLogout = async () => {
      const idUsuario = localStorage.getItem("idUsuario") ?? "1";
      await fetch(`${API}/api/eventos/logout?idUsuario=${idUsuario}`, { method: "POST" });
      localStorage.clear();
      router.push("/");
  };

  const handleImpersonar = async (emp: Empleado) => {
      const idUsuario = localStorage.getItem("idUsuario") ?? "1";
      await fetch(`${API}/api/eventos/impersonar/${emp.id}?idUsuario=${idUsuario}`, { method: "POST" });
      localStorage.setItem("impersonadoId", emp.id.toString());
      localStorage.setItem("impersonadoNombre", emp.nombre);
      router.push("/empleado");
  };

  return (
    <main style={{
      minHeight: "100vh",
      fontFamily: "Tahoma, Verdana, sans-serif",
      background: "#f7f7f7",
      padding: "32px 20px",
    }}>
      {/* Header */}
      <div style={{
        maxWidth: "800px",
        margin: "0 auto 24px",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        gap: "12px",
      }}>
        <div>
          <h1 style={{ fontSize: "24px", fontWeight: 600, margin: 0 }}>
            Empleados
          </h1>
          <p style={{ color: "#6a6a6a", fontSize: "13px", margin: "4px 0 0" }}>
            Bienvenido, {username}
          </p>
        </div>
        <div style={{ display: "flex", gap: "8px" }}>
          <button
            onClick={handleLogout}
            style={{
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
        </div>
      </div>

      {/* Barra de búsqueda */}
      <form
        onSubmit={handleFiltrar}
        style={{
          maxWidth: "800px",
          margin: "0 auto 16px",
          display: "flex",
          gap: "8px",
          alignItems: "center",
        }}
      >
        <div style={fieldStyle}>
          <label style={{ fontSize: "13px", fontWeight: 600, color: "#333", whiteSpace: "nowrap" }} htmlFor="filtro">
            Buscar:
          </label>
          <input
            style={inputStyle()}
            id="filtro"
            type="text"
            placeholder="Nombre del empleado"
            value={filtro}
            onChange={(e) => setFiltro(e.target.value)}
          />
        </div>
        <button
          type="submit"
          style={{
            padding: "8px 20px",
            borderRadius: "4px",
            border: "none",
            background: "#2a4a7f",
            color: "#fff",
            fontSize: "14px",
            fontWeight: 600,
            cursor: "pointer",
          }}
        >
          Filtrar
        </button>
        {filtro && (
          <button
            type="button"
            onClick={handleLimpiar}
            style={{
              padding: "8px 20px",
              borderRadius: "4px",
              border: "1px solid #2a4a7f",
              background: "transparent",
              color: "#2a4a7f",
              fontSize: "14px",
              fontWeight: 600,
              cursor: "pointer",
            }}
          >
            Limpiar
          </button>
        )}
      </form>

      {/* Error */}
      {error && (
        <p style={{ maxWidth: "800px", margin: "0 auto 12px", color: "#c53030", fontSize: "13px" }}>
          {error}
        </p>
      )}

      {/* Loading */}
      {loading && (
        <p style={{ maxWidth: "800px", margin: "0 auto", color: "#6a6a6a", fontSize: "14px" }}>
          Cargando...
        </p>
      )}

      {/* Tabla */}
      {!loading && (
        <div style={{
          maxWidth: "800px",
          margin: "0 auto",
          background: "#fff",
          borderRadius: "8px",
          boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
          overflow: "hidden",
        }}>
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr>
                <th style={{
                  padding: "10px 12px", textAlign: "left", fontSize: "12px",
                  fontWeight: 700, color: "#6a6a6a", borderBottom: "2px solid #eee",
                }}>Nombre</th>
                <th style={{
                  padding: "10px 12px", textAlign: "left", fontSize: "12px",
                  fontWeight: 700, color: "#6a6a6a", borderBottom: "2px solid #eee",
                }}>Puesto</th>
                <th style={{
                  padding: "10px 12px", textAlign: "left", fontSize: "12px",
                  fontWeight: 700, color: "#6a6a6a", borderBottom: "2px solid #eee",
                }}>Acción</th>
              </tr>
            </thead>
            <tbody>
              {empleados.length === 0 && (
                <tr>
                  <td colSpan={3} style={{
                    padding: "32px 12px", textAlign: "center", color: "#6a6a6a", fontSize: "14px",
                  }}>
                    No se encontraron empleados
                  </td>
                </tr>
              )}
              {empleados.map((emp) => (
                <tr
                  key={emp.id}
                  onMouseEnter={(e) => (e.currentTarget.style.background = "#f9fdf9")}
                  onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                >
                  <td style={{ padding: "10px 12px", fontSize: "13px", borderBottom: "1px solid #f0f0f0", fontWeight: 600 }}>
                    {emp.nombre}
                  </td>
                  <td style={{ padding: "10px 12px", fontSize: "13px", borderBottom: "1px solid #f0f0f0" }}>
                    {emp.puesto}
                  </td>
                  <td style={{ padding: "10px 12px", fontSize: "13px", borderBottom: "1px solid #f0f0f0" }}>
                    <button
                      onClick={() => handleImpersonar(emp)}
                      style={{
                        padding: "5px 14px",
                        borderRadius: "4px",
                        border: "none",
                        background: "#2a4a7f",
                        color: "#fff",
                        fontSize: "12px",
                        fontWeight: 600,
                        cursor: "pointer",
                      }}
                    >
                      Impersonar
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </main>
  );
}
