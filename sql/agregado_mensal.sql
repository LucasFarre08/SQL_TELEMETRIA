START TRANSACTION;

SET SQL_SAFE_UPDATES = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_agregado;

-- =========================================================
-- 1. CRIA A TABELA
-- =========================================================

CREATE TABLE IF NOT EXISTS agregado_mensal (
    grouping_id VARCHAR(64) NOT NULL,
    ano_mes DATE NOT NULL,

    grouping_ano_mes VARCHAR(80) GENERATED ALWAYS AS (
        CONCAT(
            grouping_id,
            
            DATE_FORMAT(ano_mes, '%Y%m')
        )
    ) STORED,

    km_total DECIMAL(14,2) DEFAULT 0,
    litros_total DECIMAL(14,2) DEFAULT 0,
    duracao TIME DEFAULT '00:00:00',
    duracao_int DECIMAL(14,2) DEFAULT 0,

    PRIMARY KEY (grouping_id, ano_mes)
) ENGINE=InnoDB;


-- =========================================================
-- 2. TABELA TEMPORÁRIA
-- =========================================================

CREATE TEMPORARY TABLE tmp_agregado (
    grouping_id VARCHAR(64) NOT NULL,
    ano_mes DATE NOT NULL,
    km_total DECIMAL(14,2) DEFAULT 0,
    litros_total DECIMAL(14,2) DEFAULT 0,
    duracao TIME DEFAULT '00:00:00',
    duracao_int DECIMAL(14,2) DEFAULT 0,

    PRIMARY KEY (grouping_id, ano_mes)
) ENGINE=InnoDB;


-- =========================================================
-- 3. AGREGA OS DADOS DA TABELA VIAGENS
-- =========================================================

INSERT INTO tmp_agregado (
    grouping_id,
    ano_mes,
    km_total,
    litros_total,
    duracao,
    duracao_int
)

SELECT

    REPLACE(
        REPLACE(
            TRIM(UPPER(`grouping`)),
            '.', ''
        ),
        '-', ''
    ) AS grouping_id,

    CAST(
        DATE_FORMAT(inicio, '%Y-%m-01')
        AS DATE
    ) AS ano_mes,

    ROUND(
        SUM(IFNULL(quilometragem, 0)),
        2
    ) AS km_total,

    ROUND(
        SUM(IFNULL(litros_consumidos, 0)),
        2
    ) AS litros_total,

    SEC_TO_TIME(
        SUM(
            TIME_TO_SEC(
                IFNULL(duracao, '00:00:00')
            )
        )
    ) AS duracao,

    ROUND(
        SUM(
            TIME_TO_SEC(
                IFNULL(duracao, '00:00:00')
            )
        ) / 3600,
        2
    ) AS duracao_int

FROM viagens

WHERE inicio IS NOT NULL
  AND TRIM(`grouping`) <> ''

GROUP BY

    REPLACE(
        REPLACE(
            TRIM(UPPER(`grouping`)),
            '.', ''
        ),
        '-', ''
    ),

    CAST(
        DATE_FORMAT(inicio, '%Y-%m-01')
        AS DATE
    );


-- =========================================================
-- 4. ATUALIZA REGISTROS EXISTENTES
-- =========================================================

UPDATE agregado_mensal a

JOIN tmp_agregado t
    ON a.grouping_id = t.grouping_id
   AND a.ano_mes = t.ano_mes

SET

    a.km_total = t.km_total,
    a.litros_total = t.litros_total,
    a.duracao = t.duracao,
    a.duracao_int = t.duracao_int;


-- =========================================================
-- 5. INSERE NOVOS REGISTROS
-- =========================================================

INSERT INTO agregado_mensal (
    grouping_id,
    ano_mes,
    km_total,
    litros_total,
    duracao,
    duracao_int
)

SELECT

    t.grouping_id,
    t.ano_mes,
    t.km_total,
    t.litros_total,
    t.duracao,
    t.duracao_int

FROM tmp_agregado t

LEFT JOIN agregado_mensal a

    ON a.grouping_id = t.grouping_id
   AND a.ano_mes = t.ano_mes

WHERE a.grouping_id IS NULL;


-- =========================================================
-- 6. REMOVE TEMPORÁRIA
-- =========================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado;

COMMIT;


-- =========================================================
-- 7. CONFERÊNCIA
-- =========================================================

SELECT
    grouping_id,
    ano_mes,
    grouping_ano_mes,
    km_total,
    litros_total,
    duracao,
    duracao_int
FROM agregado_mensal
ORDER BY ano_mes DESC, grouping_id;
