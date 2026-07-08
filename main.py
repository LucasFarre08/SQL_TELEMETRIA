import os
import argparse
import mysql.connector
from config import MYSQL

parser = argparse.ArgumentParser()
parser.add_argument(
    "--database",
    required=True,
    help="Banco que será atualizado"
)
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
    autocommit=False,
    use_pure=True
)
cursor = conn.cursor()

# Garante o mesmo sql_mode usado no Workbench, removendo ONLY_FULL_GROUP_BY
cursor.execute(
    "SET SESSION sql_mode = (SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''))"
)
cursor.execute("SELECT @@SESSION.sql_mode")
print("sql_mode ativo:", cursor.fetchone()[0])
print("=" * 50)

arquivos = [
    "sql/limpeza.sql",
    "sql/agregado_mensal.sql",
    "sql/agregado_motoristas.sql",
    "sql/agregado_ociosidade.sql",
    
]

try:
    for arquivo in arquivos:
        print(f"\nExecutando {arquivo}")
        with open(arquivo, encoding="utf8") as f:
            sql = f.read()

        # A partir do mysql-connector-python 9.2.0, o parâmetro multi=True
        # foi removido. Agora execute() já lida com múltiplas instruções
        # automaticamente, e os result sets são percorridos com nextset().
        cursor.execute(sql)
        while True:
            try:
                if cursor.with_rows:
                    cursor.fetchall()
            except Exception:
                pass
            if not cursor.nextset():
                break
    conn.commit()
    print("\n✔ Processo finalizado.")
except Exception as e:
    conn.rollback()
    print("\n========================")
    print("ERRO ENCONTRADO")
    print("========================")
    print(f"Arquivo: {arquivo}")
    print(f"Erro: {e}")
    print("========================")
    raise
finally:
    cursor.close()
    conn.close()
