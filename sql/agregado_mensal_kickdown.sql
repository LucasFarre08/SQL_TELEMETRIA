SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

-- =====================================================
-- TABELA AGREGADA MENSAL DE KICKDOWN
-- =====================================================

CREATE TABLE IF NOT EXISTS agregado_mensal_kickdown (
    grouping_id VARCHAR(64) NOT NULL,

    mes_ano DATE NOT NULL,

    quantidade_eventos INT DEFAULT 0,

    duracao TIME DEFAULT '00:00:00',

    duracao_int DECIMAL(14,2) DEFAULT 0,

    grouping_mes_ano VARCHAR(100) NOT NULL,

    PRIMARY KEY (grouping_id, mes_ano)
) ENGINE=InnoDB;


-- =====================================================
-- TABELA TEMPORÁRIA
-- =====================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_kickdown;

CREATE TEMPORARY TABLE tmp_agregado_kickdown (
    grouping_id VARCHAR(64) NOT NULL,

    mes_ano DATE NOT NULL,

    quantidade_eventos INT DEFAULT 0,

    duracao TIME DEFAULT '00:00:00',

    duracao_int DECIMAL(14,2) DEFAULT 0,

    grouping_mes_ano VARCHAR(100) NOT NULL,

    PRIMARY KEY (grouping_id, mes_ano)
) ENGINE=InnoDB;


-- =====================================================
-- AGRUPAMENTO DOS EVENTOS
-- =====================================================

INSERT INTO tmp_agregado_kickdown (
    grouping_id,
    mes_ano,
    quantidade_eventos,
    duracao,
    duracao_int,
    grouping_mes_ano
)

SELECT
    base.grouping_id,

    base.mes_ano,

    COUNT(*) AS quantidade_eventos,

    SEC_TO_TIME(
        SUM(
            TIME_TO_SEC(
                IFNULL(base.duracao, '00:00:00')
            )
        )
    ) AS duracao,

    ROUND(
        SUM(
            TIME_TO_SEC(
                IFNULL(base.duracao, '00:00:00')
            )
        ) / 3600,
        2
    ) AS duracao_int,

    CONCAT(
        base.grouping_id,
        DATE_FORMAT(base.mes_ano, '%Y%m')
    ) AS grouping_mes_ano

FROM (

    SELECT
        REPLACE(
            REPLACE(
                TRIM(UPPER(k.`grouping`)),
                '.',
                ''
            ),
            '-',
            ''
        ) AS grouping_id,

        STR_TO_DATE(
            DATE_FORMAT(k.ativado, '%Y-%m-01'),
            '%Y-%m-%d'
        ) AS mes_ano,

        k.duracao

    FROM kickdown k

    WHERE k.ativado IS NOT NULL
      AND TRIM(k.`grouping`) <> ''

) base

GROUP BY
    base.grouping_id,
    base.mes_ano;


-- =====================================================
-- ATUALIZA REGISTROS EXISTENTES
-- =====================================================

UPDATE agregado_mensal_kickdown a

JOIN tmp_agregado_kickdown t
    ON a.grouping_id = t.grouping_id
    AND a.mes_ano = t.mes_ano

SET
    a.quantidade_eventos = t.quantidade_eventos,
    a.duracao = t.duracao,
    a.duracao_int = t.duracao_int,
    a.grouping_mes_ano = t.grouping_mes_ano;


-- =====================================================
-- INSERE NOVOS REGISTROS
-- =====================================================

INSERT INTO agregado_mensal_kickdown (
    grouping_id,
    mes_ano,
    quantidade_eventos,
    duracao,
    duracao_int,
    grouping_mes_ano
)

SELECT
    t.grouping_id,
    t.mes_ano,
    t.quantidade_eventos,
    t.duracao,
    t.duracao_int,
    t.grouping_mes_ano

FROM tmp_agregado_kickdown t

LEFT JOIN agregado_mensal_kickdown a
    ON a.grouping_id = t.grouping_id
    AND a.mes_ano = t.mes_ano

WHERE a.grouping_id IS NULL;


-- =====================================================
-- LIMPEZA
-- =====================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_kickdown;

COMMIT;