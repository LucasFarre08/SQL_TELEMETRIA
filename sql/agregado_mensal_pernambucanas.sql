START TRANSACTION;

USE telemetria_pernambucanas;

SET SQL_SAFE_UPDATES = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_agregado;


-- =========================================================
-- 1. CRIA A TABELA AGREGADO MENSAL
-- =========================================================

CREATE TABLE IF NOT EXISTS agregado_mensal (
    grouping_id VARCHAR(64) NOT NULL,
    ano_mes DATE NOT NULL,

    grouping_ano_mes VARCHAR(80)
        GENERATED ALWAYS AS (
            CONCAT(
                grouping_id,
                '_',
                DATE_FORMAT(ano_mes, '%Y%m')
            )
        ) STORED,

    km_total DECIMAL(14,2) DEFAULT 0,

    litros_total DECIMAL(14,2) DEFAULT 0,

    duracao TIME DEFAULT '00:00:00',

    duracao_int DECIMAL(14,2) DEFAULT 0,

    km_l DECIMAL(10,2) DEFAULT 0,

    dentro_media VARCHAR(20) DEFAULT 'SEM DADOS',

    PRIMARY KEY (grouping_id, ano_mes)

) ENGINE=InnoDB;


-- =========================================================
-- 2. CASO A TABELA JÁ EXISTIA SEM AS NOVAS COLUNAS
-- =========================================================

-- Adiciona km_l caso ainda não exista
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE agregado_mensal ADD COLUMN km_l DECIMAL(10,2) DEFAULT 0',
        'SELECT 1'
    )
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'agregado_mensal'
      AND column_name = 'km_l'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- Adiciona dentro_media caso ainda não exista
SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE agregado_mensal ADD COLUMN dentro_media VARCHAR(20) DEFAULT ''SEM DADOS''',
        'SELECT 1'
    )
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'agregado_mensal'
      AND column_name = 'dentro_media'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- =========================================================
-- 3. CASO A TABELA JÁ EXISTIA SEM grouping_ano_mes
-- =========================================================

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE agregado_mensal ADD COLUMN grouping_ano_mes VARCHAR(80) GENERATED ALWAYS AS (CONCAT(grouping_id, ''_'', DATE_FORMAT(ano_mes, ''%Y%m''))) STORED',
        'SELECT 1'
    )
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'agregado_mensal'
      AND column_name = 'grouping_ano_mes'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- =========================================================
-- 4. CRIA TABELA TEMPORÁRIA
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
-- 5. AGREGA OS DADOS DA TABELA VIAGENS
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
            '.',
            ''
        ),
        '-',
        ''
    ) AS grouping_id,

    CAST(
        DATE_FORMAT(inicio, '%Y-%m-01')
        AS DATE
    ) AS ano_mes,

    ROUND(
        SUM(
            IFNULL(quilometragem, 0)
        ),
        2
    ) AS km_total,

    ROUND(
        SUM(
            IFNULL(litros_consumidos, 0)
        ),
        2
    ) AS litros_total,

    SEC_TO_TIME(
        SUM(
            TIME_TO_SEC(
                IFNULL(
                    duracao,
                    '00:00:00'
                )
            )
        )
    ) AS duracao,

    ROUND(
        SUM(
            TIME_TO_SEC(
                IFNULL(
                    duracao,
                    '00:00:00'
                )
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
            '.',
            ''
        ),
        '-',
        ''
    ),

    CAST(
        DATE_FORMAT(inicio, '%Y-%m-01')
        AS DATE
    );


-- =========================================================
-- 6. ATUALIZA REGISTROS EXISTENTES
-- =========================================================

UPDATE agregado_mensal a

JOIN tmp_agregado t

    ON a.grouping_id = t.grouping_id

   AND a.ano_mes = t.ano_mes

SET

    a.km_total = t.km_total,

    a.litros_total = t.litros_total,

    a.duracao = t.duracao,

    a.duracao_int = t.duracao_int,

    a.km_l = CASE

        WHEN t.litros_total > 0

        THEN ROUND(
            t.km_total / t.litros_total,
            2
        )

        ELSE 0

    END,

    a.dentro_media = CASE

        WHEN t.litros_total <= 0

            THEN 'SEM DADOS'

        WHEN (
            t.km_total / t.litros_total
        ) > 4.25

            THEN 'ACIMA DA MEDIA'

        WHEN (
            t.km_total / t.litros_total
        ) < 4.25

            THEN 'ABAIXO DA MEDIA'

        ELSE 'DENTRO DA MEDIA'

    END;


-- =========================================================
-- 7. INSERE NOVOS REGISTROS
-- =========================================================

INSERT INTO agregado_mensal (

    grouping_id,

    ano_mes,

    km_total,

    litros_total,

    duracao,

    duracao_int,

    km_l,

    dentro_media

)

SELECT

    t.grouping_id,

    t.ano_mes,

    t.km_total,

    t.litros_total,

    t.duracao,

    t.duracao_int,


    -- KM POR LITRO
    CASE

        WHEN t.litros_total > 0

        THEN ROUND(
            t.km_total / t.litros_total,
            2
        )

        ELSE 0

    END AS km_l,


    -- COMPARAÇÃO COM A MÉDIA DE 4,25 KM/L
    CASE

        WHEN t.litros_total <= 0

            THEN 'SEM DADOS'

        WHEN (
            t.km_total / t.litros_total
        ) > 4.25

            THEN 'ACIMA DA MEDIA'

        WHEN (
            t.km_total / t.litros_total
        ) < 4.25

            THEN 'ABAIXO DA MEDIA'

        ELSE 'DENTRO DA MEDIA'

    END AS dentro_media


FROM tmp_agregado t

LEFT JOIN agregado_mensal a

    ON a.grouping_id = t.grouping_id

   AND a.ano_mes = t.ano_mes

WHERE a.grouping_id IS NULL;


-- =========================================================
-- 8. REMOVE TABELA TEMPORÁRIA
-- =========================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado;


-- =========================================================
-- 9. FINALIZA TRANSAÇÃO
-- =========================================================

COMMIT;


-- =========================================================
-- 10. CONFERÊNCIA DOS RESULTADOS
-- =========================================================

SELECT

    grouping_id,

    ano_mes,

    grouping_ano_mes,

    km_total,

    litros_total,

    km_l,

    dentro_media,

    duracao,

    duracao_int

FROM agregado_mensal

ORDER BY
    ano_mes DESC,
    grouping_id;