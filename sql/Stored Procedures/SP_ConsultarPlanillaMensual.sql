CREATE PROCEDURE dbo.SP_ConsultarPlanillaMensual
     @inIdEmpleado   INT
    ,@inCantidad     INT = 6
    ,@inIdUsuario    INT
    ,@inIP           VARCHAR(45)
    ,@outResultCode  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @outResultCode = 0;

    DECLARE
         @fechaInicio    DATE
        ,@fechaFin       DATE;

    BEGIN TRY

        SELECT TOP (@inCantidad)
             PM.id                   AS IdPlanillaMensual
            ,M.FechaInicio
            ,M.FechaFin
            ,M.CantidadSemanas
            ,PM.SalarioBruto
            ,PM.TotalDeducciones
            ,PM.SalarioNeto
        FROM dbo.PlanillaMensual PM
        INNER JOIN dbo.Mes M ON (PM.IdMes = M.id)
        WHERE (PM.IdEmpleado = @inIdEmpleado)
        ORDER BY M.FechaInicio DESC;

        -- Para bitácora
        SELECT
             @fechaInicio = MIN(M.FechaInicio)
            ,@fechaFin    = MAX(M.FechaFin)
        FROM dbo.PlanillaMensual PM
        INNER JOIN dbo.Mes M ON (PM.IdMes = M.id)
        WHERE (PM.IdEmpleado = @inIdEmpleado);

        INSERT INTO dbo.BitacoraEvento
            ( IdUsuario, IdTipoEvento, Descripcion, IpPostIn )
        VALUES
            ( @inIdUsuario
            , 11
            , CONCAT('{"IdEmpleado":', @inIdEmpleado,
                     ',"FechaInicio":"', @fechaInicio,
                     '","FechaFin":"', @fechaFin, '"}')
            , @inIP );

    END TRY
    BEGIN CATCH

        SET @outResultCode = 50008;

        INSERT INTO dbo.DBErrors
            ( UserName, Number, State, Severity, Line, [Procedure], Message )
        VALUES
            ( SYSTEM_USER
            , ERROR_NUMBER()
            , ERROR_STATE()
            , ERROR_SEVERITY()
            , ERROR_LINE()
            , ERROR_PROCEDURE()
            , ERROR_MESSAGE() );

    END CATCH;

END;
