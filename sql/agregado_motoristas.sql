SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS tmp_motoristas;

CREATE TEMPORARY TABLE tmp_motoristas AS
SELECT
    TRIM(UPPER(motorista)) AS motoristas_id,
    GROUP_CONCAT(
        DISTINCT TRIM(UPPER(`grouping`))
        ORDER BY `grouping`
        SEPARATOR ', '
    ) AS placas,
    DATE_FORMAT(inicio, '%Y-%m-01') AS ano_mes,
    ROUND(SUM(IFNULL(quilometragem,0)),2) AS km_total,
    ROUND(SUM(IFNULL(litros_consumidos,0)),2) AS litros_total
FROM viagens
WHERE inicio IS NOT NULL
  AND TRIM(IFNULL(motorista,'')) <> ''
GROUP BY
    TRIM(UPPER(motorista)),
    DATE_FORMAT(inicio, '%Y-%m-01');

CREATE TABLE IF NOT EXISTS agrupado_motoristas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    motoristas_id VARCHAR(255) NOT NULL,
    placas TEXT,
    ano_mes VARCHAR(10) NOT NULL,
    km_total DECIMAL(10,2) DEFAULT 0,
    litros_total DECIMAL(10,2) DEFAULT 0,
    UNIQUE KEY uq_motorista_mes (motoristas_id, ano_mes)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE agrupado_motoristas
CONVERT TO CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

UPDATE agrupado_motoristas a
JOIN tmp_motoristas t
ON a.motoristas_id = t.motoristas_id
AND a.ano_mes = t.ano_mes
SET
    a.placas = t.placas,
    a.km_total = t.km_total,
    a.litros_total = t.litros_total;

INSERT INTO agrupado_motoristas (
    motoristas_id,
    placas,
    ano_mes,
    km_total,
    litros_total
)
SELECT
    t.motoristas_id,
    t.placas,
    t.ano_mes,
    t.km_total,
    t.litros_total
FROM tmp_motoristas t
LEFT JOIN agrupado_motoristas a
ON a.motoristas_id = t.motoristas_id
AND a.ano_mes = t.ano_mes
WHERE a.motoristas_id IS NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_motoristas;

COMMIT;