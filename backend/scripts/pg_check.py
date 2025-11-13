import psycopg2
import sys

DSN = dict(dbname='tutor_ai_db', user='tutor_ai_user', password='admin', host='localhost', port=5432)

try:
    conn = psycopg2.connect(**DSN)
    cur = conn.cursor()
    cur.execute("SELECT table_schema, table_name FROM information_schema.tables WHERE table_name=%s", ('core_customuser',))
    tables = cur.fetchall()
    print('tables:', tables)
    if tables:
        cur.execute('SELECT id, username, email, parent, kid FROM core_customuser')
        rows = cur.fetchall()
        print('rows:')
        for r in rows:
            print(r)
    else:
        print('core_customuser not found in information_schema')
    cur.close()
    conn.close()
except Exception as e:
    print('ERROR:', type(e).__name__, e)
    sys.exit(1)
