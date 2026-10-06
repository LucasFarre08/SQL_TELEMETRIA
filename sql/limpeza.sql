START TRANSACTION;

SET SQL_SAFE_UPDATES = 0;

UPDATE viagens
SET quilometragem = 0
WHERE quilometragem > 1000;

UPDATE viagens
SET quilometragem = 0
WHERE quilometragem < 0;

UPDATE viagens
SET litros_consumidos = 0
WHERE litros_consumidos > 1000;

UPDATE viagens
SET litros_consumidos = 0
WHERE litros_consumidos < 0;


UPDATE ociosidade
SET combustivel_gasto = 0
WHERE combustivel_gasto > 1000;

UPDATE ociosidade
SET combustivel_gasto = 0
WHERE combustivel_gasto < 0;


-- =========================================================
-- REMOVE KICKDOWN SEM DATA
-- =========================================================

DELETE FROM kickdown
WHERE ativado IS NULL;


-- =========================================================
-- KICKDOWN
-- =========================================================

UPDATE kickdown
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    );


-- =========================================================
-- FREIO
-- =========================================================

UPDATE freio
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    );


-- =========================================================
-- OCIOSIDADE
-- =========================================================

UPDATE ociosidade
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    );


-- =========================================================
-- SEGURANÇA
-- =========================================================

UPDATE seguranca
SET
    ano_mes = DATE_FORMAT(data, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(data, '%Y%m')
    );


-- =========================================================
-- RPM AMARELO
-- =========================================================

UPDATE rpm_amarelo
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    );


-- =========================================================
-- RPM VERMELHO
-- =========================================================

UPDATE rpm_vermelho
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    );


-- =========================================================
-- VELOCIDADE 80 KM
-- =========================================================

UPDATE velocidade_80km
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    );


-- =========================================================
-- VELOCIDADE CHUVA 60 KM
-- =========================================================

UPDATE velocidade_chuva_60km
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    );


-- =========================================================
-- AGREGADO MENSAL
-- FORMATO: GROUPING202609
-- SEM "_"
-- =========================================================

UPDATE agregado_mensal
SET
    grouping_ano_mes = CONCAT(
        grouping_id,
        DATE_FORMAT(ano_mes, '%Y%m')
    )
WHERE grouping_id IS NOT NULL
  AND ano_mes IS NOT NULL;


-- =========================================================
-- AGREGADO MENSAL OCIOSIDADE
-- =========================================================

UPDATE agregado_mensal_ociosidade
SET
    grouping_ano_mes = CONCAT(
        grouping_id,
        DATE_FORMAT(ano_mes, '%Y%m')
    )
WHERE grouping_id IS NOT NULL
  AND ano_mes IS NOT NULL;


-- =========================================================
-- CONSIGAZ
-- =========================================================

USE telemetria_consigaz;

UPDATE parado_acelerando
SET
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    )
WHERE ativado IS NOT NULL;


-- =========================================================
-- SOROCABA
-- =========================================================

USE telemetria_sorocaba;


UPDATE velocidade_via_10
SET
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(inicio, '%Y%m')
    )
WHERE inicio IS NOT NULL;


-- =========================================================
-- NORMALIZA GROUPING - VIAGENS
-- =========================================================

UPDATE viagens
SET `grouping` = TRIM(
    LEADING '-' FROM `grouping`
)
WHERE `grouping` LIKE '-%';


UPDATE viagens
SET `grouping` = REGEXP_REPLACE(
    `grouping`,
    '^[0-9]+',
    ''
)
WHERE `grouping` REGEXP '^[0-9]+';


-- =========================================================
-- NORMALIZA GROUPING - KICKDOWN
-- =========================================================

UPDATE kickdown
SET `grouping` = TRIM(
    LEADING '-' FROM `grouping`
)
WHERE `grouping` LIKE '-%';


UPDATE kickdown
SET `grouping` = REGEXP_REPLACE(
    `grouping`,
    '^[0-9]+',
    ''
)
WHERE `grouping` REGEXP '^[0-9]+';


-- =========================================================
-- NORMALIZA GROUPING - VELOCIDADE VIA 10
-- =========================================================

UPDATE velocidade_via_10
SET `grouping` = TRIM(
    LEADING '-' FROM `grouping`
)
WHERE `grouping` LIKE '-%';


UPDATE velocidade_via_10
SET `grouping` = REGEXP_REPLACE(
    `grouping`,
    '^[0-9]+',
    ''
)
WHERE `grouping` REGEXP '^[0-9]+';


-- =========================================================
-- NORMALIZA GROUPING - OCIOSIDADE
-- =========================================================

UPDATE ociosidade
SET `grouping` = TRIM(
    LEADING '-' FROM `grouping`
)
WHERE `grouping` LIKE '-%';


UPDATE ociosidade
SET `grouping` = REGEXP_REPLACE(
    `grouping`,
    '^[0-9]+',
    ''
)
WHERE `grouping` REGEXP '^[0-9]+';


-- =========================================================
-- NORMALIZA GROUPING - FREIO
-- =========================================================

UPDATE freio
SET `grouping` = TRIM(
    LEADING '-' FROM `grouping`
)
WHERE `grouping` LIKE '-%';


UPDATE freio
SET `grouping` = REGEXP_REPLACE(
    `grouping`,
    '^[0-9]+',
    ''
)
WHERE `grouping` REGEXP '^[0-9]+';


-- =========================================================
-- NORMALIZA GROUPING - RPM AMARELO
-- =========================================================

UPDATE rpm_amarelo
SET `grouping` = TRIM(
    LEADING '-' FROM `grouping`
)
WHERE `grouping` LIKE '-%';


UPDATE rpm_amarelo
SET `grouping` = REGEXP_REPLACE(
    `grouping`,
    '^[0-9]+',
    ''
)
WHERE `grouping` REGEXP '^[0-9]+';


-- =========================================================
-- NORMALIZA GROUPING - RPM VERMELHO
-- =========================================================

UPDATE rpm_vermelho
SET `grouping` = TRIM(
    LEADING '-' FROM `grouping`
)
WHERE `grouping` LIKE '-%';


UPDATE rpm_vermelho
SET `grouping` = REGEXP_REPLACE(
    `grouping`,
    '^[0-9]+',
    ''
)
WHERE `grouping` REGEXP '^[0-9]+';


-- =========================================================
-- NORMALIZA GROUPING - SEGURANÇA
-- =========================================================

UPDATE seguranca
SET `grouping` = TRIM(
    LEADING '-' FROM `grouping`
)
WHERE `grouping` LIKE '-%';


UPDATE seguranca
SET `grouping` = REGEXP_REPLACE(
    `grouping`,
    '^[0-9]+',
    ''
)
WHERE `grouping` REGEXP '^[0-9]+';


-- =========================================================
-- BANCO WEST
-- =========================================================

USE telemetria_west;


SET SQL_SAFE_UPDATES = 0;


-- =========================================================
-- KICKDOWN
-- =========================================================

UPDATE kickdown
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    ),
    grouping_semana_ano_mes = CONCAT(
        `grouping`,
        '_',
        DATE_FORMAT(ativado, '%Y%m'),
        '_S',
        CEIL(DAY(ativado) / 7)
    )
WHERE ativado IS NOT NULL;


-- =========================================================
-- FREIO
-- =========================================================

UPDATE freio
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    ),
    grouping_semana_ano_mes = CONCAT(
        `grouping`,
        '_',
        DATE_FORMAT(ativado, '%Y%m'),
        '_S',
        CEIL(DAY(ativado) / 7)
    )
WHERE ativado IS NOT NULL;


-- =========================================================
-- OCIOSIDADE
-- =========================================================

UPDATE ociosidade
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    ),
    grouping_semana_ano_mes = CONCAT(
        `grouping`,
        '_',
        DATE_FORMAT(ativado, '%Y%m'),
        '_S',
        CEIL(DAY(ativado) / 7)
    )
WHERE ativado IS NOT NULL;


-- =========================================================
-- SEGURANÇA
-- =========================================================

UPDATE seguranca
SET
    ano_mes = DATE_FORMAT(data, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(data, '%Y%m')
    ),
    grouping_semana_ano_mes = CONCAT(
        `grouping`,
        '_',
        DATE_FORMAT(data, '%Y%m'),
        '_S',
        CEIL(DAY(data) / 7)
    )
WHERE data IS NOT NULL;


-- =========================================================
-- RPM AMARELO
-- =========================================================

UPDATE rpm_amarelo
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    ),
    grouping_semana_ano_mes = CONCAT(
        `grouping`,
        '_',
        DATE_FORMAT(ativado, '%Y%m'),
        '_S',
        CEIL(DAY(ativado) / 7)
    )
WHERE ativado IS NOT NULL;


-- =========================================================
-- RPM VERMELHO
-- =========================================================

UPDATE rpm_vermelho
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    ),
    grouping_semana_ano_mes = CONCAT(
        `grouping`,
        '_',
        DATE_FORMAT(ativado, '%Y%m'),
        '_S',
        CEIL(DAY(ativado) / 7)
    )
WHERE ativado IS NOT NULL;


-- =========================================================
-- VELOCIDADE 80 KM
-- =========================================================

UPDATE velocidade_80km
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    ),
    grouping_semana_ano_mes = CONCAT(
        `grouping`,
        '_',
        DATE_FORMAT(ativado, '%Y%m'),
        '_S',
        CEIL(DAY(ativado) / 7)
    )
WHERE ativado IS NOT NULL;


-- =========================================================
-- VELOCIDADE CHUVA 60 KM
-- =========================================================

UPDATE velocidade_chuva_60km
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(
        `grouping`,
        DATE_FORMAT(ativado, '%Y%m')
    ),
    grouping_semana_ano_mes = CONCAT(
        `grouping`,
        '_',
        DATE_FORMAT(ativado, '%Y%m'),
        '_S',
        CEIL(DAY(ativado) / 7)
    )
WHERE ativado IS NOT NULL;
