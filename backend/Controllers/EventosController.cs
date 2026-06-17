using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace BD3.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EventosController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public EventosController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    // POST api/eventos/logout
    [HttpPost("logout")]
    public async Task<IActionResult> Logout(
        [FromQuery] int idUsuario = 1,
        [FromQuery] string ip = "127.0.0.1")
    {
        try
        {
            var cs = _configuration.GetConnectionString("DefaultConnection");
            await using var conn = new SqlConnection(cs);
            await using var cmd = new SqlCommand("dbo.SP_Logout", conn)
            {
                CommandType = CommandType.StoredProcedure
            };
            cmd.Parameters.AddWithValue("@inIdUsuario", idUsuario);
            cmd.Parameters.AddWithValue("@inIP", ip);
            var rc = new SqlParameter("@outResultCode", SqlDbType.Int)
                { Direction = ParameterDirection.Output };
            cmd.Parameters.Add(rc);

            await conn.OpenAsync();
            await cmd.ExecuteNonQueryAsync();

            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    // POST api/eventos/impersonar/{idEmpleado}
    [HttpPost("impersonar/{idEmpleado}")]
    public async Task<IActionResult> Impersonar(
        int idEmpleado,
        [FromQuery] int idUsuario = 1,
        [FromQuery] string ip = "127.0.0.1")
    {
        try
        {
            var cs = _configuration.GetConnectionString("DefaultConnection");
            await using var conn = new SqlConnection(cs);
            await using var cmd = new SqlCommand("dbo.SP_ImpersonarEmpleado", conn)
            {
                CommandType = CommandType.StoredProcedure
            };
            cmd.Parameters.AddWithValue("@inIdEmpleado", idEmpleado);
            cmd.Parameters.AddWithValue("@inIdUsuario", idUsuario);
            cmd.Parameters.AddWithValue("@inIP", ip);
            var rc = new SqlParameter("@outResultCode", SqlDbType.Int)
                { Direction = ParameterDirection.Output };
            cmd.Parameters.Add(rc);

            await conn.OpenAsync();
            await cmd.ExecuteNonQueryAsync();

            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    // POST api/eventos/regresar
    [HttpPost("regresar")]
    public async Task<IActionResult> Regresar(
        [FromQuery] int idUsuario = 1,
        [FromQuery] string ip = "127.0.0.1")
    {
        try
        {
            var cs = _configuration.GetConnectionString("DefaultConnection");
            await using var conn = new SqlConnection(cs);
            await using var cmd = new SqlCommand("dbo.SP_RegresarAdmin", conn)
            {
                CommandType = CommandType.StoredProcedure
            };
            cmd.Parameters.AddWithValue("@inIdUsuario", idUsuario);
            cmd.Parameters.AddWithValue("@inIP", ip);
            var rc = new SqlParameter("@outResultCode", SqlDbType.Int)
                { Direction = ParameterDirection.Output };
            cmd.Parameters.Add(rc);

            await conn.OpenAsync();
            await cmd.ExecuteNonQueryAsync();

            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }
}
