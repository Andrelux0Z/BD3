
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using BD3.Api.Models;

namespace BD3.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PlanillaController : ControllerBase
    {
        private readonly SqlConnection _connection;

        public PlanillaController(SqlConnection connection)
        {
            _connection = connection;
        }

        // --------------------------------------------------------
        // Grid de últimas X planillas semanales del empleado
        // --------------------------------------------------------
        [HttpGet("semanal/{idEmpleado}")]
        public async Task<IActionResult> GetPlanillaSemanal(
            int idEmpleado,
            [FromQuery] int cantidad   = 10,
            [FromQuery] int idUsuario  = 1,
            [FromQuery] string ip      = "127.0.0.1")
        {
            var resultado = new List<PlanillaSemanalResponse>();

            try
            {
                await _connection.OpenAsync();

                using var command = new SqlCommand("dbo.SP_ConsultarPlanillaSemanal", _connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@inIdEmpleado",  idEmpleado);
                command.Parameters.AddWithValue("@inCantidad",    cantidad);
                command.Parameters.AddWithValue("@inIdUsuario",   idUsuario);
                command.Parameters.AddWithValue("@inIP",          ip);

                var outResultCode = command.Parameters.Add("@outResultCode", System.Data.SqlDbType.Int);
                outResultCode.Direction = System.Data.ParameterDirection.Output;

                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    resultado.Add(new PlanillaSemanalResponse
                    {
                        IdPlanillaSemanal = reader.GetInt32(reader.GetOrdinal("IdPlanillaSemanal")),
                        FechaInicio = reader.GetDateTime(reader.GetOrdinal("FechaInicio")),
                        FechaFin = reader.GetDateTime(reader.GetOrdinal("FechaFin")),
                        SalarioBruto = reader.GetDecimal(reader.GetOrdinal("SalarioBruto")),
                        TotalDeducciones = reader.GetDecimal(reader.GetOrdinal("TotalDeducciones")),
                        SalarioNeto = reader.GetDecimal(reader.GetOrdinal("SalarioNeto")),
                        HorasOrdinarias = reader.GetDecimal(reader.GetOrdinal("HorasOrdinarias")),
                        HorasExtraNormales = reader.GetDecimal(reader.GetOrdinal("HorasExtraNormales")),
                        HorasExtraDobles = reader.GetDecimal(reader.GetOrdinal("HorasExtraDobles")),
                        Procesada = reader.GetBoolean(reader.GetOrdinal("Procesada"))
                    });
                }

                return Ok(resultado);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
            finally
            {
                await _connection.CloseAsync();
            }
        }

        // --------------------------------------------------------
        // Click en salario bruto: movimientos por día
        // --------------------------------------------------------
        [HttpGet("semanal/detalle/{idPlanillaSemanal}")]
        public async Task<IActionResult> GetDetalleSemanal(
            int idPlanillaSemanal,
            [FromQuery] int idUsuario  = 1,
            [FromQuery] string ip      = "127.0.0.1")
        {
            var resultado = new List<DetalleSemanalResponse>();

            try
            {
                await _connection.OpenAsync();

                using var command = new SqlCommand("dbo.SP_ConsultarDetalleSemanal", _connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@inIdPlanillaSemanal", idPlanillaSemanal);
                command.Parameters.AddWithValue("@inIdUsuario",         idUsuario);
                command.Parameters.AddWithValue("@inIP",                ip);

                var outResultCode = command.Parameters.Add("@outResultCode", System.Data.SqlDbType.Int);
                outResultCode.Direction = System.Data.ParameterDirection.Output;

                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    resultado.Add(new DetalleSemanalResponse
                    {
                        Fecha = reader.GetDateTime(reader.GetOrdinal("Fecha")),
                        TipoMovimiento  = reader.GetString(reader.GetOrdinal("TipoMovimiento")),
                        QHoras = reader.GetDecimal(reader.GetOrdinal("QHoras")),
                        Monto = reader.GetDecimal(reader.GetOrdinal("Monto"))
                    }); 
                }

                return Ok(resultado);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
            finally
            {
                await _connection.CloseAsync();
            }
        }

        // --------------------------------------------------------
        // Click en total de deducciones: detalle por tipo
        // --------------------------------------------------------
        [HttpGet("semanal/deducciones/{idPlanillaSemanal}")]
        public async Task<IActionResult> GetDeduccionesSemanal(
            int idPlanillaSemanal,
            [FromQuery] int idUsuario  = 1,
            [FromQuery] string ip      = "127.0.0.1")
        {
            var resultado = new List<DeduccionDetalleResponse>();

            try
            {
                await _connection.OpenAsync();

                using var command = new SqlCommand("dbo.SP_ConsultarDeduccionesSemanal", _connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@inIdPlanillaSemanal", idPlanillaSemanal);
                command.Parameters.AddWithValue("@inIdUsuario",         idUsuario);
                command.Parameters.AddWithValue("@inIP",                ip);

                var outResultCode = command.Parameters.Add("@outResultCode", System.Data.SqlDbType.Int);
                outResultCode.Direction = System.Data.ParameterDirection.Output;

                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    resultado.Add(new DeduccionDetalleResponse
                    {
                        NombreDeduccion = reader.GetString(reader.GetOrdinal("NombreDeduccion")),
                        Porcentaje = reader.IsDBNull(reader.GetOrdinal("Porcentaje"))
                                            ? null
                                            : reader.GetDecimal(reader.GetOrdinal("Porcentaje")),
                        Monto = reader.GetDecimal(reader.GetOrdinal("Monto"))
                    });
                }

                return Ok(resultado);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
            finally
            {
                await _connection.CloseAsync();
            }
        }

        // --------------------------------------------------------
        // Grid de últimos X meses del empleado
        // --------------------------------------------------------
        [HttpGet("mensual/{idEmpleado}")]
        public async Task<IActionResult> GetPlanillaMensual(
            int idEmpleado,
            [FromQuery] int cantidad = 6,
            [FromQuery] int idUsuario = 1,
            [FromQuery] string ip = "127.0.0.1")
        {
            var resultado = new List<PlanillaMensualResponse>();

            try
            {
                await _connection.OpenAsync();

                using var command = new SqlCommand("dbo.SP_ConsultarPlanillaMensual", _connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@inIdEmpleado",  idEmpleado);
                command.Parameters.AddWithValue("@inCantidad",    cantidad);
                command.Parameters.AddWithValue("@inIdUsuario",   idUsuario);
                command.Parameters.AddWithValue("@inIP",          ip);

                var outResultCode = command.Parameters.Add("@outResultCode", System.Data.SqlDbType.Int);
                outResultCode.Direction = System.Data.ParameterDirection.Output;

                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    resultado.Add(new PlanillaMensualResponse
                    {
                        IdPlanillaMensual = reader.GetInt32(reader.GetOrdinal("IdPlanillaMensual")),
                        FechaInicio = reader.GetDateTime(reader.GetOrdinal("FechaInicio")),
                        FechaFin = reader.GetDateTime(reader.GetOrdinal("FechaFin")),
                        CantidadSemanas = reader.GetByte(reader.GetOrdinal("CantidadSemanas")),
                        SalarioBruto = reader.GetDecimal(reader.GetOrdinal("SalarioBruto")),
                        TotalDeducciones = reader.GetDecimal(reader.GetOrdinal("TotalDeducciones")),
                        SalarioNeto = reader.GetDecimal(reader.GetOrdinal("SalarioNeto"))
                    });
                }

                return Ok(resultado);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
            finally
            {
                await _connection.CloseAsync();
            }
        }

        // --------------------------------------------------------
        // Click en total de deducciones del mes
        // --------------------------------------------------------
        [HttpGet("mensual/deducciones/{idPlanillaMensual}")]
        public async Task<IActionResult> GetDeduccionesMensual(
            int idPlanillaMensual,
            [FromQuery] int idUsuario  = 1,
            [FromQuery] string ip = "127.0.0.1")
        {
            var resultado = new List<DeduccionDetalleResponse>();

            try
            {
                await _connection.OpenAsync();

                using var command = new SqlCommand("dbo.SP_ConsultarDeduccionesMensual", _connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@inIdPlanillaMensual", idPlanillaMensual);
                command.Parameters.AddWithValue("@inIdUsuario",         idUsuario);
                command.Parameters.AddWithValue("@inIP",                ip);

                var outResultCode = command.Parameters.Add("@outResultCode", System.Data.SqlDbType.Int);
                outResultCode.Direction = System.Data.ParameterDirection.Output;

                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    resultado.Add(new DeduccionDetalleResponse
                    {
                        NombreDeduccion = reader.GetString(reader.GetOrdinal("NombreDeduccion")),
                        Porcentaje = null, // mensual no tiene porcentaje, es suma de semanas
                        Monto = reader.GetDecimal(reader.GetOrdinal("Monto"))
                    });
                }

                return Ok(resultado);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
            finally
            {
                await _connection.CloseAsync();
            }
        }
    }
}
