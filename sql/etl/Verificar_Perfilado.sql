USE DW_Olist;
GO

-- Este script ejecuta un nuevo perfilado. No carga CSV ni transforma datos.
EXEC etl.usp_PerfilarStaging;
GO

SELECT TOP (3) IdEjecucion, Modo, Estado, FilasLeidas,
               FilasCargadas, FilasRechazadas, Mensaje
FROM etl.Ejecucion
ORDER BY IdEjecucion DESC;

SELECT c.IdEjecucion, c.TablaOrigen, c.Regla, c.ValorAntes, c.ValorDespues
FROM etl.Calidad AS c
WHERE c.IdEjecucion = (SELECT MAX(IdEjecucion) FROM etl.Ejecucion)
ORDER BY c.IdCalidad;
