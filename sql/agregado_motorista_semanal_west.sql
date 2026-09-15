START TRANSACTION;

SET SQL_SAFE_UPDATES = 0;

USE telemetria_west;


-- =====================================================
-- LIMPA TABELA TEMPORÁRIA
-- =====================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_motoristas_semanal;


-- =====================================================
-- TABELA FINAL
-- =====================================================

CREATE TABLE IF NOT EXISTS agregado_motoristas_semanal (

    grouping_id VARCHAR(64) NOT NULL,

    motorista VARCHAR(255) NOT NULL,

    ano_mes DATE NOT NULL,

    semana INT NOT NULL,

    grouping_semana_ano_mes VARCHAR(100) NOT NULL,

    km_total DECIMAL(14,2) DEFAULT 0,

    litros_total DECIMAL(14,2) DEFAULT 0,

    duracao TIME DEFAULT '00:00:00',

    duracao_int DECIMAL(14,2) DEFAULT 0,


    PRIMARY KEY (
        grouping_id,
        motorista,
        ano_mes,
        semana
    ),

    INDEX idx_grouping_semana_ano_mes (
        grouping_semana_ano_mes
    )

) ENGINE=InnoDB;


-- =====================================================
-- TABELA TEMPORÁRIA
-- =====================================================

CREATE TEMPORARY TABLE tmp_agregado_motoristas_semanal (

    grouping_id VARCHAR(64) NOT NULL,

    motorista VARCHAR(255) NOT NULL,

    ano_mes DATE NOT NULL,

    semana INT NOT NULL,

    grouping_semana_ano_mes VARCHAR(100) NOT NULL,

    km_total DECIMAL(14,2) DEFAULT 0,

    litros_total DECIMAL(14,2) DEFAULT 0,

    duracao TIME DEFAULT '00:00:00',

    duracao_int DECIMAL(14,2) DEFAULT 0,


    PRIMARY KEY (
        grouping_id,
        motorista,
        ano_mes,
        semana
    )

) ENGINE=InnoDB;


-- =====================================================
-- INSERE OS DADOS AGRUPADOS NA TABELA TEMPORÁRIA
-- =====================================================

INSERT INTO tmp_agregado_motoristas_semanal (

    grouping_id,
    motorista,
    ano_mes,
    semana,
    grouping_semana_ano_mes,
    km_total,
    litros_total,
    duracao,
    duracao_int

)


-- =====================================================
-- SELECT FINAL
-- =====================================================

SELECT

    x.grouping_id,

    x.motorista,

    x.ano_mes,

    x.semana,


    -- ================================================
    -- CHAVE GROUPING + ANO/MÊS + SEMANA
    --
    -- Exemplo:
    -- FDX466_202609_S2
    -- ================================================

    CONCAT(
        x.grouping_id,
        '_',
        DATE_FORMAT(x.ano_mes, '%Y%m'),
        '_S',
        x.semana
    ) AS grouping_semana_ano_mes,


    x.km_total,

    x.litros_total,

    x.duracao,

    x.duracao_int


FROM (

    -- =================================================
    -- SUBCONSULTA DE AGRUPAMENTO
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
        -- MOTORISTA NORMALIZADO
        -- =============================================

        TRIM(
            UPPER(motorista)
        ) AS motorista,


        -- =============================================
        -- ANO E MÊS
        --
        -- Exemplo:
        -- 2026-09-01
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
        -- Dias 01 a 07 = Semana 1
        -- Dias 08 a 14 = Semana 2
        -- Dias 15 a 21 = Semana 3
        -- Dias 22 a 28 = Semana 4
        -- Dias 29 a 31 = Semana 5
        -- =============================================

        CEILING(
            DAY(inicio) / 7
        ) AS semana,


        -- =============================================
        -- KM TOTAL
        -- =============================================

        ROUND(
            SUM(
                IFNULL(
                    quilometragem,
                    0
                )
            ),
            2
        ) AS km_total,


        -- =============================================
        -- LITROS CONSUMIDOS
        -- =============================================

        ROUND(
            SUM(
                IFNULL(
                    litros_consumidos,
                    0
                )
            ),
            2
        ) AS litros_total,


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

        ) AS duracao_int


    FROM viagens


    -- =============================================
    -- FILTROS
    -- =============================================

    WHERE inicio IS NOT NULL

    AND TRIM(
        IFNULL(`grouping`, '')
    ) <> ''

    AND TRIM(
        IFNULL(motorista, '')
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


        -- MOTORISTA

        TRIM(
            UPPER(motorista)
        ),


        -- ANO/MÊS

        DATE(
            DATE_FORMAT(
                inicio,
                '%Y-%m-01'
            )
        ),


        -- SEMANA

        CEILING(
            DAY(inicio) / 7
        )


) AS x;



-- =====================================================
-- ATUALIZA REGISTROS QUE JÁ EXISTEM
-- =====================================================

UPDATE agregado_motoristas_semanal AS a

JOIN tmp_agregado_motoristas_semanal AS t

ON a.grouping_id = t.grouping_id

AND a.motorista = t.motorista

AND a.ano_mes = t.ano_mes

AND a.semana = t.semana


SET

    a.grouping_semana_ano_mes =
        t.grouping_semana_ano_mes,

    a.km_total =
        t.km_total,

    a.litros_total =
        t.litros_total,

    a.duracao =
        t.duracao,

    a.duracao_int =
        t.duracao_int;



-- =====================================================
-- INSERE REGISTROS NOVOS
-- =====================================================

INSERT INTO agregado_motoristas_semanal (

    grouping_id,

    motorista,

    ano_mes,

    semana,

    grouping_semana_ano_mes,

    km_total,

    litros_total,

    duracao,

    duracao_int

)


SELECT

    t.grouping_id,

    t.motorista,

    t.ano_mes,

    t.semana,

    t.grouping_semana_ano_mes,

    t.km_total,

    t.litros_total,

    t.duracao,

    t.duracao_int


FROM tmp_agregado_motoristas_semanal AS t


LEFT JOIN agregado_motoristas_semanal AS a

ON a.grouping_id = t.grouping_id

AND a.motorista = t.motorista

AND a.ano_mes = t.ano_mes

AND a.semana = t.semana


WHERE a.grouping_id IS NULL;



-- =====================================================
-- REMOVE TABELA TEMPORÁRIA
-- =====================================================

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_motoristas_semanal;


-- =====================================================
-- FINALIZA TRANSAÇÃO
-- =====================================================

COMMIT;