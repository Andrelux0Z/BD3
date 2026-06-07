CREATE PROCEDURE dbo.SP_AsociarDeduccion
     @inValorDocumento  VARCHAR(20)
    ,@inNombreDeduccion VARCHAR(100)
    ,@inMontoFijo       DECIMAL(12,2)
    ,@inFechaInicio     DATE
    ,@inIdUsuario       INT
    ,@inIP              VARCHAR(45)
    ,@outResultCode     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    BEGIN TRY

    DECLARE
         @idEmpleado        INT         = 0
        ,@idTipoDeduccion   INT         = 0
        ,@flagFijo          BIT         = 0
        ,@flagObligatorio   BIT         = 0
        ,@porcentaje        DECIMAL(6,4)= 0
        ,@idExtd            INT         = 0
        ,@yaAsociada        INT         = 0;

        -- Obtener empleado por cédula
        SELECT @idEmpleado = E.id
        FROM dbo.Empleado E
        WHERE (E.documentoIdentidad = @inValorDocumento)
            AND (E.Activo = 1);

        IF (@idEmpleado = 0)
        BEGIN
            SET @outResultCode = 50008;
            RETURN;
        END;

        -- Obtener TipoDeduccion por nombre
        SELECT
             @idTipoDeduccion = TD.id
            ,@flagObligatorio = TD.FlagObligatorio
        FROM dbo.TipoDeduccion TD
        WHERE (TD.Nombre = @inNombreDeduccion);

        IF (@idTipoDeduccion = 0)
        BEGIN
            SET @outResultCode = 50008;
            RETURN;
        END;

        IF (@flagObligatorio = 1)
        BEGIN
            SET @outResultCode = 50008;
            RETURN;
        END;

        -- Verificar si ya está asociada y vigente
        SELECT @yaAsociada = COUNT(1)
        FROM dbo.EXTD ETD
        WHERE (ETD.IdEmpleado = @idEmpleado)
            AND (ETD.IdTipoDeduccion = @idTipoDeduccion)
            AND (ETD.FechaFin IS NULL);

        IF (@yaAsociada > 0)
        BEGIN
            SET @outResultCode = 50008;
            RETURN;
        END;

        -- Obtener si es fija o porcentual
        SELECT @flagFijo = DNO.FlagFijo
        FROM dbo.DedNoObligatoria DNO
        WHERE (DNO.id = @idTipoDeduccion);

        -- Si es porcentual obtener el porcentaje del tipo
        IF (@flagFijo = 0)
        BEGIN
            SELECT @porcentaje = DP.Porcentaje
            FROM dbo.DedPorcentual DP
            WHERE (DP.id = @idTipoDeduccion);
        END;

        BEGIN TRANSACTION tAsociarDeduccion;

            -- Insertar en EXTD
            INSERT INTO dbo.EXTD
                ( IdEmpleado
                , IdTipoDeduccion
                , FechaInicio
                , FechaFin )
            VALUES
                ( @idEmpleado
                , @idTipoDeduccion
                , @inFechaInicio
                , NULL );

            SET @idExtd = SCOPE_IDENTITY();

            -- Insertar en tabla hija según tipo
            IF (@flagFijo = 1)
            BEGIN
                INSERT INTO dbo.EXTDFijas
                    ( id
                    , Monto )
                VALUES
                    ( @idExtd
                    , @inMontoFijo );
            END;
            ELSE
            BEGIN
                INSERT INTO dbo.EXTDPorcentual
                    ( id
                    , Porcentaje )
                VALUES
                    ( @idExtd
                    , @porcentaje );
            END;

            -- Registrar en bitácora
            INSERT INTO dbo.BitacoraEvento
                ( IdUsuario, IdTipoEvento, Descripcion, IpPostIn )
            VALUES
                ( @inIdUsuario
                , 18
                , CONCAT('{"IdEmpleado":', @idEmpleado,
                         ',"IdTipoDeduccion":', @idTipoDeduccion,
                         ',"ValorPorcentual":', @porcentaje,
                         ',"MontoFijo":', @inMontoFijo, '}')
                , @inIP );

        COMMIT TRANSACTION tAsociarDeduccion;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION tAsociarDeduccion;

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

