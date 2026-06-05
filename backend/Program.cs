using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);

// Conexión a SQL Server
builder.Services.AddScoped<SqlConnection>(_ =>
    new SqlConnection(builder.Configuration
        .GetConnectionString("DefaultConnection")));

// CORS para Next.js
builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendPolicy", policy =>
    {
        policy.WithOrigins("http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapOpenApi();

app.UseHttpsRedirection();
app.UseCors("FrontendPolicy");
app.UseAuthorization();
app.MapControllers();

app.Run();