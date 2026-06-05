CREATE PROCEDURE dbo.SP_ProcesarAsistencia
     @inValorDocumento  VARCHAR(20)
    ,@inMarcaInicio     DATETIME
    ,@inMarcaFin        DATETIME
    ,@inIdSemana        INT
    ,@inIdUsuario       INT
    ,@outResultCode     INT OUTPUT
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON;

    SET @outResultCode = 0;

    DECLARE
         @idEmpleado            INT             = 0
        ,@idPuesto              INT             = 0
        ,@salarioXHora          DECIMAL(10,2)   = 0
        ,@idTipoJornada         INT             = 0
        ,@horaInicioJornada     TIME            = '00:00:00'
        ,@horaFinJornada        TIME            = '00:00:00'
        ,@finJornada            DATETIME
        ,@idPlanillaSemanal     INT             = 0
        ,@horasOrdinarias       DECIMAL(8,2)    = 0
        ,@horasExtraNormales    DECIMAL(8,2)    = 0
        ,@horasExtraDobles      DECIMAL(8,2)    = 0
        ,@montoOrdinario        DECIMAL(12,2)   = 0
        ,@montoExtraNormal      DECIMAL(12,2)   = 0
        ,@montoExtraDoble       DECIMAL(12,2)   = 0
        ,@idAsistencia          INT             = 0
        ,@idMovPlanilla         INT             = 0
        ,@fechaAsistencia       DATE
        ,@fechaSiguiente        DATE
        ,@medianoche            DATETIME
        ,@fechaExtraInicio      DATE
        ,@fechaExtraFin         DATE
        ,@esFeriadoInicio       INT             = 0
        ,@esDomingoInicio       INT             = 0
        ,@esFeriadoFin          INT             = 0
        ,@esDomingoFin          INT             = 0
        ,@minutosExtra          INT             = 0
        ,@minutosExtraAnteMN    INT             = 0
        ,@minutosExtraPostMN    INT             = 0;

    -- obtener empleado y salario por hora
    SELECT
         @idEmpleado    = E.id
        ,@idPuesto      = E.IdPuesto
        ,@salarioXHora  = P.SalarioXHora
    FROM dbo.Empleado E
        INNER JOIN dbo.Puesto P
            ON (E.IdPuesto = P.id)
    WHERE (E.documentoIdentidad = @inValorDocumento)
        AND (E.Activo = 1);

    IF (@idEmpleado = 0)
    BEGIN
        SET @outResultCode = 50008;
        RETURN;
    END;

    -- Obtener jornada del empleado en esa semana
    SELECT
         @idTipoJornada     = HJ.IdTipoJornada
        ,@horaInicioJornada = TJ.HoraInicio
        ,@horaFinJornada    = TJ.HoraFin
    FROM dbo.HorarioJornada HJ
        INNER JOIN dbo.TipoJornada TJ
            ON (HJ.IdTipoJornada = TJ.id)
    WHERE (HJ.IdEmpleado = @idEmpleado)
        AND (HJ.IdSemana  = @inIdSemana);

    IF (@idTipoJornada = 0)
    BEGIN
        SET @outResultCode = 50008;
        RETURN;
    END;

    -- Obtener PlanillaSemanal del empleado
    SELECT @idPlanillaSemanal = PS.id
    FROM dbo.PlanillaSemanal PS
    WHERE (PS.IdEmpleado = @idEmpleado)
        AND (PS.IdSemana  = @inIdSemana);

    IF (@idPlanillaSemanal = 0)
    BEGIN
        SET @outResultCode = 50008;
        RETURN;
    END;

    -- Calcular fecha de la asistencia y fin de jornada como DATETIME
    SET @fechaAsistencia = CAST(@inMarcaInicio AS DATE);
    SET @fechaSiguiente  = DATEADD(DAY, 1, @fechaAsistencia);

    -- Si HoraFin < HoraInicio es jornada nocturna (cruza medianoche)
    IF (@horaFinJornada < @horaInicioJornada)
        SET @finJornada = DATETIMEFROMPARTS(
             YEAR(@fechaSiguiente), MONTH(@fechaSiguiente), DAY(@fechaSiguiente)
            ,DATEPART(HOUR,   @horaFinJornada)
            ,DATEPART(MINUTE, @horaFinJornada)
            ,0, 0);
    ELSE
        SET @finJornada = DATETIMEFROMPARTS(
             YEAR(@fechaAsistencia), MONTH(@fechaAsistencia), DAY(@fechaAsistencia)
            ,DATEPART(HOUR,   @horaFinJornada)
            ,DATEPART(MINUTE, @horaFinJornada)
            ,0, 0);

    -- Calcular horas según si hay extras o no
    IF (@inMarcaFin <= @finJornada)
    BEGIN
        -- Solo horas ordinarias, no hay extras
        SET @horasOrdinarias = FLOOR(DATEDIFF(MINUTE, @inMarcaInicio, @inMarcaFin) / 60.0);
    END;
    ELSE
    BEGIN
        -- Horas ordinarias hasta fin de jornada
        SET @horasOrdinarias = FLOOR(DATEDIFF(MINUTE, @inMarcaInicio, @finJornada) / 60.0);

        -- Minutos extra totales
        SET @minutosExtra = DATEDIFF(MINUTE, @finJornada, @inMarcaFin);

        -- Medianoche del día donde inician las extras
        SET @medianoche = CAST(DATEADD(DAY, 1, CAST(@finJornada AS DATE)) AS DATETIME);

        IF (@inMarcaFin <= @medianoche)
        BEGIN
            -- Todas las extras en el mismo día, no cruzan medianoche
            SET @fechaExtraInicio = CAST(@finJornada AS DATE);

            IF (DATEPART(WEEKDAY, @fechaExtraInicio) = 1)
                SET @esDomingoInicio = 1;

            SELECT @esFeriadoInicio = COUNT(1)
            FROM dbo.Feriados F
            WHERE (F.Fecha = @fechaExtraInicio);

            IF (@esDomingoInicio = 1 OR @esFeriadoInicio >= 1)
                SET @horasExtraDobles   = FLOOR(@minutosExtra / 60.0);
            ELSE
                SET @horasExtraNormales = FLOOR(@minutosExtra / 60.0);
        END;
        ELSE
        BEGIN
            -- Las extras cruzan medianoche: dividir en dos partes
            SET @minutosExtraAnteMN = DATEDIFF(MINUTE, @finJornada, @medianoche);
            SET @minutosExtraPostMN = DATEDIFF(MINUTE, @medianoche, @inMarcaFin);

            SET @fechaExtraInicio = CAST(@finJornada AS DATE);
            SET @fechaExtraFin    = CAST(@inMarcaFin AS DATE);

            -- Verificar día de inicio de extras
            IF (DATEPART(WEEKDAY, @fechaExtraInicio) = 1)
                SET @esDomingoInicio = 1;

            SELECT @esFeriadoInicio = COUNT(1)
            FROM dbo.Feriados F
            WHERE (F.Fecha = @fechaExtraInicio);

            -- Verificar día de fin de extras
            IF (DATEPART(WEEKDAY, @fechaExtraFin) = 1)
                SET @esDomingoFin = 1;

            SELECT @esFeriadoFin = COUNT(1)
            FROM dbo.Feriados F
            WHERE (F.Fecha = @fechaExtraFin);

            -- Horas extras antes de medianoche
            IF (@esDomingoInicio = 1 OR @esFeriadoInicio >= 1)
                SET @horasExtraDobles   = FLOOR(@minutosExtraAnteMN / 60.0);
            ELSE
                SET @horasExtraNormales = FLOOR(@minutosExtraAnteMN / 60.0);

            -- Horas extras después de medianoche
            IF (@esDomingoFin = 1 OR @esFeriadoFin >= 1)
                SET @horasExtraDobles   = @horasExtraDobles   + FLOOR(@minutosExtraPostMN / 60.0);
            ELSE
                SET @horasExtraNormales = @horasExtraNormales + FLOOR(@minutosExtraPostMN / 60.0);
        END;
    END;

    -- Calcular montos
    SET @montoOrdinario   = @horasOrdinarias    * @salarioXHora;
    SET @montoExtraNormal = @horasExtraNormales * @salarioXHora * 1.5;
    SET @montoExtraDoble  = @horasExtraDobles   * @salarioXHora * 2.0;


        BEGIN TRANSACTION tProcesarAsistencia;

            -- Insertar registro de asistencia
            INSERT INTO dbo.Asistencia
                ( IdEmpleado
                , MarcaInicio
                , MarcaFin
                , Fecha )
            VALUES
                ( @idEmpleado
                , @inMarcaInicio
                , @inMarcaFin
                , @fechaAsistencia );

            SET @idAsistencia = SCOPE_IDENTITY();

            -- Movimiento horas ordinarias
            IF (@horasOrdinarias > 0)
            BEGIN
                INSERT INTO dbo.MovPlanilla
                    ( IdPlanillaSemanal
                    , IdTipoMov
                    , Fecha
                    , Monto )
                VALUES
                    ( @idPlanillaSemanal
                    , 1
                    , @fechaAsistencia
                    , @montoOrdinario );

                SET @idMovPlanilla = SCOPE_IDENTITY();

                INSERT INTO dbo.MovHorasTrab
                    ( id
                    , IdAsistencia
                    , QHoras )
                VALUES
                    ( @idMovPlanilla
                    , @idAsistencia
                    , @horasOrdinarias );
            END;

            -- Movimiento horas extra normales
            IF (@horasExtraNormales > 0)
            BEGIN
                INSERT INTO dbo.MovPlanilla
                    ( IdPlanillaSemanal
                    , IdTipoMov
                    , Fecha
                    , Monto )
                VALUES
                    ( @idPlanillaSemanal
                    , 2
                    , @fechaAsistencia
                    , @montoExtraNormal );

                SET @idMovPlanilla = SCOPE_IDENTITY();

                INSERT INTO dbo.MovHorasTrab
                    ( id
                    , IdAsistencia
                    , QHoras )
                VALUES
                    ( @idMovPlanilla
                    , @idAsistencia
                    , @horasExtraNormales );
            END;

            -- Movimiento horas extra dobles
            IF (@horasExtraDobles > 0)
            BEGIN
                INSERT INTO dbo.MovPlanilla
                    ( IdPlanillaSemanal
                    , IdTipoMov
                    , Fecha
                    , Monto )
                VALUES
                    ( @idPlanillaSemanal
                    , 3
                    , @fechaAsistencia
                    , @montoExtraDoble );

                SET @idMovPlanilla = SCOPE_IDENTITY();

                INSERT INTO dbo.MovHorasTrab
                    ( id
                    , IdAsistencia
                    , QHoras )
                VALUES
                    ( @idMovPlanilla
                    , @idAsistencia
                    , @horasExtraDobles );
            END;

            -- Acumular en PlanillaSemanal
            UPDATE dbo.PlanillaSemanal
            SET
                 SalarioBruto       = SalarioBruto       + @montoOrdinario + @montoExtraNormal + @montoExtraDoble
                ,HorasOrdinarias    = HorasOrdinarias    + @horasOrdinarias
                ,HorasExtraNormales = HorasExtraNormales + @horasExtraNormales
                ,HorasExtraDobles   = HorasExtraDobles   + @horasExtraDobles
            WHERE (id = @idPlanillaSemanal);

            -- Registrar en bitácora
            INSERT INTO dbo.BitacoraEvento
                ( IdUsuario, IdTipoEvento, Descripcion, IpPostIn )
            VALUES
                ( @inIdUsuario
                , 14
                , CONCAT('{"IdEmpleado":', @idEmpleado, 
                         ',"MarcaInicio":"', @inMarcaInicio,
                         '","MarcaFin":"', @inMarcaFin, '"}')
                , '127.0.0.1' );

        COMMIT TRANSACTION tProcesarAsistencia;

END TRY
BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION tProcesarAsistencia;

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