CREATE PROCEDURE dbo.SP_CierreSemanal
     @inIdSemana     INT
    ,@inIdUsuario    INT
    ,@outResultCode  INT OUTPUT
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON;

    SET @outResultCode = 0;

    DECLARE
         @cantidadSemanas    TINYINT = 0
        ,@idMes              INT = 0
        ,@semanasProcesadas  INT = 0
        ,@fechaInicioSemana  DATE
        ,@fechaFinSemana     DATE;

    -- Tabla variable para acumular todas las deducciones antes de iniciar la transacción
    DECLARE @tDeducciones TABLE (
         IdPlanillaSemanal   INT
        ,IdPlanillaMensual   INT
        ,IdTipoDeduccion     INT
        ,Porcentaje          DECIMAL(6,4)
        ,Monto               DECIMAL(12,2)
    );

    SELECT
         @idMes           = S.IdMes
        ,@cantidadSemanas = M.CantidadSemanas
        ,@fechaInicioSemana  = S.FechaInicio
       ,@fechaFinSemana     = S.FechaFin
    FROM dbo.Semana S
        INNER JOIN dbo.Mes M ON (S.IdMes = M.id)
    WHERE (S.id = @inIdSemana);

    IF (@idMes = 0)
    BEGIN
        SET @outResultCode = 50008; -- semana no encontrada
        RETURN;
    END;

    -- Verificar que no haya sido ya procesada
    SELECT @semanasProcesadas = COUNT(1)
    FROM dbo.PlanillaSemanal PS
    WHERE (PS.IdSemana  = @inIdSemana)
        AND (PS.Procesada = 1);

    IF (@semanasProcesadas > 0)
    BEGIN
        SET @outResultCode = 50008; -- semana ya procesada
        RETURN;
    END;


    -- 1. Deducciones obligatorias porcentuales
    INSERT INTO @tDeducciones
        ( IdPlanillaSemanal
        , IdPlanillaMensual
        , IdTipoDeduccion
        , Porcentaje
        , Monto )
    SELECT
         PS.id
        ,PM.id
        ,TD.id
        ,DL.Porcentaje
        ,FLOOR(PS.SalarioBruto * DL.Porcentaje * 100) / 100
    FROM dbo.PlanillaSemanal PS
        INNER JOIN dbo.PlanillaMensual PM ON (PM.IdEmpleado = PS.IdEmpleado AND PM.IdMes = @idMes)
        INNER JOIN dbo.EXTD ETD ON (ETD.IdEmpleado = PS.IdEmpleado)
        INNER JOIN dbo.TipoDeduccion TD ON (ETD.IdTipoDeduccion = TD.id)
        INNER JOIN dbo.DedLey DL ON (TD.id = DL.id)
    WHERE (PS.IdSemana   = @inIdSemana)
        AND (PS.Procesada  = 0)
        AND (ETD.FechaInicio <= @fechaFinSemana)
        AND (ETD.FechaFin   IS NULL
             OR ETD.FechaFin >= @fechaInicioSemana);

    -- 2. Deducciones voluntarias porcentuales 
    INSERT INTO @tDeducciones
        ( IdPlanillaSemanal
        , IdPlanillaMensual
        , IdTipoDeduccion
        , Porcentaje
        , Monto )
    SELECT
         PS.id
        ,PM.id
        ,TD.id
        ,COALESCE(EP.Porcentaje, DP.Porcentaje)
        ,FLOOR(PS.SalarioBruto * COALESCE(EP.Porcentaje, DP.Porcentaje) * 100) / 100
    FROM dbo.PlanillaSemanal PS
        INNER JOIN dbo.PlanillaMensual PM ON (PM.IdEmpleado = PS.IdEmpleado AND PM.IdMes = @idMes)
        INNER JOIN dbo.EXTD ETD ON (ETD.IdEmpleado = PS.IdEmpleado)
        INNER JOIN dbo.TipoDeduccion TD ON (ETD.IdTipoDeduccion = TD.id)
        INNER JOIN dbo.DedNoObligatoria DNO ON (TD.id = DNO.id AND DNO.FlagFijo = 0)
        INNER JOIN dbo.DedPorcentual DP ON (DNO.id = DP.id)
        LEFT JOIN dbo.EXTDPorcentual EP ON (ETD.id = EP.id)
    WHERE (PS.IdSemana   = @inIdSemana)
        AND (PS.Procesada  = 0)
        AND (ETD.FechaInicio <= @fechaFinSemana)
        AND (ETD.FechaFin   IS NULL
             OR ETD.FechaFin >= @fechaInicioSemana);

    -- 3. Deducciones voluntarias de monto fijo 
    INSERT INTO @tDeducciones
        ( IdPlanillaSemanal
        , IdPlanillaMensual
        , IdTipoDeduccion
        , Porcentaje
        , Monto )
    SELECT
         PS.id
        ,PM.id
        ,TD.id
        ,NULL
        ,FLOOR((EF.Monto / @cantidadSemanas) * 100) / 100
    FROM dbo.PlanillaSemanal PS
        INNER JOIN dbo.PlanillaMensual PM ON (PM.IdEmpleado = PS.IdEmpleado AND PM.IdMes = @idMes)
        INNER JOIN dbo.EXTD ETD ON (ETD.IdEmpleado = PS.IdEmpleado)
        INNER JOIN dbo.TipoDeduccion TD ON (ETD.IdTipoDeduccion = TD.id)
        INNER JOIN dbo.DedNoObligatoria DNO ON (TD.id = DNO.id AND DNO.FlagFijo = 1)
        INNER JOIN dbo.EXTDFijas EF  ON (ETD.id = EF.id)
    WHERE (PS.IdSemana   = @inIdSemana)
        AND (PS.Procesada  = 0)
        AND (ETD.FechaInicio <= @fechaFinSemana)
        AND (ETD.FechaFin   IS NULL
             OR ETD.FechaFin >= @fechaInicioSemana);

        BEGIN TRANSACTION tCierreSemanal;

            -- Insertar detalle de deducciones semanales
            INSERT INTO dbo.DeduccionSemanal
                ( IdPlanillaSemanal
                , IdTipoDeduccion
                , Porcentaje
                , Monto )
            SELECT
                 D.IdPlanillaSemanal
                ,D.IdTipoDeduccion
                ,D.Porcentaje
                ,D.Monto
            FROM @tDeducciones D;

            -- Acumular TotalDeducciones en PlanillaSemanal
            UPDATE dbo.PlanillaSemanal
            SET TotalDeducciones = TotalDeducciones + D.TotalMonto
            FROM dbo.PlanillaSemanal PS
                INNER JOIN (
                    SELECT
                         D.IdPlanillaSemanal
                        ,SUM(D.Monto) AS TotalMonto
                    FROM @tDeducciones D
                    GROUP BY D.IdPlanillaSemanal
                ) D ON (PS.id = D.IdPlanillaSemanal);

            -- Acumular SalarioBruto y TotalDeducciones en PlanillaMensual
            UPDATE dbo.PlanillaMensual
            SET
                 SalarioBruto     = PM.SalarioBruto     + PS.SalarioBruto
                ,TotalDeducciones = PM.TotalDeducciones + PS.TotalDeducciones
            FROM dbo.PlanillaMensual PM
                INNER JOIN dbo.PlanillaSemanal PS ON (PS.IdEmpleado = PM.IdEmpleado)
            WHERE (PS.IdSemana = @inIdSemana)
                AND (PM.IdMes   = @idMes);

            -- Insertar detalle de deducciones mensuales
            INSERT INTO dbo.DeduccionMensual
                ( IdPlanillaMensual
                , IdTipoDeduccion
                , Monto )
            SELECT
                 D.IdPlanillaMensual
                ,D.IdTipoDeduccion
                ,D.Monto
            FROM @tDeducciones D;

            -- Marcar semana como procesada
            UPDATE dbo.PlanillaSemanal
            SET Procesada = 1
            WHERE (IdSemana = @inIdSemana);

            -- Registrar en bitácora
            INSERT INTO dbo.BitacoraEvento
                ( IdUsuario, IdTipoEvento, Descripcion, IpPostIn )
            VALUES
                ( @inIdUsuario
                , 14
                , CONCAT('Cierre semanal IdSemana: ', @inIdSemana)
                , '127.0.0.1' );

        COMMIT TRANSACTION tCierreSemanal;

END TRY
BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION tCierreSemanal;

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
