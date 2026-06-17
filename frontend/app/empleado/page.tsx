"use client";
import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";

const API = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:5246";

/* ── Types ────────────────────────────────────────── */
interface PlanillaSemanal {
  idPlanillaSemanal: number;
  fechaInicio: string;
  fechaFin: string;
  salarioBruto: number;
  totalDeducciones: number;
  salarioNeto: number;
  horasOrdinarias: number;
  horasExtraNormales: number;
  horasExtraDobles: number;
  procesada: boolean;
}

interface DetalleSemanal {
  fecha: string;
  horaEntrada: string;
  horaSalida: string;
  tipoMovimiento: string;
  qHoras: number;
  monto: number;
}

interface DeduccionDetalle {
  nombreDeduccion: string;
  porcentaje: number | null;
  monto: number;
}

interface PlanillaMensual {
  idPlanillaMensual: number;
  fechaInicio: string;
  fechaFin: string;
  cantidadSemanas: number;
  salarioBruto: number;
  totalDeducciones: number;
  salarioNeto: number;
}

type DetalleView =
  | { tipo: "dias"; data: DetalleSemanal[]; titulo: string }
  | { tipo: "deducciones"; data: DeduccionDetalle[]; titulo: string }
  | null;

/* ── Helpers ──────────────────────────────────────── */
const fmt = (n: number) =>
  n.toLocaleString("es-CR", { style: "currency", currency: "CRC", minimumFractionDigits: 2 });
const fmtDate = (iso: string) =>
  new Date(iso).toLocaleDateString("es-CR", { day: "2-digit", month: "short", year: "numeric" });
const fmtNum = (n: number) => n.toFixed(2);
const fmtTime = (iso: string) => {
  if (!iso) return "—";
  const d = new Date(iso);
  return d.toLocaleTimeString("es-CR", { hour: "2-digit", minute: "2-digit", hour12: false });
};

const CANTIDAD_MIN = 1;

/* ── Shared inline styles ─────────────────────────── */
const thStyle: React.CSSProperties = {
  padding: "10px 12px",
  textAlign: "left",
  fontSize: "12px",
  fontWeight: 700,
  color: "#6a6a6a",
  borderBottom: "2px solid #eee",
  whiteSpace: "nowrap",
};

const tdStyle: React.CSSProperties = {
  padding: "10px 12px",
  fontSize: "13px",
  borderBottom: "1px solid #f0f0f0",
};

const linkStyle: React.CSSProperties = {
  color: "#1aa04a",
  fontWeight: 600,
  cursor: "pointer",
  textDecoration: "underline",
};

const tableCardStyle: React.CSSProperties = {
  maxWidth: "960px",
  margin: "0 auto 20px",
  background: "#fff",
  borderRadius: "8px",
  boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
  overflow: "hidden",
};

const detailCardStyle: React.CSSProperties = {
  maxWidth: "960px",
  margin: "0 auto 20px",
  background: "#fff",
  borderRadius: "8px",
  boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
  padding: "20px 24px",
};

const tabBtnBase: React.CSSProperties = {
  padding: "8px 24px",
  borderRadius: "4px",
  fontSize: "14px",
  fontWeight: 600,
  cursor: "pointer",
  border: "none",
};

/* ── Component ────────────────────────────────────── */
export default function EmpleadoPage() {
  const router = useRouter();
  const [isAdmin, setIsAdmin] = useState(false);
  const [idEmpleado, setIdEmpleado] = useState<number | null>(null);
  const [impersonadoNombre, setImpersonadoNombre] = useState<string | null>(null);
  const [username, setUsername] = useState("");
  const [tab, setTab] = useState<"semanal" | "mensual">("semanal");
  const [cantidadSem, setCantidadSem] = useState(10);
  const [cantidadMes, setCantidadMes] = useState(10);
  const [idUsuario, setIdUsuario] = useState<number>(1);


  /* Semanal */
  const [semanales, setSemanales] = useState<PlanillaSemanal[]>([]);
  const [loadingSem, setLoadingSem] = useState(false);
  const [errorSem, setErrorSem] = useState("");

  /* Mensual */
  const [mensuales, setMensuales] = useState<PlanillaMensual[]>([]);
  const [loadingMes, setLoadingMes] = useState(false);
  const [errorMes, setErrorMes] = useState("");

  /* Detalle inline */
  const [detalle, setDetalle] = useState<DetalleView>(null);
  const [loadingDetalle, setLoadingDetalle] = useState(false);

  /* Auth */
  useEffect(() => {
    const auth = localStorage.getItem("isAuthenticated");
    if (!auth) { router.push("/"); return; }
    const tipo = localStorage.getItem("tipo");
    setIsAdmin(tipo === "1");
    setUsername(localStorage.getItem("nombreEmpleado") || localStorage.getItem("username") || "");
    const uid = localStorage.getItem("idUsuario");
    if (uid) setIdUsuario(Number(uid));


    // If admin is impersonating, use that employee's ID
    const impId = localStorage.getItem("impersonadoId");
    const impNombre = localStorage.getItem("impersonadoNombre");
    if (impId) {
      setIdEmpleado(Number(impId));
      setImpersonadoNombre(impNombre);
    } else {
      const id = localStorage.getItem("idEmpleado");
      if (id) setIdEmpleado(Number(id));
    }
  }, [router]);

  /* Fetch semanal */
  const fetchSemanal = useCallback(async (idEmp: number, cant: number) => {
    setLoadingSem(true);
    setErrorSem("");
    try {
      const res = await fetch(`${API}/api/planilla/semanal/${idEmp}?cantidad=${cant}&idUsuario=${idUsuario}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setSemanales(await res.json());
    } catch (e: unknown) {
      setErrorSem(e instanceof Error ? e.message : "Error al cargar planilla semanal");
    } finally { setLoadingSem(false); }
  }, [idUsuario]);

  /* Fetch mensual */
  const fetchMensual = useCallback(async (idEmp: number, cant: number) => {
    setLoadingMes(true);
    setErrorMes("");
    try {
      const res = await fetch(`${API}/api/planilla/mensual/${idEmp}?cantidad=${cant}&idUsuario=${idUsuario}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setMensuales(await res.json());
    } catch (e: unknown) {
      setErrorMes(e instanceof Error ? e.message : "Error al cargar planilla mensual");
    } finally { setLoadingMes(false); }
  }, [idUsuario]);

  useEffect(() => {
    if (!idEmpleado) return;
    fetchSemanal(idEmpleado, cantidadSem);
  }, [idEmpleado, cantidadSem, fetchSemanal]);

  useEffect(() => {
    if (!idEmpleado || tab !== "mensual") return;
    fetchMensual(idEmpleado, cantidadMes);
  }, [idEmpleado, tab, cantidadMes, fetchMensual]);

  /* Detalle días */
  const verDias = async (sem: PlanillaSemanal) => {
    setLoadingDetalle(true);
    setDetalle(null);
    try {
      const res = await fetch(`${API}/api/planilla/semanal/detalle/${sem.idPlanillaSemanal}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data: DetalleSemanal[] = await res.json();
      setDetalle({
        tipo: "dias",
        data,
        titulo: `Detalle de días — ${fmtDate(sem.fechaInicio)} a ${fmtDate(sem.fechaFin)}`,
      });
    } catch { setDetalle(null); }
    finally { setLoadingDetalle(false); }
  };

  /* Detalle deducciones sem */
  const verDeduccionesSem = async (sem: PlanillaSemanal) => {
    setLoadingDetalle(true);
    setDetalle(null);
    try {
      const res = await fetch(`${API}/api/planilla/semanal/deducciones/${sem.idPlanillaSemanal}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data: DeduccionDetalle[] = await res.json();
      setDetalle({
        tipo: "deducciones",
        data,
        titulo: `Deducciones — ${fmtDate(sem.fechaInicio)} a ${fmtDate(sem.fechaFin)}`,
      });
    } catch { setDetalle(null); }
    finally { setLoadingDetalle(false); }
  };

  /* Detalle deducciones mes */
  const verDeduccionesMes = async (mes: PlanillaMensual) => {
    setLoadingDetalle(true);
    setDetalle(null);
    try {
      const res = await fetch(`${API}/api/planilla/mensual/deducciones/${mes.idPlanillaMensual}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data: DeduccionDetalle[] = await res.json();
      setDetalle({
        tipo: "deducciones",
        data,
        titulo: `Deducciones — ${fmtDate(mes.fechaInicio)} a ${fmtDate(mes.fechaFin)}`,
      });
    } catch { setDetalle(null); }
    finally { setLoadingDetalle(false); }
  };

  const handleLogout = async () => {
      await fetch(`${API}/api/eventos/logout?idUsuario=${idUsuario}`, { method: "POST" });
      localStorage.clear();
      router.push("/");
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
        maxWidth: "960px",
        margin: "0 auto 24px",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        gap: "12px",
      }}>
        <div>
          <h1 style={{ fontSize: "24px", fontWeight: 600, margin: 0 }}>Planilla</h1>
          {impersonadoNombre ? (
            <p style={{ color: "#6a6a6a", fontSize: "13px", margin: "4px 0 0" }}>
              Viendo como: <strong>{impersonadoNombre}</strong>
            </p>
          ) : username ? (
            <p style={{ color: "#6a6a6a", fontSize: "13px", margin: "4px 0 0" }}>
              Sesión de: <strong>{username}</strong>
            </p>
          ) : null}
        </div>
        <div style={{ display: "flex", gap: "8px" }}>
          {isAdmin && (
            <button
              id="btn-volver-admin"
              onClick={async () => {
                  await fetch(`${API}/api/eventos/regresar?idUsuario=${idUsuario}`, { method: "POST" });
                  localStorage.removeItem("impersonadoId");
                  localStorage.removeItem("impersonadoNombre");
                  router.push("/admin");
              }}
              style={{
                padding: "8px 24px",
                borderRadius: "4px",
                border: "1px solid #1aa04a",
                background: "transparent",
                color: "#1aa04a",
                fontSize: "14px",
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              ← Volver a administrador
            </button>
          )}
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

      {/* Tabs */}
      <div style={{ maxWidth: "960px", margin: "0 auto 16px", display: "flex", gap: "8px" }}>
        <button
          id="tab-semanal"
          style={{
            ...tabBtnBase,
            background: tab === "semanal" ? "#1aa04a" : "transparent",
            color: tab === "semanal" ? "#fff" : "#1aa04a",
            border: tab === "semanal" ? "none" : "1px solid #1aa04a",
          }}
          onClick={() => {
              setTab("semanal");
              setDetalle(null);
              if (idEmpleado) fetchSemanal(idEmpleado, cantidadSem);
          }}
        >
          Semanal
        </button>
        <button
          id="tab-mensual"
          style={{
            ...tabBtnBase,
            background: tab === "mensual" ? "#1aa04a" : "transparent",
            color: tab === "mensual" ? "#fff" : "#1aa04a",
            border: tab === "mensual" ? "none" : "1px solid #1aa04a",
          }}
          onClick={() => { setTab("mensual"); setDetalle(null); }}
        >
          Mensual
        </button>
      </div>

      {/* Cantidad selector */}
      <div style={{ maxWidth: "960px", margin: "0 auto 12px", display: "flex", alignItems: "center", gap: "8px" }}>
        <label style={{ fontSize: "13px", fontWeight: 600, color: "#333" }} htmlFor="cantidad">
          Mostrar:
        </label>
        <input
          id="cantidad"
          type="number"
          min={CANTIDAD_MIN}
          value={tab === "semanal" ? cantidadSem : cantidadMes}
          onChange={(e) => {
            const val = Math.max(CANTIDAD_MIN, Number(e.target.value) || CANTIDAD_MIN);
            if (tab === "semanal") setCantidadSem(val);
            else setCantidadMes(val);
          }}
          style={{
            padding: "6px 10px",
            borderRadius: "4px",
            border: "1px solid #ccc",
            fontSize: "14px",
            outline: "none",
            width: "80px",
          }}
        />
        <span style={{ fontSize: "13px", color: "#6a6a6a" }}>entradas</span>
      </div>

      {/* Error */}
      {(tab === "semanal" && errorSem) && (
        <p style={{ maxWidth: "960px", margin: "0 auto 12px", color: "#c53030", fontSize: "13px" }}>{errorSem}</p>
      )}
      {(tab === "mensual" && errorMes) && (
        <p style={{ maxWidth: "960px", margin: "0 auto 12px", color: "#c53030", fontSize: "13px" }}>{errorMes}</p>
      )}

      {/* Loading */}
      {((tab === "semanal" && loadingSem) || (tab === "mensual" && loadingMes)) && (
        <p style={{ maxWidth: "960px", margin: "0 auto", color: "#6a6a6a", fontSize: "14px" }}>Cargando...</p>
      )}

      {/* ── Tabla semanal ─────────────────────────── */}
      {tab === "semanal" && !loadingSem && (
        <div style={tableCardStyle} id="tabla-semanal">
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr>
                <th style={thStyle}>Período</th>
                <th style={{ ...thStyle, textAlign: "right" }}>Salario Bruto</th>
                <th style={{ ...thStyle, textAlign: "right" }}>Deducciones</th>
                <th style={{ ...thStyle, textAlign: "right" }}>Neto</th>
                <th style={{ ...thStyle, textAlign: "right" }}>H.Ord</th>
                <th style={{ ...thStyle, textAlign: "right" }}>H.Extra</th>
                <th style={{ ...thStyle, textAlign: "right" }}>H.Doble</th>
                <th style={thStyle}>Estado</th>
              </tr>
            </thead>
            <tbody>
              {semanales.length === 0 && (
                <tr><td colSpan={8} style={{ ...tdStyle, textAlign: "center", color: "#6a6a6a" }}>Sin datos disponibles</td></tr>
              )}
              {semanales.map((sem) => (
                <tr key={sem.idPlanillaSemanal}
                    onMouseEnter={(e) => (e.currentTarget.style.background = "#f9fdf9")}
                    onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                >
                  <td style={tdStyle}>{fmtDate(sem.fechaInicio)} – {fmtDate(sem.fechaFin)}</td>
                  <td style={{ ...tdStyle, textAlign: "right" }}>
                    <span style={linkStyle} onClick={() => verDias(sem)}>{fmt(sem.salarioBruto)}</span>
                  </td>
                  <td style={{ ...tdStyle, textAlign: "right" }}>
                    <span style={linkStyle} onClick={() => verDeduccionesSem(sem)}>{fmt(sem.totalDeducciones)}</span>
                  </td>
                  <td style={{ ...tdStyle, textAlign: "right", fontWeight: 700 }}>{fmt(sem.salarioNeto)}</td>
                  <td style={{ ...tdStyle, textAlign: "right" }}>{fmtNum(sem.horasOrdinarias)}</td>
                  <td style={{ ...tdStyle, textAlign: "right" }}>{fmtNum(sem.horasExtraNormales)}</td>
                  <td style={{ ...tdStyle, textAlign: "right" }}>{fmtNum(sem.horasExtraDobles)}</td>
                  <td style={tdStyle}>
                    <span style={{ fontSize: "12px", fontWeight: 600, color: sem.procesada ? "#276749" : "#6a6a6a" }}>
                      {sem.procesada ? "✓ Procesada" : "Pendiente"}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* ── Tabla mensual ─────────────────────────── */}
      {tab === "mensual" && !loadingMes && (
        <div style={tableCardStyle} id="tabla-mensual">
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr>
                <th style={thStyle}>Período</th>
                <th style={{ ...thStyle, textAlign: "right" }}>Semanas</th>
                <th style={{ ...thStyle, textAlign: "right" }}>Salario Bruto</th>
                <th style={{ ...thStyle, textAlign: "right" }}>Deducciones</th>
                <th style={{ ...thStyle, textAlign: "right" }}>Neto</th>
              </tr>
            </thead>
            <tbody>
              {mensuales.length === 0 && (
                <tr><td colSpan={5} style={{ ...tdStyle, textAlign: "center", color: "#6a6a6a" }}>Sin datos disponibles</td></tr>
              )}
              {mensuales.map((mes) => (
                <tr key={mes.idPlanillaMensual}
                    onMouseEnter={(e) => (e.currentTarget.style.background = "#f9fdf9")}
                    onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                >
                  <td style={tdStyle}>{fmtDate(mes.fechaInicio)} – {fmtDate(mes.fechaFin)}</td>
                  <td style={{ ...tdStyle, textAlign: "right" }}>{mes.cantidadSemanas}</td>
                  <td style={{ ...tdStyle, textAlign: "right" }}>{fmt(mes.salarioBruto)}</td>
                  <td style={{ ...tdStyle, textAlign: "right" }}>
                    <span style={linkStyle} onClick={() => verDeduccionesMes(mes)}>{fmt(mes.totalDeducciones)}</span>
                  </td>
                  <td style={{ ...tdStyle, textAlign: "right", fontWeight: 700 }}>{fmt(mes.salarioNeto)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* ── Detalle inline ────────────────────────── */}
      {loadingDetalle && (
        <p style={{ maxWidth: "960px", margin: "0 auto", color: "#6a6a6a", fontSize: "14px" }}>Cargando detalle...</p>
      )}

      {detalle && !loadingDetalle && (
        <div style={detailCardStyle}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
            <h2 style={{ fontSize: "16px", fontWeight: 600, margin: 0 }}>{detalle.titulo}</h2>
            <button
              onClick={() => setDetalle(null)}
              style={{
                padding: "6px 16px",
                borderRadius: "4px",
                border: "1px solid #ccc",
                background: "transparent",
                color: "#333",
                fontSize: "13px",
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              Cerrar
            </button>
          </div>

          {detalle.tipo === "dias" && (
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  <th style={thStyle}>Fecha</th>
                  <th style={thStyle}>Hora Entrada</th>
                  <th style={thStyle}>Hora Salida</th>
                  <th style={thStyle}>Tipo de movimiento</th>
                  <th style={{ ...thStyle, textAlign: "right" }}>Horas</th>
                  <th style={{ ...thStyle, textAlign: "right" }}>Monto</th>
                </tr>
              </thead>
              <tbody>
                {detalle.data.length === 0 && (
                  <tr><td colSpan={6} style={{ ...tdStyle, textAlign: "center", color: "#6a6a6a" }}>Sin movimientos</td></tr>
                )}
                {detalle.data.map((d, i) => (
                  <tr key={i}>
                    <td style={tdStyle}>{fmtDate(d.fecha)}</td>
                    <td style={tdStyle}>{fmtTime(d.horaEntrada)}</td>
                    <td style={tdStyle}>{fmtTime(d.horaSalida)}</td>
                    <td style={tdStyle}>{d.tipoMovimiento}</td>
                    <td style={{ ...tdStyle, textAlign: "right" }}>{fmtNum(d.qHoras)}</td>
                    <td style={{ ...tdStyle, textAlign: "right" }}>{fmt(d.monto)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          {detalle.tipo === "deducciones" && (
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr>
                  <th style={thStyle}>Deducción</th>
                  <th style={{ ...thStyle, textAlign: "right" }}>Porcentaje</th>
                  <th style={{ ...thStyle, textAlign: "right" }}>Monto</th>
                </tr>
              </thead>
              <tbody>
                {detalle.data.length === 0 && (
                  <tr><td colSpan={3} style={{ ...tdStyle, textAlign: "center", color: "#6a6a6a" }}>Sin deducciones</td></tr>
                )}
                {detalle.data.map((d, i) => (
                  <tr key={i}>
                    <td style={tdStyle}>{d.nombreDeduccion}</td>
                    <td style={{ ...tdStyle, textAlign: "right" }}>
                      {d.porcentaje != null ? `${(d.porcentaje * 100).toFixed(2)}%` : "—"}
                    </td>
                    <td style={{ ...tdStyle, textAlign: "right" }}>{fmt(d.monto)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </main>
  );
}
