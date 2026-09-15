START TRANSACTION;

SET SQL_SAFE_UPDATES = 0;

USE telemetria_west;


-- =====================================================
-- REMOVE TABELA TEMPORÁRIA
-- =====================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_semanal;


-- =====================================================
-- TABELA FINAL
-- =====================================================

CREATE TABLE IF NOT EXISTS agregado_semanal (

    grouping_id VARCHAR(64) NOT NULL,

    ano_mes DATE NOT NULL,

    semana INT NOT NULL,

    grouping_semanal_ VARCHAR(100) NOT NULL,

    km_total DECIMAL(14,2) DEFAULT 0,

    litros_total DECIMAL(14,2) DEFAULT 0,

    duracao TIME DEFAULT '00:00:00',

    duracao_int DECIMAL(14,2) DEFAULT 0,


    PRIMARY KEY (
        grouping_id,
        ano_mes,
        semana
    ),

    INDEX idx_grouping_semanal_ (
        grouping_semanal_
    )

) ENGINE=InnoDB;


-- =====================================================
-- TABELA TEMPORÁRIA
-- =====================================================

CREATE TEMPORARY TABLE tmp_agregado_semanal (

    grouping_id VARCHAR(64) NOT NULL,

    ano_mes DATE NOT NULL,

    semana INT NOT NULL,

    grouping_semanal_ VARCHAR(100) NOT NULL,

    km_total DECIMAL(14,2) DEFAULT 0,

    litros_total DECIMAL(14,2) DEFAULT 0,

    duracao TIME DEFAULT '00:00:00',

    duracao_int DECIMAL(14,2) DEFAULT 0,


    PRIMARY KEY (
        grouping_id,
        ano_mes,
        semana
    )

) ENGINE=InnoDB;


-- =====================================================
-- AGRUPAMENTO SEMANAL
-- =====================================================

INSERT INTO tmp_agregado_semanal (

    grouping_id,
    ano_mes,
    semana,
    grouping_semanal_,
    km_total,
    litros_total,
    duracao,
    duracao_int

)


SELECT

    x.grouping_id,

    x.ano_mes,

    x.semana,


    -- ================================================
    -- CHAVE SEMANAL
    --
    -- EXEMPLO:
    -- FDX466_202609_S2
    -- ================================================

    CONCAT(
        x.grouping_id,
        '_',
        DATE_FORMAT(x.ano_mes, '%Y%m'),
        '_S',
        x.semana
    ) AS grouping_semanal_,


    x.km_total,

    x.litros_total,

    x.duracao,

    x.duracao_int


FROM (

    SELECT


        -- =============================================
        -- GROUPING NORMALIZADO
        -- =============================================

        REPLACE(
            REPLACE(
                TRIM(UPPER(`grouping`)),
                '.',
                ''
            ),
            '-',
            ''
        ) AS grouping_id,


        -- =============================================
        -- MÊS E ANO
        -- =============================================

        DATE(
            DATE_FORMAT(
                inicio,
                '%Y-%m-01'
            )
        ) AS ano_mes,


        -- =============================================
        -- SEMANA DO MÊS
        --
        -- 01 a 07 = Semana 1
        -- 08 a 14 = Semana 2
        -- 15 a 21 = Semana 3
        -- 22 a 28 = Semana 4
        -- 29 a 31 = Semana 5
        -- =============================================

        CEILING(
            DAY(inicio) / 7
        ) AS semana,


        -- =============================================
        -- KM TOTAL
        -- =============================================

        ROUND(
            SUM(
                IFNULL(quilometragem, 0)
            ),
            2
        ) AS km_total,


        -- =============================================
        -- LITROS TOTAL
        -- =============================================

        ROUND(
            SUM(
                IFNULL(litros_consumidos, 0)
            ),
            2
        ) AS litros_total,


        -- =============================================
        -- DURAÇÃO
        -- =============================================

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


        -- =============================================
        -- DURAÇÃO EM HORAS
        -- =============================================

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

    AND TRIM(IFNULL(`grouping`, '')) <> ''


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

        DATE(
            DATE_FORMAT(
                inicio,
                '%Y-%m-01'
            )
        ),

        CEILING(
            DAY(inicio) / 7
        )


) AS x;



-- =====================================================
-- ATUALIZA REGISTROS EXISTENTES
-- =====================================================

UPDATE agregado_semanal AS a

JOIN tmp_agregado_semanal AS t

ON a.grouping_id = t.grouping_id

AND a.ano_mes = t.ano_mes

AND a.semana = t.semana


SET

    a.grouping_semanal_ =
        t.grouping_semanal_,

    a.km_total =
        t.km_total,

    a.litros_total =
        t.litros_total,

    a.duracao =
        t.duracao,

    a.duracao_int =
        t.duracao_int;



-- =====================================================
-- INSERE NOVOS REGISTROS
-- =====================================================

INSERT INTO agregado_semanal (

    grouping_id,
    ano_mes,
    semana,
    grouping_semanal_,
    km_total,
    litros_total,
    duracao,
    duracao_int

)


SELECT

    t.grouping_id,

    t.ano_mes,

    t.semana,

    t.grouping_semanal_,

    t.km_total,

    t.litros_total,

    t.duracao,

    t.duracao_int


FROM tmp_agregado_semanal AS t


LEFT JOIN agregado_semanal AS a

ON a.grouping_id = t.grouping_id

AND a.ano_mes = t.ano_mes

AND a.semana = t.semana


WHERE a.grouping_id IS NULL;



-- =====================================================
-- LIMPEZA
-- =====================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_semanal;


COMMIT;