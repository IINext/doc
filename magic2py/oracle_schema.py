"""以 Oracle 資料字典為準產生 PostgreSQL 建表 SQL，並和 Magic 的定義比對。

輸入是 export_oracle_dictionary.sql 匯出的 CSV，加上 magic_schema.py 產生的 tables.csv、columns.csv
（用來補上 Magic 的中文名稱與預設值）。

用法：
    python oracle_schema.py schema/ oracle_columns.csv oracle_indexes.csv oracle_tables.csv

輸出（寫到 schema/）：
    postgresql.sql        建表 SQL（以 Oracle 為準；Magic 暫存表 TEMP_數字 不產生）
    oracle_tables.csv     每個資料表的分類、筆數、是否有 Magic 定義
    oracle_vs_magic.csv   Oracle 與 Magic 定義不同的地方
"""
import csv
import io
import os
import re
import sys

from magic_schema import q, sql_str


def read_csv(path):
    """SQL*Plus 匯出的 CSV 開頭有空行，先去掉。"""
    with open(path, encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(io.StringIO(f.read().lstrip('\r\n'))))


def category(name):
    if re.fullmatch(r'TEMP_\d+', name):
        return 'Magic 暫存表'
    if re.search(r'(19|20)\d{6}$', name):
        return '備份（名稱含日期）'
    if re.match(r'(BCK|BAK)', name):
        return '備份'
    if name.startswith('CNV'):
        return '轉檔'
    if 'TEST' in name:
        return '測試'
    return '業務'


def pg_type(c):
    """Oracle 欄位型態 → PostgreSQL。"""
    t = c['DATA_TYPE']
    p = int(c['DATA_PRECISION']) if c['DATA_PRECISION'] else None
    s = int(c['DATA_SCALE']) if c['DATA_SCALE'] else 0
    length = int(c['CHAR_LENGTH'] or 0) or int(c['DATA_LENGTH'] or 0)
    if t in ('VARCHAR2', 'NVARCHAR2', 'VARCHAR'):
        return f'varchar({length})'
    if t in ('CHAR', 'NCHAR'):
        return f'char({length})'
    if t == 'NUMBER':
        if p is None:
            return 'numeric'
        if s == 0:
            return 'smallint' if p <= 4 else 'integer' if p <= 9 else 'bigint' if p <= 18 else f'numeric({p},0)'
        return f'numeric({p},{s})'
    if t in ('FLOAT', 'BINARY_DOUBLE', 'BINARY_FLOAT'):
        return 'double precision'
    if t == 'DATE':
        return 'timestamp(0)'
    if t.startswith('TIMESTAMP'):
        return 'timestamptz(6)' if 'TIME ZONE' in t else 'timestamp(6)'
    if t in ('CLOB', 'NCLOB', 'LONG'):
        return 'text'
    if t in ('BLOB', 'RAW', 'LONG RAW'):
        return 'bytea'
    if t in ('ROWID', 'UROWID'):
        return 'text'
    return 'text'


def family(pgtype):
    """型態類別：只有類別不同（文字／數字／日期／二進位）才算真正的差異。"""
    if pgtype.startswith(('varchar', 'char', 'text')):
        return '文字'
    if pgtype.startswith(('smallint', 'integer', 'bigint', 'numeric', 'double')):
        return '數字'
    if pgtype.startswith(('timestamp', 'date', 'time')):
        return '日期時間'
    return pgtype


def default_fits(default, pgtype):
    """Magic 的預設值只在型態相符時使用（Magic 和 Oracle 的定義不一定一致）。"""
    if not default:
        return False
    is_text = pgtype.startswith(('varchar', 'char', 'text'))
    is_num = pgtype.startswith(('smallint', 'integer', 'bigint', 'numeric', 'double'))
    if default.startswith("'"):
        return is_text
    return is_num and re.fullmatch(r'-?\d+(\.\d+)?', default) is not None


def main():
    out, cols_csv, idx_csv, tables_csv = sys.argv[1:5]
    ocols = read_csv(cols_csv)
    oidx = read_csv(idx_csv)
    otables = {r['TABLE_NAME']: r for r in read_csv(tables_csv)}

    # Magic 定義：實體名稱 → Magic 名稱；(實體名稱, DB 欄位) → Magic 欄位資訊
    mt = read_csv(os.path.join(out, 'tables.csv'))
    mc = read_csv(os.path.join(out, 'columns.csv'))
    magic_name = {}
    for r in mt:
        if r['實體名稱'] and r['種類'] == 'Table' and r['產生 DDL'] == 'Y':
            magic_name.setdefault(r['實體名稱'].upper(), r['Magic 名稱'])
    magic_col = {}
    for r in mc:
        if r['PostgreSQL'] and r['實體名稱']:
            key = (r['實體名稱'].upper(), r['DB 欄位'].upper())
            info = magic_col.setdefault(key, {'names': [], 'type': r['PostgreSQL'], 'default': r['預設值'],
                                              'oracle': r['Oracle SqlType'], 'note': r['備註']})
            if r['Magic 欄位'] not in info['names']:
                info['names'].append(r['Magic 欄位'])

    tables = {}
    for c in ocols:
        if c['OBJECT_TYPE'] == 'TABLE':
            tables.setdefault(c['TABLE_NAME'], []).append(c)

    ddl, report, diffs = [], [], []
    for name in sorted(tables):
        cat = category(name)
        rows = otables.get(name, {}).get('NUM_ROWS', '')
        report.append({'資料表': name, '分類': cat, '筆數': rows, 'Magic 名稱': magic_name.get(name, ''),
                       '產生 DDL': 'N' if cat == 'Magic 暫存表' else 'Y'})
        if cat == 'Magic 暫存表':
            continue
        cols = sorted(tables[name], key=lambda c: int(c['COLUMN_ID']))
        body, comments = [], []
        for c in cols:
            t = pg_type(c)
            m = magic_col.get((name, c['COLUMN_NAME']))
            line = f'    {q(c["COLUMN_NAME"])} {t}'
            if m and default_fits(m['default'], t):
                line += f' DEFAULT {m["default"]}'
            if c['NULLABLE'] == 'N':
                line += ' NOT NULL'
            body.append(line)
            if m and m['names'] != [c['COLUMN_NAME']]:
                comments.append(f'COMMENT ON COLUMN {q(name)}.{q(c["COLUMN_NAME"])} IS {sql_str(" / ".join(m["names"]))};')
            if name in magic_name:
                if not m:
                    diffs.append({'資料表': name, '欄位': c['COLUMN_NAME'], '差異': 'Magic 沒有定義這個欄位',
                                  'Oracle': c['DATA_TYPE'], 'Magic': ''})
                elif family(m['type']) != family(t):
                    diffs.append({'資料表': name, '欄位': c['COLUMN_NAME'],
                                  '差異': '型態類別不同' + ('（Magic 為推測值）' if '推測' in m['note'] else ''),
                                  'Oracle': f'{c["DATA_TYPE"]} → {t}', 'Magic': m['type']})
        if name in magic_name:
            ocolnames = {c['COLUMN_NAME'] for c in cols}
            for (tbl, col), m in magic_col.items():
                if tbl == name and col not in ocolnames:
                    diffs.append({'資料表': name, '欄位': col, '差異': 'Oracle 沒有這個欄位', 'Oracle': '',
                                  'Magic': m['type']})

        # 索引
        indexes = {}
        for r in oidx:
            if r['TABLE_NAME'] == name:
                indexes.setdefault(r['INDEX_NAME'], {'unique': r['UNIQUENESS'] == 'UNIQUE',
                                                     'primary': r['IS_PRIMARY'] == 'Y', 'cols': []})
                indexes[r['INDEX_NAME']]['cols'].append((int(r['COLUMN_POSITION']), r['COLUMN_NAME'], r['DESCEND']))
        extra = []
        for ixname, ix in sorted(indexes.items()):
            segs = sorted(ix['cols'])
            if any(col.startswith('SYS_NC') for _, col, _ in segs):
                extra.append(f'-- 略過索引 {ixname}：Oracle 遞減索引的欄位是運算式，匯出資料無法得知')
                continue
            cols_sql = ', '.join(q(col) + (' DESC' if d == 'DESC' else '') for _, col, d in segs)
            if ix['primary']:
                body.append(f'    PRIMARY KEY ({", ".join(q(col) for _, col, _ in segs)})')
            else:
                extra.append(f'CREATE {"UNIQUE " if ix["unique"] else ""}INDEX {q(ixname)} ON {q(name)} ({cols_sql});')

        title = magic_name.get(name, '')
        ddl.append(f'-- {name}' + (f'：{title}' if title else '') + (f'（{cat}）' if cat != '業務' else '')
                   + (f'，{rows} 筆' if rows else ''))
        ddl.append(f'CREATE TABLE {q(name)} (\n' + ',\n'.join(body) + '\n);')
        ddl.extend(extra)
        if title:
            ddl.append(f'COMMENT ON TABLE {q(name)} IS {sql_str(title)};')
        ddl.extend(comments)
        ddl.append('')

    # Magic 有定義、Oracle 沒有的資料表
    for name, title in sorted(magic_name.items()):
        if name not in tables:
            diffs.append({'資料表': name, '欄位': '', '差異': 'Oracle 沒有這個資料表', 'Oracle': '', 'Magic': title})

    with open(os.path.join(out, 'postgresql.sql'), 'w', encoding='utf-8') as f:
        f.write('-- 由 oracle_schema.py 依 Oracle 資料字典產生（Magic 暫存表 TEMP_數字 除外），請勿手動修改\n'
                '-- 欄位說明與預設值取自 Magic 定義\n\n' + '\n'.join(ddl))
    for fname, rows in (('oracle_tables.csv', report), ('oracle_vs_magic.csv', diffs)):
        with open(os.path.join(out, fname), 'w', newline='', encoding='utf-8-sig') as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0]))
            w.writeheader()
            w.writerows(rows)
    made = sum(1 for r in report if r['產生 DDL'] == 'Y')
    kinds = {}
    for d in diffs:
        kinds[d['差異']] = kinds.get(d['差異'], 0) + 1
    print(f'Oracle 資料表 {len(report)} 個，產生 DDL {made} 個；和 Magic 的差異：{kinds}')


if __name__ == '__main__':
    main()
