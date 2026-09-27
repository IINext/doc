"""從 Magic 專案 XML 中抽出 Oracle View 定義，轉成 PostgreSQL。

Magic 程式裡用 SQL 指令建立 View（例如 Home 專案的「View」資料夾），
這支工具把所有 CREATE VIEW 抽出來，每個 View 取最後修改的版本，轉成 PostgreSQL 語法。

用法：
    python magic_views.py schema/ oracle_views.csv --columns oracle_columns.csv   # Oracle 實際的定義（建議）
    python magic_views.py schema/ Home.xml [其他專案.xml ...]      # 沒有 Oracle 匯出時，從 Magic 程式抽出
    python magic_views.py schema/ Home.xml --pg "host=/tmp port=5432 dbname=t user=postgres"
    python magic_views.py schema/ Home.xml --pg "..." --smoke   # 另外放測試資料實際查詢每個 View

輸出：
    oracle_views.sql      原始 Oracle 定義（每個 View 最後的版本）
    postgresql_views.sql  轉換後的定義；有 --pg 時只放實際建立成功的，並依相依順序排列
    views.csv             每個 View 的來源程式、轉換結果與錯誤訊息

--pg 會連到一個已經執行過 postgresql.sql 和 oracle_compat.sql 的資料庫，
逐一建立 View 來驗證（View 之間有相依關係，會反覆嘗試到沒有進展為止）。
--smoke 再在每個資料表放一筆測試資料、實際查詢每個 View（最後 ROLLBACK），
抓出建立時看不出來的執行錯誤。請用測試用的資料庫。
需要安裝 sqlglot，驗證時另外需要 psycopg2。
"""
import csv
import os
import re
import sys
import xml.etree.ElementTree as ET

import sqlglot
from sqlglot import exp

CREATE_VIEW = re.compile(
    r'CREATE\s+(?:OR\s+REPLACE\s+)?(?:NO)?(?:FORCE\s+)?(?:(?:NON)?EDITIONABLE\s+)?VIEW\s+'
    r'(?:"?[\w$#]+"?\.)?"?([\w$#一-鿿]+)"?', re.I)


def extract(paths):
    """回傳 {View 名稱大寫: {'view', 'sql', 'project', 'prg', 'desc', 'stamp'}}，每個 View 取最新版本。"""
    latest = {}
    for path in paths:
        root = ET.parse(path).getroot()
        project = root.find('ProjectProperties/ProjectData/ProjectName').get('val')
        for i, t in enumerate(root.findall('ProgramsRepository/Programs/Task'), 1):
            h = t.find('Header')
            lm = h.find('LastModified')
            stamp = (int(lm.get('_date') or 0), int(lm.get('_time') or 0), i) if lm is not None else (0, 0, i)
            for x in t.iter('SQL_STMT_U'):
                for part in re.split(r';\s*(?:\r?\n|$)', x.get('val') or ''):
                    m = CREATE_VIEW.search(part)
                    if not m:
                        continue
                    key = m.group(1).upper()
                    if key not in latest or stamp > latest[key]['stamp']:
                        latest[key] = {'view': m.group(1), 'sql': part.strip(), 'project': project,
                                       'prg': i, 'desc': h.get('Description'), 'stamp': stamp}
    return latest


TRUNC_UNIT = {'DD': 'day', 'DDD': 'day', 'J': 'day', 'DAY': 'day', 'D': 'week', 'IW': 'week', 'WW': 'week',
              'MM': 'month', 'MON': 'month', 'MONTH': 'month', 'RM': 'month',
              'Q': 'quarter', 'YYYY': 'year', 'YYY': 'year', 'YY': 'year', 'Y': 'year', 'YEAR': 'year',
              'HH': 'hour', 'HH12': 'hour', 'HH24': 'hour', 'MI': 'minute'}


def outside_strings(sql, fn):
    """只對字串常數以外的部分套用 fn。"""
    parts = re.split(r"('(?:[^']|'')*')", sql)
    return ''.join(p if i % 2 else fn(p) for i, p in enumerate(parts))


def view_columns(path):
    """oracle_columns.csv 中每個 View 的欄位（依順序），以及在 Oracle 已失效的 View（欄位型態 UNDEFINED）。"""
    import csv
    import io
    with open(path, encoding='utf-8-sig', newline='') as f:
        rows = list(csv.DictReader(io.StringIO(f.read().lstrip('\r\n'))))
    cols, invalid = {}, set()
    for r in rows:
        if r['OBJECT_TYPE'] == 'VIEW':
            cols.setdefault(r['TABLE_NAME'].upper(), []).append((int(r['COLUMN_ID']), r['COLUMN_NAME']))
            if r['DATA_TYPE'] == 'UNDEFINED':
                invalid.add(r['TABLE_NAME'].upper())
    return {k: [c for _, c in sorted(v)] for k, v in cols.items()}, invalid


def extract_oracle_csv(path, columns_path=None):
    """讀 export_oracle_dictionary.sql 匯出的 oracle_views.csv（Oracle 裡實際的 View 定義）。

    View 的 SQL 內含換行與引號，SQL*Plus 的 CSV 用一般 CSV 讀取會出錯，
    這裡改用「行首的 "名稱","」切開每一筆。
    user_views 只有查詢本身，View 的欄位名稱另外從 oracle_columns.csv 取得（columns_path）。
    """
    cols, invalid = view_columns(columns_path) if columns_path else ({}, set())
    with open(path, encoding='utf-8-sig', newline='') as f:
        text = f.read()
    starts = list(re.finditer(r'(?:^|\r\n|\r|\n)"([^"\r\n]+)","', text))
    latest = {}
    for i, m in enumerate(starts):
        name = m.group(1)
        if name == 'VIEW_NAME':
            continue
        end = starts[i + 1].start() if i + 1 < len(starts) else len(text)
        body = text[m.end():end].rstrip()
        body = body[:-1] if body.endswith('"') else body
        body = body.replace('""', '"').replace('\r\r\n', '\n').replace('\r\n', '\n')
        names = cols.get(name.upper())
        collist = ' (' + ', '.join('"' + c.replace('"', '""') + '"' for c in names) + ')' if names else ''
        latest[name.upper()] = {'view': name, 'sql': f'CREATE VIEW "{name}"{collist} AS {body}',
                                'project': 'Oracle', 'prg': '', 'stamp': (0, 0, 0),
                                'desc': 'user_views' + ('（在 Oracle 已失效）' if name.upper() in invalid else '')}
    return latest


def preclean(sql, notes=None):
    """去掉 PostgreSQL 不支援、也不影響結果的 Oracle 語法。notes 會記錄做過的修正。"""
    fixed = outside_strings(sql, lambda p: p.replace('（', '(').replace('）', ')'))
    if fixed != sql and notes is not None:
        notes.append('全形括號改為半形（原 SQL 在 Oracle 應該也無法執行）')
    sql = fixed
    sql = re.sub(r'\b(NO)?FORCE\s+', '', sql, flags=re.I)
    sql = re.sub(r'\b(NON)?EDITIONABLE\s+', '', sql, flags=re.I)
    sql = re.sub(r'"?\bAPK\b"?\s*\.\s*', '', sql, flags=re.I)          # schema 前綴
    sql = re.sub(r'\bWITH\s+READ\s+ONLY\b', '', sql, flags=re.I)
    return sql


def normalize(tree, notes=None):
    """所有識別字轉小寫並加引號，和 magic_schema.py 產生的資料表一致。"""
    for ident in tree.find_all(exp.Identifier):
        ident.set('this', ident.this.lower())
        ident.set('quoted', True)
    # LISTAGG 用在數字欄位時，PostgreSQL 的 string_agg 需要文字
    for agg in tree.find_all(exp.GroupConcat):
        target = agg.this if isinstance(agg.this, exp.Order) else agg
        target.set('this', exp.cast(target.this, 'text'))
    # 字串串接：Oracle 的 'A' || NULL = 'A'，PostgreSQL 的 || 遇到 NULL 會整個變 NULL；
    # 改用 CONCAT()，它和 Oracle 一樣忽略 NULL（LEFT JOIN 後串接名稱的寫法很常見）
    for pipe in list(tree.find_all(exp.DPipe)):
        if isinstance(pipe.parent, exp.DPipe) or pipe.parent is None:
            continue
        parts, stack = [], [pipe]
        while stack:
            node = stack.pop()
            if isinstance(node, exp.DPipe):
                stack += [node.expression, node.this]
            else:
                parts.append(node)
        pipe.replace(exp.Anonymous(this='CONCAT', expressions=parts))
    # SUBSTR：Oracle 的起點 0、負數起點、負數長度的處理和 PostgreSQL 不同，改用 oracle_compat.sql 的 ora_substr
    for sub in list(tree.find_all(exp.Substring)):
        args = [sub.this, sub.args.get('start') or exp.Literal.number(1)]
        if sub.args.get('length') is not None:
            args.append(sub.args['length'])
        sub.replace(exp.Anonymous(this='ORA_SUBSTR', expressions=args))
    # 沒給格式的 TO_NUMBER：sqlglot 會轉成 CAST(... AS DOUBLE PRECISION)，金額會變浮點數、空白字串會出錯；
    # 改呼叫 oracle_compat.sql 的 to_number(text)，回傳 numeric，空白回傳 NULL
    for num in list(tree.find_all(exp.ToNumber)):
        if num.args.get('format') is None:
            num.replace(exp.Anonymous(this='TO_NUMBER', expressions=[num.this]))
    # GROUP BY 常數：Oracle 允許，PostgreSQL 不允許文字常數，拿掉不影響結果
    for group in tree.find_all(exp.Group):
        consts = [e for e in group.expressions if isinstance(e, exp.Literal)]
        for c in consts:
            c.pop()
        if consts and notes is not None:
            notes.append('移除 GROUP BY 中的常數')
    for table in tree.find_all(exp.Table):
        if table.name == 'dual' and not table.db:
            table.parent.pop() if isinstance(table.parent, exp.From) else None
    return tree


def convert(sql, notes=None):
    """回傳 (PostgreSQL SQL, 錯誤訊息)。"""
    try:
        tree = sqlglot.parse_one(preclean(sql, notes), read='oracle')
    except Exception as e:  # noqa: BLE001  sqlglot 的錯誤種類很多
        return None, f'解析失敗：{str(e).splitlines()[0]}'
    if isinstance(tree, exp.Command):
        return None, '解析失敗：sqlglot 不支援此語法'
    tree = normalize(tree, notes)
    try:
        out = tree.sql(dialect='postgres', unsupported_level=sqlglot.ErrorLevel.RAISE)
    except Exception as e:  # noqa: BLE001
        msg = str(e).splitlines()[0]
        if 'TO_NUMBER' not in msg:
            return None, f'轉換失敗：{msg}'
        # 沒給格式的 TO_NUMBER 照原樣輸出，由 oracle_compat.sql 的 to_number(text) 處理
        out = tree.sql(dialect='postgres', unsupported_level=sqlglot.ErrorLevel.IGNORE)
    out = re.sub(r'^CREATE VIEW', 'CREATE OR REPLACE VIEW', out)
    # Oracle TRUNC(日期, 格式) 的格式代碼換成 PostgreSQL date_trunc 的單位
    out = re.sub(r"DATE_TRUNC\('(\w+)'", lambda m: f"DATE_TRUNC('{TRUNC_UNIT.get(m.group(1).upper(), m.group(1))}'", out)
    return out, ''


def fix_duplicate_aliases(sql, columns_of):
    """Oracle 允許同一層 FROM 裡兩個表用相同別名（只要欄位不衝突），PostgreSQL 不允許。

    把後出現的別名改名，再依各表實際的欄位判斷每個「別名.欄位」屬於哪個表。
    columns_of(表名) 回傳該表（或 View）的欄位名稱集合。無法判斷時回傳 None。
    """
    tree = sqlglot.parse_one(sql, read='postgres')
    changed = False
    for select in tree.find_all(exp.Select):
        tables = []
        if select.args.get('from'):
            tables += [t for t in select.args['from'].find_all(exp.Table) if t.find_ancestor(exp.Select) is select]
        for j in select.args.get('joins') or []:
            tables += [t for t in j.find_all(exp.Table) if t.find_ancestor(exp.Select) is select]
        by_alias = {}
        for t in tables:
            by_alias.setdefault(t.alias_or_name, []).append(t)
        for alias, group in by_alias.items():
            if len(group) < 2:
                continue
            owners = [(alias, columns_of(group[0].name))]
            for n, t in enumerate(group[1:], 2):
                new = f'{alias}_{n}'
                t.set('alias', exp.TableAlias(this=exp.to_identifier(new, quoted=True)))
                owners.append((new, columns_of(t.name)))
            if any(cols is None for _, cols in owners):
                return None
            for col in select.find_all(exp.Column):
                if col.table != alias or col.find_ancestor(exp.Select) is not select:
                    continue
                hits = [a for a, cols in owners if col.name in cols]
                if len(hits) != 1:
                    return None
                col.set('table', exp.to_identifier(hits[0], quoted=True))
            changed = True
    return tree.sql(dialect='postgres') if changed else None


def validate(views, dsn, notes):
    """在資料庫逐一建立，回傳 (成功的順序, {名稱: 錯誤}, {名稱: 實際使用的 SQL})。"""
    import psycopg2
    conn = psycopg2.connect(dsn)
    conn.autocommit = True
    cur = conn.cursor()

    def columns_of(name):
        cur.execute('SELECT column_name FROM information_schema.columns WHERE table_name = %s', (name,))
        cols = {r[0] for r in cur.fetchall()}
        return cols or None

    pending, order, errors = dict(views), [], {}
    progress = True
    while progress and pending:
        progress = False
        for key, sql in list(pending.items()):
            try:
                cur.execute(sql)
            except Exception as e:  # noqa: BLE001
                errors[key] = str(e).splitlines()[0]
                if 'specified more than once' in errors[key]:
                    fixed = fix_duplicate_aliases(sql, columns_of)
                    if fixed and fixed != sql:
                        pending[key] = fixed
                        notes.setdefault(key, []).append('重複的資料表別名已改名')
                        progress = True
                continue
            order.append(key)
            errors.pop(key, None)
            views[key] = sql
            del pending[key]
            progress = True
    conn.close()
    return order, errors


def smoke_test(dsn, keys):
    """每個資料表放一筆測試資料，實際查詢每個 View，抓出建立時看不出來的執行錯誤
    （例如函數參數格式不對）。全部在一個交易裡，最後 ROLLBACK，不會留下資料。"""
    import psycopg2
    conn = psycopg2.connect(dsn)
    cur = conn.cursor()
    cur.execute("""SELECT table_name, column_name, data_type, character_maximum_length,
                          numeric_precision, numeric_scale
                   FROM information_schema.columns c JOIN information_schema.tables t USING (table_schema, table_name)
                   WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
                   ORDER BY table_name, ordinal_position""")
    tables = {}
    for table, col, dtype, length, precision, scale in cur.fetchall():
        if dtype in ('character varying', 'character', 'text'):
            value = {8: '20250101', 6: '120000'}.get(length, '1')
        elif dtype in ('smallint', 'integer', 'bigint', 'numeric', 'double precision', 'real'):
            value = 0.5 if precision and scale and precision == scale else 1   # numeric(4,4) 放不下 1
        elif dtype.startswith(('timestamp', 'date')):
            value = '2025-01-01 12:00:00'
        elif dtype.startswith('time'):
            value = '12:00:00'
        elif dtype == 'boolean':
            value = True
        elif dtype == 'bytea':
            value = b'1'
        else:
            value = None
        tables.setdefault(table, []).append((col, value))
    for table, cols in tables.items():
        names = ', '.join('"' + c.replace('"', '""') + '"' for c, _ in cols)
        cur.execute(f'INSERT INTO "{table}" ({names}) VALUES ({", ".join(["%s"] * len(cols))})',
                    [v for _, v in cols])
    errors = {}
    for key in keys:
        cur.execute('SAVEPOINT s')
        try:
            cur.execute(f'SELECT * FROM "{key.lower()}" LIMIT 5')
            cur.fetchall()
        except Exception as e:  # noqa: BLE001
            errors[key] = str(e).splitlines()[0]
            cur.execute('ROLLBACK TO SAVEPOINT s')
    conn.rollback()
    conn.close()
    return errors


def main():
    argv = sys.argv[1:]
    dsn = None
    smoke = '--smoke' in argv
    argv = [a for a in argv if a != '--smoke']
    if '--pg' in argv:
        i = argv.index('--pg')
        dsn = argv[i + 1]
        del argv[i:i + 2]
    out, paths = argv[0], argv[1:]
    os.makedirs(out, exist_ok=True)
    # oracle_views.csv（Oracle 實際的定義）優先；否則從 Magic 專案 XML 抽出
    columns_path = None
    if '--columns' in paths:
        i = paths.index('--columns')
        columns_path = paths[i + 1]
        del paths[i:i + 2]
    csvs = [p for p in paths if p.lower().endswith('.csv')]
    latest = extract_oracle_csv(csvs[0], columns_path) if csvs else extract(paths)
    converted, report, notes = {}, {}, {}
    for key, v in sorted(latest.items()):
        notes[key] = []
        sql, err = convert(v['sql'], notes[key])
        report[key] = {'View': v['view'], '專案': v['project'], '程式': v['prg'], '程式名稱': v['desc'],
                       '結果': '已轉換' if sql else '失敗', '錯誤': err}
        if sql:
            converted[key] = sql

    order = sorted(converted)
    if dsn:
        order, errors = validate(converted, dsn, notes)
        for key in converted:
            if key in errors:
                report[key]['結果'], report[key]['錯誤'] = '建立失敗', errors[key]
            else:
                report[key]['結果'] = '已建立'
        if smoke:
            for key, err in smoke_test(dsn, order).items():
                report[key]['結果'], report[key]['錯誤'] = '執行錯誤', err

    with open(os.path.join(out, 'oracle_views.sql'), 'w', encoding='utf-8') as f:
        f.write('-- 由 magic_views.py 抽出的 Oracle View 定義（每個 View 最後修改的版本），請勿手動修改\n\n')
        for key, v in sorted(latest.items()):
            src = f'{v["project"]} #{v["prg"]} {v["desc"]}' if v['prg'] else f'{v["project"]} {v["desc"]}'
            f.write(f'-- {src}\n{v["sql"].rstrip()};\n\n')
    with open(os.path.join(out, 'postgresql_views.sql'), 'w', encoding='utf-8') as f:
        f.write('-- 由 magic_views.py 從 Oracle 定義轉換，請勿手動修改\n'
                '-- 執行前先執行 postgresql.sql 和 oracle_compat.sql\n'
                + ('-- 只包含已在 PostgreSQL 實際建立成功的 View，依相依順序排列\n' if dsn else '') + '\n')
        for key in order:
            v = latest[key]
            src = f'{v["project"]} #{v["prg"]} {v["desc"]}' if v['prg'] else f'{v["project"]} {v["desc"]}'
            f.write(f'-- {src}\n{converted[key]};\n\n')
    for key, r in report.items():
        r['自動修正'] = '；'.join(notes.get(key, []))
    rows = [report[k] for k in sorted(report)]
    with open(os.path.join(out, 'views.csv'), 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    counts = {}
    for r in rows:
        counts[r['結果']] = counts.get(r['結果'], 0) + 1
    print(f'View {len(latest)} 個：' + '、'.join(f'{k} {n}' for k, n in counts.items()))


if __name__ == '__main__':
    main()
