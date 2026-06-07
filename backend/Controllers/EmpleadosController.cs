using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace BD3.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EmpleadosController : ControllerBase
{
    private readonly SqlConnection _connection;

    public EmpleadosController(SqlConnection connection)
    {
        _connection = connection;
    }

    // GET /api/empleados?idUsuario=1&ip=127.0.0.1
    [HttpGet]
    public async Task<IActionResult> Listar(
        [FromQuery] int idUsuario = 1,
        [FromQuery] string ip = "127.0.0.1")
    {
        try
        {
            await _connection.OpenAsync();

            using var command = new SqlCommand("dbo.SP_ListarEmpleados", _connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@inIdUsuario", idUsuario);
            command.Parameters.AddWithValue("@inIP", ip);

            var outResultCode = command.Parameters.Add("@outResultCode", SqlDbType.Int);
            outResultCode.Direction = ParameterDirection.Output;

            using var reader = await command.ExecuteReaderAsync();
            var lista = new List<object>();

            while (await reader.ReadAsync())
            {
                lista.Add(new
                {
                    id = reader.GetInt32(reader.GetOrdinal("id")),
                    nombre = reader.GetString(reader.GetOrdinal("Nombre")),
                    documentoIdentidad = reader.GetString(reader.GetOrdinal("documentoIdentidad")),
                    puesto = reader.GetString(reader.GetOrdinal("NombrePuesto")),
                    departamento = reader.GetString(reader.GetOrdinal("NombreDepartamento")),
                });
            }

            return Ok(lista);
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

    // GET /api/empleados/filtro?filtro=texto&idUsuario=1&ip=127.0.0.1
    [HttpGet("filtro")]
    public async Task<IActionResult> ListarConFiltro(
        [FromQuery] string filtro = "",
        [FromQuery] int idUsuario = 1,
        [FromQuery] string ip = "127.0.0.1")
    {
        try
        {
            await _connection.OpenAsync();

            using var command = new SqlCommand("dbo.SP_ListarEmpleadosConFiltro", _connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@inFiltro", filtro);
            command.Parameters.AddWithValue("@inIdUsuario", idUsuario);
            command.Parameters.AddWithValue("@inIP", ip);

            var outResultCode = command.Parameters.Add("@outResultCode", SqlDbType.Int);
            outResultCode.Direction = ParameterDirection.Output;

            using var reader = await command.ExecuteReaderAsync();
            var lista = new List<object>();

            while (await reader.ReadAsync())
            {
                lista.Add(new
                {
                    id = reader.GetInt32(reader.GetOrdinal("id")),
                    nombre = reader.GetString(reader.GetOrdinal("Nombre")),
                    documentoIdentidad = reader.GetString(reader.GetOrdinal("documentoIdentidad")),
                    puesto = reader.GetString(reader.GetOrdinal("NombrePuesto")),
                    departamento = reader.GetString(reader.GetOrdinal("NombreDepartamento")),
                });
            }

            return Ok(lista);
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
