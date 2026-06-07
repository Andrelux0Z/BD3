CREATE PROCEDURE dbo.SP_ConsultarDeduccionesMensual
     @inIdPlanillaMensual    INT
    ,@inIdUsuario            INT
    ,@inIP                   VARCHAR(45)
    ,@outResultCode          INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @outResultCode = 0;

    BEGIN TRY

        SELECT
             TM.Nombre          AS NombreDeduccion
            ,SUM(DM.Monto)      AS Monto
        FROM dbo.DeduccionMensual DM
        INNER JOIN dbo.TipoDeduccion TD ON (DM.IdTipoDeduccion = TD.id)
        INNER JOIN dbo.TipoMov TM ON (TD.IdTipoMov = TM.id)
        WHERE (DM.IdPlanillaMensual = @inIdPlanillaMensual)
        GROUP BY TM.Nombre
        ORDER BY TM.Nombre ASC;

        INSERT INTO dbo.BitacoraEvento
            ( IdUsuario, IdTipoEvento, Descripcion, IpPostIn )
        VALUES
            ( @inIdUsuario
            , 21
            , CONCAT('{"IdPlanillaMensual":', @inIdPlanillaMensual, '}')
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