

namespace BD3.Api.Models
{
    // Grid de planillas semanales
    public class PlanillaSemanalResponse
    {
        public int      IdPlanillaSemanal   { get; set; }
        public DateTime FechaInicio         { get; set; }
        public DateTime FechaFin            { get; set; }
        public decimal  SalarioBruto        { get; set; }
        public decimal  TotalDeducciones    { get; set; }
        public decimal  SalarioNeto         { get; set; }
        public decimal  HorasOrdinarias     { get; set; }
        public decimal  HorasExtraNormales  { get; set; }
        public decimal  HorasExtraDobles    { get; set; }
        public bool     Procesada           { get; set; }
    }

    // Click en salario bruto: movimientos por día
    public class DetalleSemanalResponse
    {
        public DateTime Fecha           { get; set; }
        public string   TipoMovimiento  { get; set; } = string.Empty;
        public decimal  QHoras          { get; set; }
        public decimal  Monto           { get; set; }
    }

    // Click en deducciones: detalle por tipo
    public class DeduccionDetalleResponse
    {
        public string   NombreDeduccion { get; set; } = string.Empty;
        public decimal? Porcentaje      { get; set; }
        public decimal  Monto           { get; set; }
    }

    // Grid de planillas mensuales
    public class PlanillaMensualResponse
    {
        public int      IdPlanillaMensual   { get; set; }
        public DateTime FechaInicio         { get; set; }
        public DateTime FechaFin            { get; set; }
        public int      CantidadSemanas     { get; set; }
        public decimal  SalarioBruto        { get; set; }
        public decimal  TotalDeducciones    { get; set; }
        public decimal  SalarioNeto         { get; set; }
    }
}
