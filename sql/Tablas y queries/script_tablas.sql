
-- ============================================================
-- CATÁLOGOS
-- ============================================================

CREATE TABLE dbo.TipoJornada (
     id          INT         NOT NULL
    ,Nombre      VARCHAR(50) NOT NULL
    ,HoraInicio  TIME        NOT NULL
    ,HoraFin     TIME        NOT NULL
    ,CONSTRAINT PK_TipoJornada PRIMARY KEY (id)
);

CREATE TABLE dbo.Puesto (
     id           INT            NOT NULL IDENTITY(1,1)
    ,Nombre       VARCHAR(100)   NOT NULL
    ,SalarioXHora DECIMAL(10,2)  NOT NULL
    ,CONSTRAINT PK_Puesto PRIMARY KEY (id)
    ,CONSTRAINT UQ_Puesto UNIQUE (Nombre)
);

CREATE TABLE dbo.Feriados (
     id      INT          NOT NULL
    ,Nombre  VARCHAR(100) NOT NULL
    ,Fecha   DATE         NOT NULL
    ,CONSTRAINT PK_Feriados PRIMARY KEY (id)
);

CREATE TABLE dbo.TipoEvento (
     id      INT          NOT NULL
    ,Nombre  VARCHAR(100) NOT NULL
    ,CONSTRAINT PK_TipoEvento PRIMARY KEY (id)
);

-- Tabla de códigos de error del sistema
CREATE TABLE dbo.CodigoError (
     Codigo      INT             NOT NULL
    ,Descripcion VARCHAR(400)    NOT NULL
    ,CONSTRAINT PK_CodigoError PRIMARY KEY (Codigo)
);


CREATE TABLE dbo.TipoMov (
     id      INT          NOT NULL
    ,Nombre  VARCHAR(100) NOT NULL
    ,Accion  CHAR(1)      NOT NULL
    ,CONSTRAINT PK_TipoMov   PRIMARY KEY (id)
    ,CONSTRAINT CK_TipoMovAc CHECK (Accion IN ('C','D'))
);


CREATE TABLE dbo.TipoDeduccion (
     id              INT  NOT NULL
    ,IdTipoMov       INT  NOT NULL
    ,Nombre VARCHAR(100) NOT NULL DEFAULT ''
    ,FlagObligatorio BIT  NOT NULL DEFAULT 0
    ,CONSTRAINT PK_TipoDeduccion PRIMARY KEY (id)
    ,CONSTRAINT FK_TD_TipoMov    FOREIGN KEY (IdTipoMov) REFERENCES dbo.TipoMov(id)
);

-- Hijo de TipoDeduccion: deducciones obligatorias porcentuales
CREATE TABLE dbo.DedLey (
     id         INT          NOT NULL
    ,Porcentaje DECIMAL(6,4) NOT NULL
    ,CONSTRAINT PK_DedLey PRIMARY KEY (id)
    ,CONSTRAINT FK_DL_TD  FOREIGN KEY (id) REFERENCES dbo.TipoDeduccion(id)
);

-- Hijo de TipoDeduccion: deducciones no obligatorias
CREATE TABLE dbo.DedNoObligatoria (
     id       INT NOT NULL
    ,FlagFijo BIT NOT NULL
    ,CONSTRAINT PK_DedNoObl PRIMARY KEY (id)
    ,CONSTRAINT FK_DNO_TD   FOREIGN KEY (id) REFERENCES dbo.TipoDeduccion(id)
);

CREATE TABLE dbo.DedFijo (
     id    INT           NOT NULL
    ,Monto DECIMAL(12,2) NOT NULL
    ,CONSTRAINT PK_DedFijo PRIMARY KEY (id)
    ,CONSTRAINT FK_DF_DNO  FOREIGN KEY (id) REFERENCES dbo.DedNoObligatoria(id)
);

CREATE TABLE dbo.DedPorcentual (
     id         INT          NOT NULL
    ,Porcentaje DECIMAL(6,4) NOT NULL
    ,CONSTRAINT PK_DedPct PRIMARY KEY (id)
    ,CONSTRAINT FK_DP_DNO FOREIGN KEY (id) REFERENCES dbo.DedNoObligatoria(id)
);

-- ============================================================
-- TIEMPO
-- ============================================================

CREATE TABLE dbo.Mes (
     id              INT     NOT NULL IDENTITY(1,1)
    ,FechaInicio     DATE    NOT NULL
    ,FechaFin        DATE    NOT NULL
    ,CantidadSemanas TINYINT NOT NULL
    ,CONSTRAINT PK_Mes    PRIMARY KEY (id)
    ,CONSTRAINT CK_MesSem CHECK (CantidadSemanas IN (4,5))
);

CREATE TABLE dbo.Semana (
     id          INT  NOT NULL IDENTITY(1,1)
    ,IdMes       INT  NOT NULL
    ,FechaInicio DATE NOT NULL
    ,FechaFin    DATE NOT NULL
    ,CONSTRAINT PK_Semana  PRIMARY KEY (id)
    ,CONSTRAINT FK_Sem_Mes FOREIGN KEY (IdMes) REFERENCES dbo.Mes(id)
);

-- ============================================================
-- USUARIOS Y EMPLEADOS
-- ============================================================

CREATE TABLE dbo.Usuario (
     id         INT          NOT NULL IDENTITY(1,1)
    ,[User]     VARCHAR(50)  NOT NULL
    ,[Password] VARCHAR(255) NOT NULL
    ,Tipo       TINYINT      NOT NULL
    ,CONSTRAINT PK_Usuario PRIMARY KEY (id)
    ,CONSTRAINT UQ_User    UNIQUE ([User])
    ,CONSTRAINT CK_TipoUsr CHECK (Tipo IN (1,2))
);

CREATE TABLE dbo.Empleado (
     id                 INT          NOT NULL IDENTITY(1,1)
    ,documentoIdentidad VARCHAR(20)  NOT NULL
    ,Nombre             VARCHAR(200) NOT NULL
    ,IdPuesto           INT          NOT NULL
    ,CuentaBancaria     VARCHAR(50)  NULL
    ,Activo             BIT          NOT NULL DEFAULT 1
    ,CONSTRAINT PK_Empleado     PRIMARY KEY (id)
    ,CONSTRAINT UQ_DocIdentidad UNIQUE (documentoIdentidad)
    ,CONSTRAINT FK_Emp_Puesto   FOREIGN KEY (IdPuesto)        REFERENCES dbo.Puesto(id)
);

ALTER TABLE dbo.Usuario
    ADD IdEmpleado INT NULL
        CONSTRAINT FK_Usr_Empleado FOREIGN KEY REFERENCES dbo.Empleado(id);

-- ============================================================
-- DEDUCCIONES POR EMPLEADO (EXTD)
-- ============================================================

CREATE TABLE dbo.EXTD (
     id              INT  NOT NULL IDENTITY(1,1)
    ,IdEmpleado      INT  NOT NULL
    ,IdTipoDeduccion INT  NOT NULL
    ,FechaInicio     DATE NOT NULL
    ,FechaFin        DATE NULL
    ,CONSTRAINT PK_EXTD     PRIMARY KEY (id)
    ,CONSTRAINT FK_EXTD_Emp FOREIGN KEY (IdEmpleado)      REFERENCES dbo.Empleado(id)
    ,CONSTRAINT FK_EXTD_TD  FOREIGN KEY (IdTipoDeduccion) REFERENCES dbo.TipoDeduccion(id)
);

CREATE TABLE dbo.EXTDFijas (
     id    INT           NOT NULL
    ,Monto DECIMAL(12,2) NOT NULL
    ,CONSTRAINT PK_EXTDFijas PRIMARY KEY (id)
    ,CONSTRAINT FK_EXF_EXTD  FOREIGN KEY (id) REFERENCES dbo.EXTD(id)
);

CREATE TABLE dbo.EXTDPorcentual (
     id         INT          NOT NULL
    ,Porcentaje DECIMAL(6,4) NOT NULL
    ,CONSTRAINT PK_EXTDPct  PRIMARY KEY (id)
    ,CONSTRAINT FK_EXP_EXTD FOREIGN KEY (id) REFERENCES dbo.EXTD(id)
);

-- ============================================================
-- ASISTENCIA Y JORNADA
-- ============================================================

CREATE TABLE dbo.Asistencia (
     id          INT      NOT NULL IDENTITY(1,1)
    ,IdEmpleado  INT      NOT NULL
    ,MarcaInicio DATETIME NOT NULL
    ,MarcaFin    DATETIME NOT NULL
    ,Fecha       DATE     NOT NULL
    ,CONSTRAINT PK_Asistencia PRIMARY KEY (id)
    ,CONSTRAINT FK_Asist_Emp  FOREIGN KEY (IdEmpleado) REFERENCES dbo.Empleado(id)
);

CREATE TABLE dbo.HorarioJornada (
     id            INT NOT NULL IDENTITY(1,1)
    ,IdEmpleado    INT NOT NULL
    ,IdSemana      INT NOT NULL
    ,IdTipoJornada INT NOT NULL
    ,CONSTRAINT PK_HorarioJornada PRIMARY KEY (id)
    ,CONSTRAINT FK_HJ_Emp         FOREIGN KEY (IdEmpleado)    REFERENCES dbo.Empleado(id)
    ,CONSTRAINT FK_HJ_Semana      FOREIGN KEY (IdSemana)      REFERENCES dbo.Semana(id)
    ,CONSTRAINT FK_HJ_Jornada     FOREIGN KEY (IdTipoJornada) REFERENCES dbo.TipoJornada(id)
    ,CONSTRAINT UQ_HJ_EmpSem      UNIQUE (IdEmpleado, IdSemana)
);

-- ============================================================
-- PLANILLA
-- ============================================================

CREATE TABLE dbo.PlanillaSemanal (
     id                 INT           NOT NULL IDENTITY(1,1)
    ,IdEmpleado         INT           NOT NULL
    ,IdSemana           INT           NOT NULL
    ,SalarioBruto       DECIMAL(12,2) NOT NULL DEFAULT 0
    ,TotalDeducciones   DECIMAL(12,2) NOT NULL DEFAULT 0
    ,SalarioNeto        AS (SalarioBruto - TotalDeducciones)
    ,HorasOrdinarias    DECIMAL(8,2)  NOT NULL DEFAULT 0
    ,HorasExtraNormales DECIMAL(8,2)  NOT NULL DEFAULT 0
    ,HorasExtraDobles   DECIMAL(8,2)  NOT NULL DEFAULT 0
    ,Procesada          BIT           NOT NULL DEFAULT 0
    ,CONSTRAINT PK_PlanillaSemanal PRIMARY KEY (id)
    ,CONSTRAINT FK_PS_Emp          FOREIGN KEY (IdEmpleado) REFERENCES dbo.Empleado(id)
    ,CONSTRAINT FK_PS_Semana       FOREIGN KEY (IdSemana)   REFERENCES dbo.Semana(id)
    ,CONSTRAINT UQ_PS_EmpSem       UNIQUE (IdEmpleado, IdSemana)
);

CREATE TABLE dbo.PlanillaMensual (
     id               INT           NOT NULL IDENTITY(1,1)
    ,IdEmpleado       INT           NOT NULL
    ,IdMes            INT           NOT NULL
    ,SalarioBruto     DECIMAL(12,2) NOT NULL DEFAULT 0
    ,TotalDeducciones DECIMAL(12,2) NOT NULL DEFAULT 0
    ,SalarioNeto      AS (SalarioBruto - TotalDeducciones)
    ,CONSTRAINT PK_PlanillaMensual PRIMARY KEY (id)
    ,CONSTRAINT FK_PM_Emp          FOREIGN KEY (IdEmpleado) REFERENCES dbo.Empleado(id)
    ,CONSTRAINT FK_PM_Mes          FOREIGN KEY (IdMes)      REFERENCES dbo.Mes(id)
    ,CONSTRAINT UQ_PM_EmpMes       UNIQUE (IdEmpleado, IdMes)
);

-- ============================================================
-- MOVIMIENTOS
-- ============================================================

CREATE TABLE dbo.MovPlanilla (
     id                INT           NOT NULL IDENTITY(1,1)
    ,IdPlanillaSemanal INT           NOT NULL
    ,IdTipoMov         INT           NOT NULL
    ,Fecha             DATE          NOT NULL
    ,Monto             DECIMAL(12,2) NOT NULL
    ,CONSTRAINT PK_MovPlanilla PRIMARY KEY (id)
    ,CONSTRAINT FK_MP_PlanSem  FOREIGN KEY (IdPlanillaSemanal) REFERENCES dbo.PlanillaSemanal(id)
    ,CONSTRAINT FK_MP_TipoMov  FOREIGN KEY (IdTipoMov)         REFERENCES dbo.TipoMov(id)
);

CREATE TABLE dbo.MovHorasTrab (
     id           INT          NOT NULL
    ,IdAsistencia INT          NOT NULL
    ,QHoras       DECIMAL(5,2) NOT NULL
    ,CONSTRAINT PK_MovHorasTrab   PRIMARY KEY (id)
    ,CONSTRAINT FK_MHT_MovPlan    FOREIGN KEY (id)           REFERENCES dbo.MovPlanilla(id)
    ,CONSTRAINT FK_MHT_Asistencia FOREIGN KEY (IdAsistencia) REFERENCES dbo.Asistencia(id)
);

CREATE TABLE dbo.DeduccionSemanal (
     id                INT           NOT NULL IDENTITY(1,1)
    ,IdPlanillaSemanal INT           NOT NULL
    ,IdTipoDeduccion   INT           NOT NULL
    ,Porcentaje        DECIMAL(6,4)  NULL
    ,Monto             DECIMAL(12,2) NOT NULL
    ,CONSTRAINT PK_DeduccionSemanal PRIMARY KEY (id)
    ,CONSTRAINT FK_DS_PlanSem       FOREIGN KEY (IdPlanillaSemanal) REFERENCES dbo.PlanillaSemanal(id)
    ,CONSTRAINT FK_DS_TipoDed       FOREIGN KEY (IdTipoDeduccion)   REFERENCES dbo.TipoDeduccion(id)
);

CREATE TABLE dbo.DeduccionMensual (
     id                INT           NOT NULL IDENTITY(1,1)
    ,IdPlanillaMensual INT           NOT NULL
    ,IdTipoDeduccion   INT           NOT NULL
    ,Monto             DECIMAL(12,2) NOT NULL
    ,CONSTRAINT PK_DeduccionMensual PRIMARY KEY (id)
    ,CONSTRAINT FK_DM_PlanMens      FOREIGN KEY (IdPlanillaMensual) REFERENCES dbo.PlanillaMensual(id)
    ,CONSTRAINT FK_DM_TipoDed       FOREIGN KEY (IdTipoDeduccion)   REFERENCES dbo.TipoDeduccion(id)
);

-- ============================================================
-- BITÁCORA Y ERRORES
-- ============================================================

CREATE TABLE dbo.BitacoraEvento (
     id           INT           NOT NULL IDENTITY(1,1)
    ,IdUsuario    INT           NOT NULL
    ,IdTipoEvento INT           NOT NULL
    ,Descripcion  NVARCHAR(MAX) NULL
    ,IpPostIn     VARCHAR(45)   NOT NULL
    ,PostTime     DATETIME      NOT NULL DEFAULT GETDATE()
    ,DatosAntes   NVARCHAR(MAX) NULL
    ,DatosDespues NVARCHAR(MAX) NULL
    ,CONSTRAINT PK_BitacoraEvento PRIMARY KEY (id)
    ,CONSTRAINT FK_BE_Usuario     FOREIGN KEY (IdUsuario)    REFERENCES dbo.Usuario(id)
    ,CONSTRAINT FK_BE_TipoEvento  FOREIGN KEY (IdTipoEvento) REFERENCES dbo.TipoEvento(id)
);

CREATE TABLE dbo.DBErrors (
     id          INT             NOT NULL IDENTITY(1,1)
    ,UserName    VARCHAR(100)    NULL
    ,Number      INT             NOT NULL
    ,State       INT             NOT NULL
    ,Severity    INT             NOT NULL
    ,Line        INT             NOT NULL
    ,[Procedure] VARCHAR(200)    NOT NULL
    ,Message     NVARCHAR(MAX)   NOT NULL
    ,DateTime    DATETIME        NOT NULL DEFAULT GETDATE()
    ,CONSTRAINT PK_DBErrors PRIMARY KEY (id)
);

