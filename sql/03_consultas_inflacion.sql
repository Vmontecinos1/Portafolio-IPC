-- ============================================================
-- Consultas SQL del proyecto: INFLACIÓN EN CHILE (Hito 2)
-- Ciencia de Datos para Economía (ICO09425)
--
-- Este archivo lo ejecuta src/consultas.py. Cada bloque empieza con
-- una línea "-- nombre: xxx" y se llama desde Python por ese nombre.
-- Los parámetros con dos puntos (:corte, :objetivo) los entrega Python.
--
-- Orden (el de la guía):
--   1. revision_base       -> revisar lo que quedó en la base (Etapa 3)
--   2. vista_mensual       -> JOIN + GROUP BY: todo a frecuencia mensual
--   3. vista_cambios       -> funciones de ventana con PARTITION BY
--   4. inflacion           -> variable objetivo, comparada con la meta
--   5. resumen_anual       -> GROUP BY por año
--   6. tabla_coyuntura     -> último dato de cada serie (ROW_NUMBER)
--   7. panel_mensual       -> datos para los gráficos y correlaciones
-- ============================================================


-- nombre: revision_base
-- Una fila por serie: cuántas observaciones tiene y entre qué fechas.
-- n_obs = 0 -> extracción fallida | hasta antiguo -> serie descontinuada
-- desde reciente -> poca historia | tema sin series -> hueco en el catálogo
SELECT t.tema,
       s.nombre,
       s.frecuencia,
       s.unidad,
       COUNT(o.valor) AS n_obs,
       MIN(o.fecha)   AS desde,
       MAX(o.fecha)   AS hasta
FROM temas AS t
LEFT JOIN series AS s        ON s.id_tema  = t.id_tema
LEFT JOIN observaciones AS o ON o.id_serie = s.id_serie
GROUP BY t.tema, s.nombre, s.frecuencia, s.unidad
ORDER BY t.tema, n_obs;


-- nombre: chequeo_integridad
-- Tres controles de calidad de la base (todos deberían dar 0):
--   duplicados: pares (serie, fecha) repetidos
--   huerfanas:  observaciones cuya serie no está en el catálogo
--   valores_demo: TPM o desempleo >= 50%, señal de datos del modo demo
SELECT
    (SELECT COUNT(*) FROM (SELECT id_serie, fecha FROM observaciones
                           GROUP BY id_serie, fecha HAVING COUNT(*) > 1))      AS duplicados,
    (SELECT COUNT(*) FROM observaciones AS o
     LEFT JOIN series AS s ON s.id_serie = o.id_serie
     WHERE s.id_serie IS NULL)                                                 AS huerfanas,
    (SELECT COUNT(*) FROM observaciones
     WHERE id_serie IN ('F022.TPM.TIN.D001.NO.Z.D', 'F049.DES.TAS.INE9.10.M')
       AND valor >= 50)                                                        AS valores_demo;


-- nombre: vista_mensual
-- JOIN + GROUP BY. Lleva TODAS las series a frecuencia mensual:
--   * series diarias (dólar, TPM): promedio de los días del mes
--   * series mensuales: el único dato del mes (el promedio no lo cambia)
-- 'mes' queda como fecha del día 1 (igual que resample('MS') en pandas).
-- n_obs permite detectar meses con pocos días de datos.
DROP VIEW IF EXISTS v_mensual;
CREATE VIEW v_mensual AS
SELECT o.id_serie,
       s.nombre,
       t.tema,
       s.unidad,
       s.frecuencia,
       strftime('%Y-%m-01', o.fecha) AS mes,
       AVG(o.valor)                  AS valor,
       COUNT(*)                      AS n_obs
FROM observaciones AS o
JOIN series AS s ON s.id_serie = o.id_serie
JOIN temas  AS t ON t.id_tema  = s.id_tema
GROUP BY o.id_serie, s.nombre, t.tema, s.unidad, s.frecuencia, mes;


-- nombre: vista_cambios
-- Funciones de ventana sobre las series YA mensuales.
-- PARTITION BY id_serie: cada serie se recorre por separado, así LAG nunca
-- toma un dato de otra serie.
--
-- Transformación según la unidad (ver config.py):
--   * TASA (unidad con '%'): diferencia en puntos porcentuales
--   * NIVEL o ÍNDICE: variación porcentual
--
-- Cuidado con los huecos: LAG(valor, 12) es "12 filas atrás", que solo es
-- "12 meses atrás" si no faltan meses. Por eso se calcula n_mes (número
-- correlativo del mes) y el cambio se deja NULL si la distancia no es la correcta.
-- (Se multiplica por 100.0 y no por 100 para evitar la división entera de SQLite.)
DROP VIEW IF EXISTS v_cambios;
CREATE VIEW v_cambios AS
WITH base AS (
    SELECT m.*,
           CAST(strftime('%Y', m.mes) AS INTEGER) * 12
         + CAST(strftime('%m', m.mes) AS INTEGER)  AS n_mes,
           CASE WHEN instr(m.unidad, '%') > 0 THEN 'tasa' ELSE 'nivel' END AS tipo
    FROM v_mensual AS m
),
rezagos AS (
    SELECT b.*,
           LAG(b.valor, 1)  OVER (PARTITION BY b.id_serie ORDER BY b.mes) AS valor_1m,
           LAG(b.n_mes, 1)  OVER (PARTITION BY b.id_serie ORDER BY b.mes) AS n_mes_1,
           LAG(b.valor, 12) OVER (PARTITION BY b.id_serie ORDER BY b.mes) AS valor_12m,
           LAG(b.n_mes, 12) OVER (PARTITION BY b.id_serie ORDER BY b.mes) AS n_mes_12,
           AVG(b.valor) OVER (PARTITION BY b.id_serie ORDER BY b.mes
                              ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)   AS prom_movil_3m
    FROM base AS b
)
SELECT id_serie, nombre, tema, unidad, tipo, mes, valor, prom_movil_3m,
       CASE WHEN n_mes - n_mes_1 = 1 THEN
            CASE WHEN tipo = 'tasa' THEN valor - valor_1m
                 ELSE 100.0 * (valor / valor_1m - 1) END
       END AS cambio_1m,
       CASE WHEN n_mes - n_mes_12 = 12 THEN
            CASE WHEN tipo = 'tasa' THEN valor - valor_12m
                 ELSE 100.0 * (valor / valor_12m - 1) END
       END AS cambio_12m
FROM rezagos;


-- nombre: inflacion
-- Variable objetivo: inflación a 12 meses calculada desde el índice del IPC.
-- JOIN con la variación mensual OFICIAL para validar nuestro cálculo:
-- 'dif_vs_oficial' debería ser cercana a 0 (solo diferencias de redondeo).
SELECT c.mes,
       c.valor                         AS ipc_indice,
       ROUND(c.cambio_1m, 2)           AS inflacion_mensual,
       ROUND(c.cambio_12m, 2)          AS inflacion_12m,
       ROUND(c.cambio_12m - 3.0, 2)    AS desvio_meta_pp,
       oficial.valor                   AS var_mensual_oficial,
       ROUND(c.cambio_1m - oficial.valor, 2) AS dif_vs_oficial
FROM v_cambios AS c
LEFT JOIN v_mensual AS oficial
       ON oficial.mes = c.mes
      AND oficial.id_serie = 'F074.IPC.VAR.Z.Z.C.M'
WHERE c.id_serie = :objetivo
  AND c.mes <= :corte
ORDER BY c.mes;


-- nombre: resumen_anual
-- GROUP BY por año: cómo se comportó la inflación cada año y cuántos meses
-- estuvo fuera del rango de tolerancia del BCCh (2% - 4%).
SELECT strftime('%Y', mes)                                AS anio,
       ROUND(AVG(cambio_12m), 2)                          AS inflacion_12m_promedio,
       ROUND(MIN(cambio_12m), 2)                          AS minimo,
       ROUND(MAX(cambio_12m), 2)                          AS maximo,
       SUM(CASE WHEN cambio_12m > 4 THEN 1 ELSE 0 END)    AS meses_sobre_4,
       SUM(CASE WHEN cambio_12m < 2 THEN 1 ELSE 0 END)    AS meses_bajo_2,
       COUNT(cambio_12m)                                  AS meses_con_dato
FROM v_cambios
WHERE id_serie = :objetivo
  AND cambio_12m IS NOT NULL
  AND mes <= :corte
GROUP BY anio
ORDER BY anio;


-- nombre: tabla_coyuntura
-- Último dato disponible de cada serie (ROW_NUMBER es otra función de ventana).
-- Muestra también si la serie se está acelerando: cambio 12m hoy vs. hace 3 meses.
WITH ordenado AS (
    SELECT c.*,
           LAG(c.cambio_12m, 3) OVER (PARTITION BY c.id_serie ORDER BY c.mes) AS cambio_12m_hace_3m,
           ROW_NUMBER()         OVER (PARTITION BY c.id_serie ORDER BY c.mes DESC) AS fila
    FROM v_cambios AS c
    WHERE c.mes <= :corte
)
SELECT tema,
       nombre,
       unidad,
       tipo,
       mes                         AS ultimo_mes,
       ROUND(valor, 2)             AS ultimo_valor,
       ROUND(cambio_12m, 2)        AS cambio_12m,
       ROUND(cambio_12m_hace_3m, 2) AS cambio_12m_hace_3m
FROM ordenado
WHERE fila = 1
ORDER BY tema, nombre;


-- nombre: panel_mensual
-- Formato largo (una fila por serie y mes) para graficar y correlacionar.
SELECT id_serie, nombre, tema, unidad, tipo, mes, valor, prom_movil_3m, cambio_1m, cambio_12m
FROM v_cambios
WHERE mes <= :corte
ORDER BY id_serie, mes;
