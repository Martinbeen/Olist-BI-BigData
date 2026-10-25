-- Procedimiento etl.usp_PerfilarStaging ejecutado en DW_Olist.
-- Basado en el código T-SQL compartido y probado por el equipo.
-- La ejecución 4: OK / FilasLeidas = 0 (staging vacío).
USE DW_Olist;
GO

CREATE OR ALTER PROCEDURE etl.usp_PerfilarStaging
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdEjecucion BIGINT;
    DECLARE @TotalFilas BIGINT;

    BEGIN TRY
        INSERT INTO etl.Ejecucion
        (
            FechaInicioUtc, Modo, Estado,
            FilasLeidas, FilasCargadas, FilasRechazadas
        )
        VALUES (SYSUTCDATETIME(), 'T2', 'INICIADA', 0, 0, 0);

        SET @IdEjecucion = CONVERT(BIGINT, SCOPE_IDENTITY());

        DECLARE @Conteos TABLE
        (
            TablaOrigen NVARCHAR(50),
            Filas BIGINT
        );

        INSERT INTO @Conteos
        SELECT 'Customers', COUNT_BIG(*) FROM stg.Customers
        UNION ALL SELECT 'Orders', COUNT_BIG(*) FROM stg.Orders
        UNION ALL SELECT 'OrderItems', COUNT_BIG(*) FROM stg.OrderItems
        UNION ALL SELECT 'OrderPayments', COUNT_BIG(*) FROM stg.OrderPayments
        UNION ALL SELECT 'OrderReviews', COUNT_BIG(*) FROM stg.OrderReviews
        UNION ALL SELECT 'Products', COUNT_BIG(*) FROM stg.Products
        UNION ALL SELECT 'Sellers', COUNT_BIG(*) FROM stg.Sellers
        UNION ALL SELECT 'Geolocation', COUNT_BIG(*) FROM stg.Geolocation
        UNION ALL SELECT 'CategoryTranslation', COUNT_BIG(*) FROM stg.CategoryTranslation;

        SELECT @TotalFilas = SUM(Filas) FROM @Conteos;

        INSERT INTO etl.Calidad
            (IdEjecucion, TablaOrigen, Regla, ValorAntes,
             ValorDespues, FechaRegistroUtc)
        SELECT @IdEjecucion, TablaOrigen, 'FILAS_STAGING',
               Filas, NULL, SYSUTCDATETIME()
        FROM @Conteos;

        INSERT INTO etl.Calidad
            (IdEjecucion, TablaOrigen, Regla, ValorAntes,
             ValorDespues, FechaRegistroUtc)
        SELECT @IdEjecucion, 'Orders', 'CLAVE_NULA',
               COUNT_BIG(*), NULL, SYSUTCDATETIME()
        FROM stg.Orders
        WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL;

        INSERT INTO etl.Calidad
            (IdEjecucion, TablaOrigen, Regla, ValorAntes,
             ValorDespues, FechaRegistroUtc)
        SELECT @IdEjecucion, 'Orders', 'DUPLICADOS',
               COALESCE(SUM(Repeticiones - 1), 0), NULL,
               SYSUTCDATETIME()
        FROM
        (
            SELECT COUNT_BIG(*) AS Repeticiones
            FROM stg.Orders
            WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NOT NULL
            GROUP BY order_id
            HAVING COUNT_BIG(*) > 1
        ) AS D;

        UPDATE etl.Ejecucion
        SET FechaFinUtc = SYSUTCDATETIME(),
            Estado = 'OK',
            FilasLeidas = @TotalFilas,
            FilasCargadas = 0,
            FilasRechazadas = 0,
            Mensaje = CASE
                WHEN @TotalFilas = 0 THEN 'Staging sin datos para perfilar'
                ELSE 'Perfilado de Staging completado'
            END
        WHERE IdEjecucion = @IdEjecucion;

        SELECT @IdEjecucion AS IdEjecucion,
               @TotalFilas AS TotalFilas;
    END TRY
    BEGIN CATCH
        IF @IdEjecucion IS NOT NULL
        BEGIN
            UPDATE etl.Ejecucion
            SET FechaFinUtc = SYSUTCDATETIME(),
                Estado = 'ERROR',
                Mensaje = ERROR_MESSAGE()
            WHERE IdEjecucion = @IdEjecucion;
        END;
        THROW;
    END CATCH
END;
GO
