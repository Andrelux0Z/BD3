
CREATE PROCEDURE dbo.SP_DesasociarDeduccion
     @inValorDocumento  VARCHAR(20)
    ,@inNombreDeduccion VARCHAR(100)
    ,@inFechaFin        DATE
    ,@inIdUsuario       INT
    ,@inIP              VARCHAR(45)
    ,@outResultCode     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    SET @outResultCode = 0;

    DECLARE
         @idEmpleado        INT = 0
        ,@idTipoDeduccion   INT = 0
        ,@idExtd            INT = 0
        ,@flagObligatorio   BIT = 0;

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
            SET @outResultCode = 60020;
            RETURN;
        END;

        -- No se pueden desasociar deducciones obligatorias
        IF (@flagObligatorio = 1)
        BEGIN
            SET @outResultCode = 60021;
            RETURN;
        END;

        -- Obtener el EXTD vigente
        SELECT @idExtd = ETD.id
        FROM dbo.EXTD ETD
        WHERE (ETD.IdEmpleado = @idEmpleado)
            AND (ETD.IdTipoDeduccion = @idTipoDeduccion)
            AND (ETD.FechaFin IS NULL);

        IF (@idExtd = 0)
        BEGIN
            SET @outResultCode = 60023; -- deducción no está asociada
            RETURN;
        END;

        BEGIN TRANSACTION tDesasociarDeduccion;

            -- Poner FechaFin para marcar como inactiva
            UPDATE dbo.EXTD
            SET FechaFin = @inFechaFin
            WHERE (id = @idExtd);

            -- Registrar en bitácora
            INSERT INTO dbo.BitacoraEvento
                ( IdUsuario, IdTipoEvento, Descripcion, IpPostIn )
            VALUES
                ( @inIdUsuario
                , 6
                , CONCAT('{"IdEmpleado":', @idEmpleado,
                         ',"IdTipoDeduccion":', @idTipoDeduccion, '}')
                , @inIP );

        COMMIT TRANSACTION tDesasociarDeduccion;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION tDesasociarDeduccion;

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