import time
import argparse
import mysql.connector
from mysql.connector import errors
from config import MYSQL

LOCK_TIMEOUT = 300
MAX_RETRIES = 3
RETRY_ERRNOS = (1205, 1213)

# Limpeza comum a todos os bancos
LIMPEZA_COMUM = "sql/limpeza.sql"

# Agregados genéricos
AGREGADOS_COMUNS = [
    "sql/agregado_mensal.sql",
    "sql/agregado_motoristas.sql",
    "sql/agregado_ociosidade.sql",
    "sql/agregado_mensal_kickdown.sql",
]

# Bancos que possuem agregado mensal próprio.
# Nesses bancos, o agregado mensal genérico será ignorado.
AGREGADO_MENSAL_EXCLUIDO_DOS_COMUNS = {
    "telemetria_maersk",
}

# Limpezas específicas
LIMPEZA_POR_BANCO = {
    "telemetria_consigaz": ["sql/limpeza.sql"],
    "telemetria_sorocaba": ["sql/limpeza.sql"],
    "telemetria_west": ["sql/limpeza.sql"],
}

# Agregados específicos por banco
AGREGADOS_POR_BANCO = {
    "telemetria_maersk": [
        "sql/agregado_mensal_maersk.sql",
    ],
    "telemetria_pernambucanas": [
        "sql/agregado_mensal_pernambucanas.sql",
    ],
    "telemetria_west": [
        "sql/agregado_motorista_semanal_west.sql",
        "sql/agregado_semanal_ociosidade_west.sql",
        "sql/agregado_semanal_west.sql",
    ],
}

# Erros ignoráveis somente durante a limpeza:
# 1146 = tabela não existe
# 3105 = tentativa de atribuir valor a coluna gerada
ERROS_IGNORAVEIS_LIMPEZA = (1146, 3105)


def split_statements(sql):
    """Separa statements por ';', respeitando strings,
    identificadores com crase e comentários SQL."""
    stmts, buf = [], []
    i, n = 0, len(sql)
    quote = None

    while i < n:
        c = sql[i]
        nxt = sql[i + 1] if i + 1 < n else ""

        if quote:
            buf.append(c)

            if c == "\\" and quote != "`":
                if i + 1 < n:
                    buf.append(nxt)
                i += 2
                continue

            if c == quote:
                quote = None

        elif c in ("'", '"', "`"):
            quote = c
            buf.append(c)

        elif (
            c == "-"
            and nxt == "-"
            and sql[i + 2:i + 3] in (" ", "\t", "\n", "\r", "")
        ):
            while i < n and sql[i] != "\n":
                i += 1
            continue

        elif c == "#":
            while i < n and sql[i] != "\n":
                i += 1
            continue

        elif c == "/" and nxt == "*":
            j = sql.find("*/", i + 2)
            i = n if j == -1 else j + 2
            continue

        elif c == ";":
            stmt = "".join(buf).strip()

            if stmt:
                stmts.append(stmt)

            buf = []

        else:
            buf.append(c)

        i += 1

    tail = "".join(buf).strip()

    if tail:
        stmts.append(tail)

    return stmts


def mostrar_bloqueios(cursor):
    """Lista transações ativas para diagnóstico de bloqueios."""
    try:
        cursor.execute(
            "SELECT trx_mysql_thread_id, trx_state, trx_started, "
            "trx_rows_locked, LEFT(IFNULL(trx_query, ''), 120) "
            "FROM information_schema.innodb_trx "
            "ORDER BY trx_started"
        )

        rows = cursor.fetchall()

        print(
            "  >> Transações ativas no servidor "
            "(possíveis bloqueadoras):"
        )

        for row in rows:
            print("    ", row)

    except Exception as e:
        print(
            "  >> Não foi possível consultar innodb_trx:",
            e,
        )


def executar_arquivo(conn, cursor, arquivo, database):
    ignoravel = "limpeza" in arquivo.lower()

    with open(arquivo, encoding="utf8") as f:
        statements = split_statements(f.read())

    for n, stmt in enumerate(statements, 1):
        resumo = " ".join(stmt.split())[:90]

        for tentativa in range(1, MAX_RETRIES + 1):
            try:
                cursor.execute(stmt)

                if cursor.with_rows:
                    cursor.fetchall()

                conn.commit()

                print(
                    f"  [{n}/{len(statements)}] "
                    f"ok ({cursor.rowcount} linhas) - {resumo}"
                )

                break

            except errors.DatabaseError as e:
                conn.rollback()

                if (
                    e.errno in RETRY_ERRNOS
                    and tentativa < MAX_RETRIES
                ):
                    espera = 15 * tentativa

                    print(
                        f"  [{n}/{len(statements)}] "
                        f"erro {e.errno}, "
                        f"tentativa {tentativa}/{MAX_RETRIES}; "
                        f"aguardando {espera}s - {resumo}"
                    )

                    if e.errno == 1205:
                        mostrar_bloqueios(cursor)

                    time.sleep(espera)
                    continue

                if (
                    e.errno in ERROS_IGNORAVEIS_LIMPEZA
                    and ignoravel
                ):
                    print(
                        f"  [{n}/{len(statements)}] "
                        f"ignorado (erro {e.errno}) - {resumo}"
                    )
                    break

                print(f"  Statement com erro: {resumo}")

                if e.errno == 1205:
                    mostrar_bloqueios(cursor)

                raise

    # Restaura o banco selecionado caso o arquivo contenha USE.
    cursor.execute(f"USE `{database}`")


def montar_lista_arquivos(database):
    """Monta a sequência de scripts para o banco informado."""
    banco = database.lower()

    # Exclui o agregado mensal genérico somente para bancos
    # que possuem um script mensal próprio.
    agregados_comuns = [
        arquivo
        for arquivo in AGREGADOS_COMUNS
        if not (
            banco in AGREGADO_MENSAL_EXCLUIDO_DOS_COMUNS
            and arquivo == "sql/agregado_mensal.sql"
        )
    ]

    arquivos = (
        [LIMPEZA_COMUM]
        + LIMPEZA_POR_BANCO.get(banco, [])
        + agregados_comuns
        + AGREGADOS_POR_BANCO.get(banco, [])
    )

    return arquivos


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--database",
        required=True,
        help="Banco que será atualizado",
    )

    args = parser.parse_args()
    database = args.database.lower()

    print("=" * 50)
    print("Banco:", database)
    print("=" * 50)

    conn = mysql.connector.connect(
        host=MYSQL["host"],
        port=MYSQL["port"],
        user=MYSQL["user"],
        password=MYSQL["password"],
        database=database,
        autocommit=True,
        use_pure=True,
    )

    cursor = conn.cursor()

    arquivo = None

    try:
        # Mesmo sql_mode do Workbench, sem ONLY_FULL_GROUP_BY.
        cursor.execute(
            "SET SESSION sql_mode = "
            "(SELECT REPLACE(@@sql_mode, "
            "'ONLY_FULL_GROUP_BY', ''))"
        )

        cursor.execute(
            f"SET SESSION innodb_lock_wait_timeout = {LOCK_TIMEOUT}"
        )

        cursor.execute("SET SQL_SAFE_UPDATES = 0")
        cursor.execute("SELECT @@SESSION.sql_mode")

        print("sql_mode ativo:", cursor.fetchone()[0])
        print("=" * 50)

        arquivos = montar_lista_arquivos(database)

        if database in AGREGADO_MENSAL_EXCLUIDO_DOS_COMUNS:
            print(
                "Agregado mensal genérico desativado para este banco; "
                "será utilizado o script específico."
            )

        for arquivo in arquivos:
            print(f"\nExecutando {arquivo}")

            executar_arquivo(
                conn,
                cursor,
                arquivo,
                database,
            )

        print("\n[OK] Processo finalizado.")

    except Exception as e:
        print("\n========================")
        print("ERRO ENCONTRADO")
        print("========================")
        print(f"Banco: {database}")
        print(f"Arquivo: {arquivo}")
        print(f"Erro: {e}")
        print("========================")

        raise

    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()
```
