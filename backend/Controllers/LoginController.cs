using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace BD3.Api.Controllers;

public sealed record LoginRequest(string Usuario, string Password);

[ApiController]
[Route("api/[controller]")]
public class LoginController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public LoginController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpPost]
    public async Task<IActionResult> Post([FromBody] LoginRequest request)
    {
        if (request is null || string.IsNullOrWhiteSpace(request.Usuario) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new { success = false, message = "Usuario y contrasena son requeridos." });
        }

        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return StatusCode(500, new { success = false, message = "Falta configurar la conexion a la base de datos." });
        }

        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "0.0.0.0";

        try
        {
            await using var connection = new SqlConnection(connectionString);
            await using var command = new SqlCommand("dbo.SP_Login", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@inUsuario", SqlDbType.VarChar, 50) { Value = request.Usuario });
            command.Parameters.Add(new SqlParameter("@inPassword", SqlDbType.VarChar, 60) { Value = request.Password });
            command.Parameters.Add(new SqlParameter("@inIpPostIn", SqlDbType.VarChar, 45) { Value = ipAddress });

            var outResultCode = new SqlParameter("@outResultCode", SqlDbType.Int) { Direction = ParameterDirection.Output };
            var outIdUsuario = new SqlParameter("@outIdUsuario", SqlDbType.Int) { Direction = ParameterDirection.Output };
            command.Parameters.Add(outResultCode);
            command.Parameters.Add(outIdUsuario);

            await connection.OpenAsync();

            LoginUser? user = null;
            await using (var reader = await command.ExecuteReaderAsync())
            {
                if (await reader.ReadAsync())
                {
                    user = new LoginUser
                    {
                        IdUsuario = reader.GetInt32(reader.GetOrdinal("IdUsuario")),
                        Username = reader.GetString(reader.GetOrdinal("Username")),
                        Tipo = reader.GetByte(reader.GetOrdinal("Tipo")).ToString(),
                        IdEmpleado = reader.IsDBNull(reader.GetOrdinal("IdEmpleado"))
                            ? null
                            : reader.GetInt32(reader.GetOrdinal("IdEmpleado")),
                        NombreEmpleado = reader.IsDBNull(reader.GetOrdinal("NombreEmpleado"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("NombreEmpleado"))
                    };
                }
            }

            var resultCode = outResultCode.Value is int rc ? rc : 0;
            if (resultCode != 0)
            {
                return Unauthorized(new { success = false, code = resultCode, message = MapLoginError(resultCode) });
            }

            if (user is null)
            {
                return Unauthorized(new { success = false, message = "Credenciales invalidas." });
            }

            return Ok(new
            {
                success = true,
                idUsuario = user.IdUsuario,
                username = user.Username,
                tipo = user.Tipo,
                idEmpleado = user.IdEmpleado,
                nombreEmpleado = user.NombreEmpleado
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, message = "Error al procesar el login.", detail = ex.Message });
        }
    }

    private static string MapLoginError(int code)
    {
        return code switch
        {
            50001 => "Usuario no existe.",
            50002 => "Contrasena incorrecta.",
            50003 => "Cuenta bloqueada por intentos fallidos.",
            50008 => "Error interno en el login.",
            _ => "No se pudo iniciar sesion."
        };
    }

    private sealed class LoginUser
    {
        public int IdUsuario { get; init; }
        public string Username { get; init; } = string.Empty;
        public string Tipo { get; init; } = string.Empty;
        public int? IdEmpleado { get; init; }
        public string? NombreEmpleado { get; init; }
    }
}
