
CREATE PROCEDURE dbo.SP_CargarCatalogos
     @inXML          XML
    ,@outResultCode  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @outResultCode = 0;

    BEGIN TRY

        INSERT INTO dbo.Puesto
            ( Nombre
            , SalarioXHora )
        SELECT
             nodo.value('@Nombre',       'VARCHAR(100)')
            ,nodo.value('@SalarioXHora', 'DECIMAL(10,2)')
        FROM @inXML.nodes('/Datos/Puestos/Puesto') AS t(nodo);

        INSERT INTO dbo.TipoJornada
            ( id
            , Nombre
            , HoraInicio
            , HoraFin )
        SELECT
             nodo.value('@Id',         'INT')
            ,nodo.value('@Nombre',     'VARCHAR(50)')
            ,nodo.value('@HoraInicio', 'TIME')
            ,nodo.value('@HoraFin',    'TIME')
        FROM @inXML.nodes('/Datos/TiposJornada/TipoJornada') AS t(nodo);


        INSERT INTO dbo.Feriados
            ( id
            , Nombre
            , Fecha )
        SELECT
             nodo.value('@Id',     'INT')
            ,nodo.value('@Nombre', 'VARCHAR(100)')
            ,nodo.value('@Fecha',  'DATE')
        FROM @inXML.nodes('/Datos/Feriados/Feriado') AS t(nodo);


        INSERT INTO dbo.TipoEvento
            ( id
            , Nombre )
        SELECT
             nodo.value('@Id',     'INT')
            ,nodo.value('@Nombre', 'VARCHAR(100)')
        FROM @inXML.nodes('/Datos/TiposEvento/TipoEvento') AS t(nodo);


        INSERT INTO dbo.TipoMov
            ( id
            , Nombre
            , Accion )
        SELECT
             nodo.value('@Id',     'INT')
            ,nodo.value('@Nombre', 'VARCHAR(100)')
            ,nodo.value('@Accion', 'CHAR(1)')
        FROM @inXML.nodes('/Datos/TiposMovimiento/TipoMovimiento') AS t(nodo);


        INSERT INTO dbo.TipoDeduccion
            ( id
            , IdTipoMov
            , FlagObligatorio
            , Nombre )
        SELECT
             nodo.value('@Id',           'INT')
            ,TM.id
            ,nodo.value('@EsObligatoria','BIT')
            ,nodo.value('@Nombre',       'VARCHAR(100)')
        FROM @inXML.nodes('/Datos/TiposDeduccion/TipoDeduccion') AS t(nodo)
            INNER JOIN dbo.TipoMov TM
                ON (TM.Nombre = nodo.value('@TipoMovimiento', 'VARCHAR(100)'));

        -- DedLey: deducciones obligatorias porcentuales
        INSERT INTO dbo.DedLey
            ( id
            , Porcentaje )
        SELECT
             nodo.value('@Id',    'INT')
            ,nodo.value('@Valor', 'DECIMAL(6,4)')
        FROM @inXML.nodes('/Datos/TiposDeduccion/TipoDeduccion') AS t(nodo)
        WHERE (nodo.value('@EsObligatoria', 'BIT') = 1)
            AND (nodo.value('@EsPorcentual',  'BIT') = 1);

        -- DedNoObligatoria: deducciones voluntarias
        -- FlagFijo = 1 si EsPorcentual = 0, FlagFijo = 0 si EsPorcentual = 1
        INSERT INTO dbo.DedNoObligatoria
            ( id
            , FlagFijo )
        SELECT
             nodo.value('@Id',          'INT')
            ,CASE nodo.value('@EsPorcentual', 'BIT')
                WHEN 1 THEN 0
                ELSE 1
             END
        FROM @inXML.nodes('/Datos/TiposDeduccion/TipoDeduccion') AS t(nodo)
        WHERE (nodo.value('@EsObligatoria', 'BIT') = 0);

        -- DedPorcentual: voluntarias porcentuales
        INSERT INTO dbo.DedPorcentual
            ( id
            , Porcentaje )
        SELECT
             nodo.value('@Id',    'INT')
            ,nodo.value('@Valor', 'DECIMAL(6,4)')
        FROM @inXML.nodes('/Datos/TiposDeduccion/TipoDeduccion') AS t(nodo)
        WHERE (nodo.value('@EsObligatoria', 'BIT') = 0)
            AND (nodo.value('@EsPorcentual',  'BIT') = 1);

        -- DedFijo: voluntarias de monto fijo (monto inicial 0, se define por empleado)
        INSERT INTO dbo.DedFijo
            ( id
            , Monto )
        SELECT
             nodo.value('@Id',    'INT')
            ,nodo.value('@Valor', 'DECIMAL(12,2)')
        FROM @inXML.nodes('/Datos/TiposDeduccion/TipoDeduccion') AS t(nodo)
        WHERE (nodo.value('@EsObligatoria', 'BIT') = 0)
            AND (nodo.value('@EsPorcentual',  'BIT') = 0);

        -- ------------------------------------------------
        -- Usuarios administradores 
        -- ------------------------------------------------
        INSERT INTO dbo.Usuario
            ( [User]
            , [Password]
            , Tipo
            , IdEmpleado )
        SELECT
             nodo.value('@Username',     'VARCHAR(50)')
            ,nodo.value('@PasswordHash', 'VARCHAR(255)')
            ,nodo.value('@Tipo',         'TINYINT')
            ,NULL
        FROM @inXML.nodes('/Datos/Usuarios/Usuario') AS t(nodo);

        -- ------------------------------------------------
        -- CodigoError 
        -- ------------------------------------------------
        INSERT INTO dbo.CodigoError
            ( Codigo
            , Descripcion )
        SELECT
             nodo.value('@Codigo',      'INT')
            ,nodo.value('@Descripcion', 'VARCHAR(400)')
        FROM @inXML.nodes('/Datos/Error/error') AS t(nodo);

        -- ------------------------------------------------
        -- TipoDocumentoIdentidad 
        -- ------------------------------------------------
        INSERT INTO dbo.TipoDocumentoIdentidad
            ( id, Nombre )
        VALUES
             (1, 'Cedula Nacional')
            ,(2, 'DIMEX')
            ,(3, 'Pasaporte');

        -- ------------------------------------------------
        -- Departamento 
        -- ------------------------------------------------
        INSERT INTO dbo.Departamento
            ( id, Nombre )
        VALUES
             (1, 'Produccion')
            ,(2, 'Mantenimiento')
            ,(3, 'Logistica')
            ,(4, 'Laboratorio');

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