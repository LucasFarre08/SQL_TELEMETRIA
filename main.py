import time
import argparse
import mysql.connector
from mysql.connector import errors
from config import MYSQL

LOCK_TIMEOUT = 300      # segundos que cada statement espera por um lock
MAX_RETRIES = 3         # tentativas em caso de lock timeout (1205) / deadlock (1213)
RETRY_ERRNOS = (1205, 1213)

# Arquivos executados em todos os bancos
ARQUIVOS_COMUNS = [
    "sql/limpeza.sql",
    "sql/agregado_mensal.sql",
    "sql/agregado_mensal_maersk.sql",
    "sql/agregado_mensal_pernambucanas.sql",
    "sql/agregado_motoristas.sql",
    "sql/agregado_ociosidade.sql",
    "sql/agregado_mensal_kickdown.sql",
    "sql/agregado_motorista_semanal_west.sql",
    "sql/agregado_semanal_ociosidade_west.sql",
    "sql/agregado_semanal_west.sql",
]

# Limpezas que só valem para um banco específico (rodam logo após limpeza.sql)
ARQUIVOS_POR_BANCO = {
    "telemetria_consigaz": ["sql/limpeza_consigaz.sql"],
    "telemetria_sorocaba": ["sql/limpeza_sorocaba.sql"],
    "telemetria_west": ["sql/limpeza_west.sql"],
}


def split_statements(sql):
    """Separa o script em statements por ';', respeitando strings,
    identificadores com crase e comentários (-- , # e /* */)."""
    stmts, buf = [], []
    i, n = 0, len(sql)
    quote = None
    while i < n:
        c = sql[i]
        nxt = sql[i + 1] if i + 1 < n else ""
        if quote:
            buf.append(c)
            if c == "\\" and quote != "`":
                buf.append(nxt)
                i += 2
                continue
            if c == quote:
                quote = None
        elif c in ("'", '"', "`"):
            quote = c
            buf.append(c)
        elif c == "-" and nxt == "-" and sql[i + 2: i + 3] in (" ", "\t", "\n", "\r", ""):
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
    """Diagnóstico: lista transações abertas quando acontece lock timeout."""
    try:
        cursor.execute(
            "SELECT trx_mysql_thread_id, trx_state, trx_started, "
            "trx_rows_locked, LEFT(IFNULL(trx_query, ''), 120) "
            "FROM information_schema.innodb_trx ORDER BY trx_started"
        )
        rows = cursor.fetchall()
        print("  >> Transações ativas no servidor (possíveis bloqueadoras):")
        for r in rows:
            print("    ", r)
    except Exception as e:
        print("  >> Não foi possível consultar innodb_trx:", e)


def executar_arquivo(conn, cursor, arquivo, database):
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
                print(f"  [{n}/{len(statements)}] ok ({cursor.rowcount} linhas) - {resumo}")
                break
            except errors.DatabaseError as e:
                conn.rollback()
                if e.errno in RETRY_ERRNOS and tentativa < MAX_RETRIES:
                    espera = 15 * tentativa
                    print(f"  [{n}/{len(statements)}] erro {e.errno}, "
                          f"tentativa {tentativa}/{MAX_RETRIES}; aguardando {espera}s - {resumo}")
                    if e.errno == 1205:
                        mostrar_bloqueios(cursor)
                    time.sleep(espera)
                    continue
                print(f"  Statement com erro: {resumo}")
                if e.errno == 1205:
                    mostrar_bloqueios(cursor)
                raise

    # Garante que um eventual USE dentro do arquivo não vaze para o próximo
    cursor.execute(f"USE `{database}`")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--database", required=True, help="Banco que será atualizado")
    args = parser.parse_args()

    print("=" * 50)
    print("Banco:", args.database)
    print("=" * 50)

    conn = mysql.connector.connect(
        host=MYSQL["host"],
        port=MYSQL["port"],
        user=MYSQL["user"],
        password=MYSQL["password"],
        database=args.database,
        autocommit=True,
        use_pure=True,
    )
    cursor = conn.cursor()

    # Mesmo sql_mode do Workbench, sem ONLY_FULL_GROUP_BY
    cursor.execute(
        "SET SESSION sql_mode = (SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''))"
    )
    cursor.execute(f"SET SESSION innodb_lock_wait_timeout = {LOCK_TIMEOUT}")
    cursor.execute("SET SQL_SAFE_UPDATES = 0")
    cursor.execute("SELECT @@SESSION.sql_mode")
    print("sql_mode ativo:", cursor.fetchone()[0])
    print("=" * 50)

    arquivos = list(ARQUIVOS_COMUNS)
    # limpezas específicas entram logo depois de limpeza.sql
    arquivos[1:1] = ARQUIVOS_POR_BANCO.get(args.database, [])

    arquivo = None
    try:
        for arquivo in arquivos:
            print(f"\nExecutando {arquivo}")
            executar_arquivo(conn, cursor, arquivo, args.database)
        print("\n[OK] Processo finalizado.")
    except Exception as e:
        print("\n========================")
        print("ERRO ENCONTRADO")
        print("========================")
        print(f"Banco: {args.database}")
        print(f"Arquivo: {arquivo}")
        print(f"Erro: {e}")
        print("========================")
        raise
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()
