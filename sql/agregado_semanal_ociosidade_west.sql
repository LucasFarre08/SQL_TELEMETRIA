SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

USE telemetria_west;


-- =====================================================
-- TABELA FINAL
-- =====================================================

CREATE TABLE IF NOT EXISTS agregado_semanal_ociosidade (

    grouping_id VARCHAR(64) NOT NULL,

    ano_mes DATE NOT NULL,

    semana INT NOT NULL,

    grouping_semana_ano_mes VARCHAR(100) NOT NULL,

    duracao TIME NOT NULL,

    duracao_int DECIMAL(14,2) DEFAULT 0,

    litros_gasto DECIMAL(14,2) DEFAULT 0,


    PRIMARY KEY (
        grouping_id,
        ano_mes,
        semana
    ),


    INDEX idx_grouping_semana_ano_mes (
        grouping_semana_ano_mes
    )

) ENGINE=InnoDB;


-- =====================================================
-- REMOVE TABELA TEMPORÁRIA ANTERIOR
-- =====================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_semanal_ociosidade;


-- =====================================================
-- TABELA TEMPORÁRIA
-- =====================================================

CREATE TEMPORARY TABLE tmp_agregado_semanal_ociosidade (

    grouping_id VARCHAR(64) NOT NULL,

    ano_mes DATE NOT NULL,

    semana INT NOT NULL,

    grouping_semana_ano_mes VARCHAR(100) NOT NULL,

    duracao TIME NOT NULL,

    duracao_int DECIMAL(14,2) DEFAULT 0,

    litros_gasto DECIMAL(14,2) DEFAULT 0,


    PRIMARY KEY (
        grouping_id,
        ano_mes,
        semana
    )

) ENGINE=InnoDB;


-- =====================================================
-- INSERE DADOS AGRUPADOS SEMANALMENTE
-- =====================================================

INSERT INTO tmp_agregado_semanal_ociosidade (

    grouping_id,
    ano_mes,
    semana,
    grouping_semana_ano_mes,
    duracao,
    duracao_int,
    litros_gasto

)


-- =====================================================
-- SELECT FINAL
-- =====================================================

SELECT

    x.grouping_id,

    x.ano_mes,

    x.semana,


    -- ================================================
    -- CHAVE:
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
    ) AS grouping_semana_ano_mes,


    x.duracao,

    x.duracao_int,

    x.litros_gasto


FROM (

    -- =================================================
    -- SUBCONSULTA PARA AGRUPAMENTO
    -- =================================================

    SELECT


        -- =============================================
        -- GROUPING NORMALIZADO
        -- =============================================

        REPLACE(
            REPLACE(
                TRIM(
                    UPPER(`grouping`)
                ),
                '.',
                ''
            ),
            '-',
            ''
        ) AS grouping_id,


        -- =============================================
        -- ANO E MÊS
        --
        -- EXEMPLO:
        -- 2026-09-01
        -- =============================================

        DATE(
            DATE_FORMAT(
                ativado,
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
            DAY(ativado) / 7
        ) AS semana,


        -- =============================================
        -- DURAÇÃO TOTAL
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
        -- DURAÇÃO EM HORAS DECIMAIS
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

        ) AS duracao_int,


        -- =============================================
        -- LITROS GASTOS
        -- =============================================

        ROUND(

            SUM(

                IFNULL(
                    combustivel_gasto,
                    0
                )

            ),

            2

        ) AS litros_gasto


    FROM ociosidade


    -- =============================================
    -- FILTROS
    -- =============================================

    WHERE ativado IS NOT NULL

    AND TRIM(
        IFNULL(`grouping`, '')
    ) <> ''


    -- =============================================
    -- AGRUPAMENTO
    -- =============================================

    GROUP BY


        -- GROUPING

        REPLACE(
            REPLACE(
                TRIM(
                    UPPER(`grouping`)
                ),
                '.',
                ''
            ),
            '-',
            ''
        ),


        -- ANO / MÊS

        DATE(
            DATE_FORMAT(
                ativado,
                '%Y-%m-01'
            )
        ),


        -- SEMANA

        CEILING(
            DAY(ativado) / 7
        )


) AS x;



-- =====================================================
-- ATUALIZA REGISTROS EXISTENTES
-- =====================================================

UPDATE agregado_semanal_ociosidade AS a

JOIN tmp_agregado_semanal_ociosidade AS t

ON a.grouping_id = t.grouping_id

AND a.ano_mes = t.ano_mes

AND a.semana = t.semana


SET

    a.grouping_semana_ano_mes =
        t.grouping_semana_ano_mes,

    a.duracao =
        t.duracao,

    a.duracao_int =
        t.duracao_int,

    a.litros_gasto =
        t.litros_gasto;



-- =====================================================
-- INSERE REGISTROS NOVOS
-- =====================================================

INSERT INTO agregado_semanal_ociosidade (

    grouping_id,

    ano_mes,

    semana,

    grouping_semana_ano_mes,

    duracao,

    duracao_int,

    litros_gasto

)


SELECT

    t.grouping_id,

    t.ano_mes,

    t.semana,

    t.grouping_semana_ano_mes,

    t.duracao,

    t.duracao_int,

    t.litros_gasto


FROM tmp_agregado_semanal_ociosidade AS t


LEFT JOIN agregado_semanal_ociosidade AS a

ON a.grouping_id = t.grouping_id

AND a.ano_mes = t.ano_mes

AND a.semana = t.semana


WHERE a.grouping_id IS NULL;



-- =====================================================
-- REMOVE TABELA TEMPORÁRIA
-- =====================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_semanal_ociosidade;


-- =====================================================
-- FINALIZA TRANSAÇÃO
-- =====================================================

COMMIT;SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

USE telemetria_west;


-- =====================================================
-- TABELA FINAL
-- =====================================================

CREATE TABLE IF NOT EXISTS agregado_semanal_ociosidade (

    grouping_id VARCHAR(64) NOT NULL,

    ano_mes DATE NOT NULL,

    semana INT NOT NULL,

    grouping_semana_ano_mes VARCHAR(100) NOT NULL,

    duracao TIME NOT NULL,

    duracao_int DECIMAL(14,2) DEFAULT 0,

    litros_gasto DECIMAL(14,2) DEFAULT 0,


    PRIMARY KEY (
        grouping_id,
        ano_mes,
        semana
    ),


    INDEX idx_grouping_semana_ano_mes (
        grouping_semana_ano_mes
    )

) ENGINE=InnoDB;


-- =====================================================
-- REMOVE TABELA TEMPORÁRIA ANTERIOR
-- =====================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_semanal_ociosidade;


-- =====================================================
-- TABELA TEMPORÁRIA
-- =====================================================

CREATE TEMPORARY TABLE tmp_agregado_semanal_ociosidade (

    grouping_id VARCHAR(64) NOT NULL,

    ano_mes DATE NOT NULL,

    semana INT NOT NULL,

    grouping_semana_ano_mes VARCHAR(100) NOT NULL,

    duracao TIME NOT NULL,

    duracao_int DECIMAL(14,2) DEFAULT 0,

    litros_gasto DECIMAL(14,2) DEFAULT 0,


    PRIMARY KEY (
        grouping_id,
        ano_mes,
        semana
    )

) ENGINE=InnoDB;


-- =====================================================
-- INSERE DADOS AGRUPADOS SEMANALMENTE
-- =====================================================

INSERT INTO tmp_agregado_semanal_ociosidade (

    grouping_id,
    ano_mes,
    semana,
    grouping_semana_ano_mes,
    duracao,
    duracao_int,
    litros_gasto

)


-- =====================================================
-- SELECT FINAL
-- =====================================================

SELECT

    x.grouping_id,

    x.ano_mes,

    x.semana,


    -- ================================================
    -- CHAVE:
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
    ) AS grouping_semana_ano_mes,


    x.duracao,

    x.duracao_int,

    x.litros_gasto


FROM (

    -- =================================================
    -- SUBCONSULTA PARA AGRUPAMENTO
    -- =================================================

    SELECT


        -- =============================================
        -- GROUPING NORMALIZADO
        -- =============================================

        REPLACE(
            REPLACE(
                TRIM(
                    UPPER(`grouping`)
                ),
                '.',
                ''
            ),
            '-',
            ''
        ) AS grouping_id,


        -- =============================================
        -- ANO E MÊS
        --
        -- EXEMPLO:
        -- 2026-09-01
        -- =============================================

        DATE(
            DATE_FORMAT(
                ativado,
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
            DAY(ativado) / 7
        ) AS semana,


        -- =============================================
        -- DURAÇÃO TOTAL
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
        -- DURAÇÃO EM HORAS DECIMAIS
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

        ) AS duracao_int,


        -- =============================================
        -- LITROS GASTOS
        -- =============================================

        ROUND(

            SUM(

                IFNULL(
                    combustivel_gasto,
                    0
                )

            ),

            2

        ) AS litros_gasto


    FROM ociosidade


    -- =============================================
    -- FILTROS
    -- =============================================

    WHERE ativado IS NOT NULL

    AND TRIM(
        IFNULL(`grouping`, '')
    ) <> ''


    -- =============================================
    -- AGRUPAMENTO
    -- =============================================

    GROUP BY


        -- GROUPING

        REPLACE(
            REPLACE(
                TRIM(
                    UPPER(`grouping`)
                ),
                '.',
                ''
            ),
            '-',
            ''
        ),


        -- ANO / MÊS

        DATE(
            DATE_FORMAT(
                ativado,
                '%Y-%m-01'
            )
        ),


        -- SEMANA

        CEILING(
            DAY(ativado) / 7
        )


) AS x;



-- =====================================================
-- ATUALIZA REGISTROS EXISTENTES
-- =====================================================

UPDATE agregado_semanal_ociosidade AS a

JOIN tmp_agregado_semanal_ociosidade AS t

ON a.grouping_id = t.grouping_id

AND a.ano_mes = t.ano_mes

AND a.semana = t.semana


SET

    a.grouping_semana_ano_mes =
        t.grouping_semana_ano_mes,

    a.duracao =
        t.duracao,

    a.duracao_int =
        t.duracao_int,

    a.litros_gasto =
        t.litros_gasto;



-- =====================================================
-- INSERE REGISTROS NOVOS
-- =====================================================

INSERT INTO agregado_semanal_ociosidade (

    grouping_id,

    ano_mes,

    semana,

    grouping_semana_ano_mes,

    duracao,

    duracao_int,

    litros_gasto

)


SELECT

    t.grouping_id,

    t.ano_mes,

    t.semana,

    t.grouping_semana_ano_mes,

    t.duracao,

    t.duracao_int,

    t.litros_gasto


FROM tmp_agregado_semanal_ociosidade AS t


LEFT JOIN agregado_semanal_ociosidade AS a

ON a.grouping_id = t.grouping_id

AND a.ano_mes = t.ano_mes

AND a.semana = t.semana


WHERE a.grouping_id IS NULL;



-- =====================================================
-- REMOVE TABELA TEMPORÁRIA
-- =====================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_semanal_ociosidade;


-- =====================================================
-- FINALIZA TRANSAÇÃO
-- =====================================================

COMMIT;