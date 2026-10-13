
USE telemetria_maersk;

SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS tmp_agregado;

CREATE TABLE IF NOT EXISTS agregado_mensal (
    grouping_id VARCHAR(64) NOT NULL,
    ano_mes DATE NOT NULL,
    grouping_ano_mes VARCHAR(80) NOT NULL,
    km_total DECIMAL(14,2) DEFAULT 0,
    litros_total DECIMAL(14,2) DEFAULT 0,
    duracao TIME DEFAULT '00:00:00',
    duracao_int DECIMAL(14,2) DEFAULT 0,
    emissoes_de_co2 FLOAT DEFAULT NULL,
    velocidade_max FLOAT DEFAULT NULL,
    velocidade_media FLOAT DEFAULT NULL,
    PRIMARY KEY (grouping_id, ano_mes)
) ENGINE=InnoDB;

CREATE TEMPORARY TABLE tmp_agregado (
    grouping_id VARCHAR(64) NOT NULL,
    ano_mes DATE NOT NULL,
    grouping_ano_mes VARCHAR(80) NOT NULL,
    km_total DECIMAL(14,2) DEFAULT 0,
    litros_total DECIMAL(14,2) DEFAULT 0,
    duracao TIME DEFAULT '00:00:00',
    duracao_int DECIMAL(14,2) DEFAULT 0,
    emissoes_de_co2 DECIMAL(16,4) DEFAULT 0,
    velocidade_max DECIMAL(10,2) DEFAULT 0,
    velocidade_media DECIMAL(10,2) DEFAULT 0,
    PRIMARY KEY (grouping_id, ano_mes)
) ENGINE=InnoDB;

INSERT INTO tmp_agregado (
    grouping_id,
    ano_mes,
    grouping_ano_mes,
    km_total,
    litros_total,
    duracao,
    duracao_int,
    emissoes_de_co2,
    velocidade_max,
    velocidade_media
)
SELECT
    d.grouping_id,
    d.ano_mes,
    CONCAT(d.grouping_id, DATE_FORMAT(d.ano_mes, '%Y%m')),
    ROUND(SUM(IFNULL(d.quilometragem, 0)), 2),
    ROUND(SUM(IFNULL(d.litros_consumidos, 0)), 2),
    SEC_TO_TIME(
        SUM(TIME_TO_SEC(IFNULL(d.duracao, '00:00:00')))
    ),
    ROUND(
        SUM(TIME_TO_SEC(IFNULL(d.duracao, '00:00:00'))) / 3600,
        2
    ),
    ROUND(SUM(
        CASE
            WHEN TRIM(d.emissoes_de_co2)
                 REGEXP '^[0-9]+([.,][0-9]+)?$'
            THEN CAST(
                REPLACE(TRIM(d.emissoes_de_co2), ',', '.')
                AS DECIMAL(20,6)
            )
            ELSE 0
        END
    ), 4),
    ROUND(MAX(IFNULL(d.velocidade_media, 0)), 2),
    ROUND(AVG(d.velocidade_media), 2)
FROM (
    SELECT
        REPLACE(
            REPLACE(TRIM(UPPER(`grouping`)), '.', ''),
            '-', ''
        ) AS grouping_id,
        CAST(DATE_FORMAT(inicio, '%Y-%m-01') AS DATE) AS ano_mes,
        quilometragem,
        litros_consumidos,
        duracao,
        emissoes_de_co2,
        velocidade_media
    FROM viagens
    WHERE inicio IS NOT NULL
      AND `grouping` IS NOT NULL
      AND TRIM(`grouping`) <> ''
) AS d
GROUP BY d.grouping_id, d.ano_mes;

UPDATE agregado_mensal a
JOIN tmp_agregado t
  ON a.grouping_id = t.grouping_id
 AND a.ano_mes = t.ano_mes
SET
    a.grouping_ano_mes = t.grouping_ano_mes,
    a.km_total = t.km_total,
    a.litros_total = t.litros_total,
    a.duracao = t.duracao,
    a.duracao_int = t.duracao_int,
    a.emissoes_de_co2 = t.emissoes_de_co2,
    a.velocidade_max = t.velocidade_max,
    a.velocidade_media = t.velocidade_media;

INSERT INTO agregado_mensal (
    grouping_id,
    ano_mes,
    grouping_ano_mes,
    km_total,
    litros_total,
    duracao,
    duracao_int,
    emissoes_de_co2,
    velocidade_max,
    velocidade_media
)
SELECT
    t.grouping_id,
    t.ano_mes,
    t.grouping_ano_mes,
    t.km_total,
    t.litros_total,
    t.duracao,
    t.duracao_int,
    t.emissoes_de_co2,
    t.velocidade_max,
    t.velocidade_media
FROM tmp_agregado t
WHERE NOT EXISTS (
    SELECT 1
    FROM agregado_mensal a
    WHERE a.grouping_id = t.grouping_id
      AND a.ano_mes = t.ano_mes
);

DROP TEMPORARY TABLE IF EXISTS tmp_agregado;

COMMIT;

SELECT
    COUNT(*) AS total_registros,
    MAX(ano_mes) AS mes_mais_recente
FROM agregado_mensal;
