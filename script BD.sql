
IF DB_ID(N'DW_Olist') IS NULL
    CREATE DATABASE DW_Olist;
GO

USE DW_Olist;
GO

IF SCHEMA_ID(N'dw') IS NULL
    EXEC(N'CREATE SCHEMA dw');
GO

-- DIMENSIÓN FECHA
CREATE TABLE dw.DimFecha (
    SK_Fecha INT PRIMARY KEY,
    Fecha DATE NOT NULL UNIQUE,
    Anio SMALLINT NOT NULL,
    Trimestre TINYINT NOT NULL,
    Mes TINYINT NOT NULL,
    NombreMes NVARCHAR(20) NOT NULL,
    CONSTRAINT CK_DimFecha_Trimestre
        CHECK (Trimestre BETWEEN 1 AND 4),
    CONSTRAINT CK_DimFecha_Mes
        CHECK (Mes BETWEEN 1 AND 12)
);
GO

-- DIMENSIÓN CLIENTE
CREATE TABLE dw.DimCliente (
    SK_Cliente INT IDENTITY(1,1) PRIMARY KEY,
    IdCliente VARCHAR(40) NOT NULL UNIQUE,
    IdClienteUnico VARCHAR(40) NULL,
    Ciudad NVARCHAR(100) NULL,
    Estado CHAR(2) NULL
);
GO

-- DIMENSIÓN PRODUCTO
CREATE TABLE dw.DimProducto (
    SK_Producto INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto VARCHAR(40) NOT NULL UNIQUE,
    Categoria NVARCHAR(120) NULL
);
GO

-- DIMENSIÓN VENDEDOR
CREATE TABLE dw.DimVendedor (
    SK_Vendedor INT IDENTITY(1,1) PRIMARY KEY,
    IdVendedor VARCHAR(40) NOT NULL UNIQUE,
    Ciudad NVARCHAR(100) NULL,
    Estado CHAR(2) NULL
);
GO

-- TABLA DE HECHOS: PEDIDOS
CREATE TABLE dw.FactPedido (
    SK_Pedido BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdPedido VARCHAR(40) NOT NULL UNIQUE,
    SK_Cliente INT NOT NULL,
    SK_Fecha INT NOT NULL,
    EstadoPedido VARCHAR(30) NULL,
    FechaCompra DATETIME2(0) NULL,
    FechaEstimada DATE NULL,
    FechaEntrega DATETIME2(0) NULL,
    EsTardia BIT NULL,
    DiasEntrega DECIMAL(10,4) NULL,
    Calificacion TINYINT NULL,

    CONSTRAINT FK_FactPedido_Cliente
        FOREIGN KEY (SK_Cliente)
        REFERENCES dw.DimCliente(SK_Cliente),

    CONSTRAINT FK_FactPedido_Fecha
        FOREIGN KEY (SK_Fecha)
        REFERENCES dw.DimFecha(SK_Fecha),

    CONSTRAINT CK_FactPedido_Calificacion
        CHECK (Calificacion BETWEEN 1 AND 5)
);
GO

-- TABLA DE HECHOS: ARTÍCULOS DE PEDIDO
CREATE TABLE dw.FactPedidoItem (
    SK_Item BIGINT IDENTITY(1,1) PRIMARY KEY,
    SK_Pedido BIGINT NOT NULL,
    IdPedido VARCHAR(40) NOT NULL,
    NumeroItem SMALLINT NOT NULL,
    SK_Producto INT NULL,
    SK_Vendedor INT NOT NULL,
    Precio DECIMAL(18,2) NOT NULL,
    Flete DECIMAL(18,2) NOT NULL,

    CONSTRAINT UQ_FactPedidoItem
        UNIQUE (IdPedido, NumeroItem),

    CONSTRAINT FK_FactPedidoItem_Pedido
        FOREIGN KEY (SK_Pedido)
        REFERENCES dw.FactPedido(SK_Pedido),

    CONSTRAINT FK_FactPedidoItem_Producto
        FOREIGN KEY (SK_Producto)
        REFERENCES dw.DimProducto(SK_Producto),

    CONSTRAINT FK_FactPedidoItem_Vendedor
        FOREIGN KEY (SK_Vendedor)
        REFERENCES dw.DimVendedor(SK_Vendedor),

    CONSTRAINT CK_FactPedidoItem_Importes
        CHECK (Precio >= 0 AND Flete >= 0)
);
GO

-- ÍNDICES PARA CONSULTAS ANALÍTICAS
CREATE INDEX IX_FactPedido_Fecha
ON dw.FactPedido(SK_Fecha);

CREATE INDEX IX_FactPedido_Cliente
ON dw.FactPedido(SK_Cliente);

CREATE INDEX IX_FactPedidoItem_Pedido
ON dw.FactPedidoItem(SK_Pedido);

CREATE INDEX IX_FactPedidoItem_Producto
ON dw.FactPedidoItem(SK_Producto);

CREATE INDEX IX_FactPedidoItem_Vendedor
ON dw.FactPedidoItem(SK_Vendedor);
GO

-- VERIFICACIÓN DE LAS TABLAS CREADAS
SELECT
    s.name AS Esquema,
    t.name AS Tabla
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name = 'dw'
ORDER BY t.name;
