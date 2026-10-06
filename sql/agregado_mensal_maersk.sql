START TRANSACTION;

SET SQL_SAFE_UPDATES = 0;

USE telemetria_maersk;

DROP TEMPORARY TABLE IF EXISTS tmp_agregado;


/* =========================================================
   TABELA AGREGADO MENSAL
   ========================================================= */

CREATE TABLE IF NOT EXISTS agregado_mensal (
    grouping_id VARCHAR(64) NOT NULL,
    ano_mes DATE NOT NULL,
    grouping_ano_mes VARCHAR(80) NOT NULL,

    km_total DECIMAL(14,2) DEFAULT 0,
    litros_total DECIMAL(14,2) DEFAULT 0,

    duracao TIME DEFAULT '00:00:00',
    duracao_int DECIMAL(14,2) DEFAULT 0,

    emissoes_de_co2 FLOAT,

    velocidade_max FLOAT,
    velocidade_media FLOAT,

    PRIMARY KEY (grouping_id, ano_mes)
) ENGINE=InnoDB;



/* =========================================================
   TABELA TEMPORÁRIA
   ========================================================= */

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


/* =========================================================
   INSERE OS DADOS
   ========================================================= */

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
    dados.grouping_id,
    dados.ano_mes,

    CONCAT(
        dados.grouping_id,
        
        DATE_FORMAT(dados.ano_mes, '%Y%m')
    ) AS grouping_ano_mes,

    ROUND(
        SUM(IFNULL(dados.quilometragem, 0)),
        2
    ) AS km_total,

    ROUND(
        SUM(IFNULL(dados.litros_consumidos, 0)),
        2
    ) AS litros_total,

    SEC_TO_TIME(
        SUM(
            TIME_TO_SEC(
                IFNULL(
                    dados.duracao,
                    '00:00:00'
                )
            )
        )
    ) AS duracao,

    ROUND(
        SUM(
            TIME_TO_SEC(
                IFNULL(
                    dados.duracao,
                    '00:00:00'
                )
            )
        ) / 3600,
        2
    ) AS duracao_int,

    ROUND(
        SUM(
            CASE
                WHEN TRIM(dados.emissoes_de_co2)
                     REGEXP '^[0-9]+([.,][0-9]+)?$'

                THEN CAST(
                    REPLACE(
                        TRIM(dados.emissoes_de_co2),
                        ',',
                        '.'
                    ) AS DECIMAL(20,6)
                )

                ELSE 0
            END
        ),
        4
    ) AS emissoes_de_co2,

    /* VELOCIDADE MÁXIMA */
    ROUND(
        MAX(
            IFNULL(
                dados.velocidade_media,
                0
            )
        ),
        2
    ) AS velocidade_max,

    /* VELOCIDADE MÉDIA */
    ROUND(
        AVG(dados.velocidade_media),
        2
    ) AS velocidade_media


FROM (

    /* =====================================================
       NORMALIZAÇÃO DOS DADOS DA TABELA VIAGENS
       ===================================================== */

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

        quilometragem,
        litros_consumidos,
        duracao,
        emissoes_de_co2,
        velocidade_media

    FROM viagens

    WHERE inicio IS NOT NULL
      AND TRIM(`grouping`) <> ''

) AS dados


GROUP BY
    dados.grouping_id,
    dados.ano_mes;


/* =========================================================
   ATUALIZA REGISTROS EXISTENTES
   ========================================================= */

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


/* =========================================================
   INSERE NOVOS REGISTROS
   ========================================================= */

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

LEFT JOIN agregado_mensal a
    ON a.grouping_id = t.grouping_id
   AND a.ano_mes = t.ano_mes

WHERE a.grouping_id IS NULL;


/* =========================================================
   LIMPEZA
   ========================================================= */

DROP TEMPORARY TABLE IF EXISTS tmp_agregado;

COMMIT;