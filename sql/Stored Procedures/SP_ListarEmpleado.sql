/****** Object:  StoredProcedure [dbo].[SP_ListarEmpleados] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_ListarEmpleados]
     @inIdUsuario    INT
    ,@inIP           VARCHAR(45)
    ,@outResultCode  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @outResultCode = 0;

    BEGIN TRY

        INSERT INTO dbo.BitacoraEvento (IdUsuario, IdTipoEvento, Descripcion, IpPostIn)
        VALUES
            (@inIdUsuario, 17, NULL, @inIP);

        SELECT
             E.id
            ,E.Nombre
            ,E.documentoIdentidad
            ,P.Nombre           AS NombrePuesto
        FROM dbo.Empleado E
        INNER JOIN dbo.Puesto P ON (E.IdPuesto = P.id)
        WHERE (E.Activo = 1)
        ORDER BY E.Nombre ASC;

    END TRY
    BEGIN CATCH

        SET @outResultCode = 50008;

        INSERT INTO dbo.DBErrors
            (UserName, Number, State, Severity, Line, [Procedure], Message)
        VALUES
            ( SYSTEM_USER
            , ERROR_NUMBER()
            , ERROR_STATE()
            , ERROR_SEVERITY()
            , ERROR_LINE()
            , ERROR_PROCEDURE()
            , ERROR_MESSAGE()
            );

    END CATCH;

END;