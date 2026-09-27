"""Magic xpa 資料表定義 → PostgreSQL。

讀取 Magic xpa 專案 XML（例如 Files.xml）的 DataSourceRepository，產生：
    postgresql.sql   CREATE TABLE / 索引 / 註解
    tables.csv       資料表清單（含 View、非預設資料庫的表）
    columns.csv      欄位字典（Magic 型態、Picture、對應的 PostgreSQL 型態）

用法：
    python magic_schema.py Files.xml schema/
    python magic_schema.py Files.xml schema/ --native-types

預設「保留原本的儲存方式」：日期仍是 char(8)（YYYYMMDD）、時間是 char(6)（HHMMSS）、
邏輯欄位是 smallint（0/1），這樣從 Oracle 搬資料時可以原封不動。
加上 --native-types 會改成 date / time / boolean，搬資料時需要轉換（見 README）。
"""
import csv
import os
import re
import sys
import xml.etree.ElementTree as ET

DEFAULT_SOURCE = 'Default'


def q(name):
    """PostgreSQL 識別字：ASCII 名稱轉小寫，一律加雙引號（中文欄位名稱照舊）。"""
    if re.fullmatch(r'[A-Za-z0-9_]+', name):
        name = name.lower()
    return '"' + name.replace('"', '""') + '"'


def sql_str(s):
    return "'" + s.replace("'", "''") + "'"


def parse_picture(pic):
    """'N10.4CZ A' -> (10, 4)；'5CZ' -> (5, 0)；無法解析時回傳 None。"""
    m = re.match(r'\s*N?(\d+)(?:\.(\d+))?', pic or '')
    if not m:
        return None
    return int(m.group(1)), int(m.group(2) or 0)


def parse_sqltype(sqltype):
    m = re.match(r'\s*NUMBER\s*\(\s*(\d+)\s*(?:,\s*(\d+))?\s*\)', sqltype or '', re.I)
    return (int(m.group(1)), int(m.group(2) or 0)) if m else None


def is_identifier(name):
    """Oracle 欄位名稱；不是的話代表 Magic 裡寫的是 SQL 運算式（例如 A||B、子查詢）。"""
    return re.fullmatch(r'[\w$#]+', name or '') is not None


def pg_type(p, native, paired=False):
    """由 _FieldPhysical 屬性決定 PostgreSQL 型態。回傳 (type, note)。

    paired=True：這個 DB 欄位同時被一個日期、一個時間的 Magic 欄位對應，
    代表它在 Oracle 是 DATE（含日期與時間），轉成 timestamp(0)。
    """
    attr, storage = p.get('attribute'), p.get('storage')
    size = int(p.get('Size') or 0)
    pic, sqltype = p.get('PIC_U'), (p.get('SqlType') or '').upper()
    default = p.get('DB_DEF_VAL_U')

    if attr in ('A', 'U'):
        if not size:
            return 'varchar', 'Magic 未定義長度'
        return f'varchar({max(size // 2, 1) if attr == "U" else size})', ''  # Unicode 的 Size 是 bytes
    if attr == 'N':
        if storage == '4':                          # 整數
            return ('smallint' if size <= 2 else 'integer' if size <= 4 else 'bigint'), ''
        ps = parse_sqltype(sqltype)
        if not ps:
            pp = parse_picture(pic)
            if pp:
                ps = (pp[0] + pp[1], pp[1])
        return (f'numeric({ps[0]},{ps[1]})' if ps else 'numeric'), ''
    if attr in ('D', 'T'):
        if paired or sqltype.startswith(('DATE', 'TIMESTAMP')):
            return 'timestamp(0)', 'Oracle DATE（日期＋時間）'
        if attr == 'T' and storage == '23':
            return 'integer', '秒數'
        guess = '' if sqltype.startswith('CHAR') else '推測，請用 Oracle 確認；'
        if not guess or default is not None or p.get('allowed_null') == 'N':
            if native:
                return ('date', guess + 'char(8) YYYYMMDD → date') if attr == 'D' else \
                    ('time', guess + 'char(6) HHMMSS → time')
            return ('char(8)', guess + 'YYYYMMDD') if attr == 'D' else ('char(6)', guess + 'HHMMSS')
        return 'timestamp(0)', guess + 'Oracle DATE'
    if attr == 'B':
        if native:
            return 'boolean', '0/1 → boolean'
        return 'smallint', '0/1'
    if attr == 'O':
        return ('text', 'Unicode BLOB') if storage == '34' else ('bytea', 'Binary BLOB')
    return 'text', f'未知型態 {attr}/{storage}'


def pg_default(p, pgtype):
    d = p.get('DB_DEF_VAL_U')
    if d is None or pgtype in ('date', 'time', 'timestamp(0)', 'bytea', 'text'):
        return None
    if pgtype == 'boolean':
        return 'true' if d.strip("'") in ('1', 'Y', 'TRUE') else 'false'
    return d


def load(path):
    root = ET.parse(path).getroot()
    return root.findall('DataSourceRepository/DataObjects/DataObject')


def build(objs, native):
    ddl, tables, columns, warnings = [], [], [], []
    seen = {}
    for pos, d in enumerate(objs, 1):
        name, phys, src = d.get('name'), d.get('PhysicalName'), d.get('data_source')
        otype = d.find('ObjectType').get('val') if d.find('ObjectType') is not None else ''
        cols = d.findall('Columns/Column')
        if not cols:
            continue  # 分隔用的空項目
        kind = {'T': 'Table', 'V': 'View'}.get(otype, otype)
        if phys and phys.upper().startswith('MV_'):
            kind = 'Materialized View'
        generate = src == DEFAULT_SOURCE and kind == 'Table'
        if generate and phys in seen:
            warnings.append(f'-- 略過：{name}（{phys}）與 {seen[phys]} 的實體名稱重複')
            generate = False
        tables.append({'序號': pos, 'Magic 名稱': name, 'Public 名稱': d.get('Public') or '',
                       '實體名稱': phys, '資料來源': src, '種類': kind, '欄位數': len(cols),
                       '產生 DDL': 'Y' if generate else 'N'})

        # 依 DB 欄位名稱分組：同一個 DB 欄位可能被多個 Magic 欄位對應
        phys_cols = [c.find('PropertyList/_FieldPhysical') for c in cols]
        dbnames = [p.get('Name') or c.get('name') for c, p in zip(cols, phys_cols)]
        groups = {}
        for i, n in enumerate(dbnames):
            groups.setdefault(n.lower(), []).append(i)

        coldefs = []          # (定義字串, Magic 欄位名稱清單, DB 欄位名稱)
        for i, (c, p, dbname) in enumerate(zip(cols, phys_cols, dbnames)):
            group = groups[dbname.lower()]
            attrs = {phys_cols[j].get('attribute') for j in group}
            paired = len(group) > 1 and {'D', 'T'} <= attrs
            t, note = pg_type(p, native, paired)
            nullable = any(phys_cols[j].get('allowed_null') == 'Y' for j in group)
            default = pg_default(p, t)
            computed = not is_identifier(dbname)
            if computed:
                note = '運算欄位（SQL 運算式，不建立實體欄位）'
            elif group[0] != i:
                note = f'與「{cols[group[0]].get("name")}」對應同一個 DB 欄位'
            columns.append({'實體名稱': phys, 'Magic 名稱': name, '位置': i + 1, 'Magic 欄位': c.get('name'),
                            'DB 欄位': dbname, 'Magic 型態': f'{p.get("attribute")}/{p.get("storage")}',
                            'Picture': p.get('PIC_U') or '', 'Size': p.get('Size') or '',
                            'Oracle SqlType': p.get('SqlType') or '', 'PostgreSQL': '' if computed else t,
                            'Null': 'Y' if nullable else 'N', '預設值': default or '', '備註': note})
            if generate and not computed and group[0] == i:
                s = f'    {q(dbname)} {t}'
                if default is not None:
                    s += f' DEFAULT {default}'
                if not nullable:
                    s += ' NOT NULL'
                coldefs.append((s, [cols[j].get('name') for j in group], dbname))

        if not generate:
            continue
        seen[phys] = name
        tname = q(phys)
        body = [x[0] for x in coldefs]
        extra = []
        for ix in d.findall('Indexes/Index'):
            if val(ix, 'IndexType') == 'V':
                continue  # Magic 虛擬索引，資料庫中不存在
            segs, skip = [], False
            for sg in ix.findall('Segments/Segment'):
                n = dbnames[int(sg.find('Column').get('val')) - 1]
                if not is_identifier(n):
                    skip = True
                    break
                seg = q(n) + (' DESC' if val(sg, 'Order') == 'D' else '')
                if q(n) not in [x.split(' ')[0] for x in segs]:   # 日期＋時間拆成兩段的只保留一段
                    segs.append(seg)
            ixname = q(val(ix, 'PhysicalName') or f'{phys}_{ix.get("id")}')
            if skip:
                warnings.append(f'-- 略過索引：{name}.{ix.get("name")}（包含運算欄位）')
            elif val(ix, 'Primary') == 'Y':
                body.append(f'    PRIMARY KEY ({", ".join(x.replace(" DESC", "") for x in segs)})')
            else:
                unique = 'UNIQUE ' if val(ix, 'Mode') == 'S' else ''
                extra.append(f'CREATE {unique}INDEX {ixname} ON {tname} ({", ".join(segs)});')
        ddl.append(f'-- {name}')
        ddl.append(f'CREATE TABLE {tname} (\n' + ',\n'.join(body) + '\n);')
        ddl.extend(extra)
        ddl.append(f'COMMENT ON TABLE {tname} IS {sql_str(name)};')
        for _, mnames, dbname in coldefs:
            if mnames != [dbname]:
                ddl.append(f'COMMENT ON COLUMN {tname}.{q(dbname)} IS {sql_str(" / ".join(mnames))};')
        ddl.append('')
    return ddl, tables, columns, warnings


def val(e, path):
    x = e.find(path)
    return x.get('val') if x is not None else None


def write_csv(path, rows):
    with open(path, 'w', newline='', encoding='utf-8-sig') as f:  # utf-8-sig：Excel 可直接開
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def main():
    src, out = sys.argv[1], sys.argv[2]
    native = '--native-types' in sys.argv
    os.makedirs(out, exist_ok=True)
    ddl, tables, columns, warnings = build(load(src), native)
    header = [f'-- 由 magic_schema.py 從 {os.path.basename(src)} 產生'
              f'{"（--native-types）" if native else ""}，請勿手動修改', '']
    with open(os.path.join(out, 'postgresql.sql'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(header + warnings + [''] + ddl))
    write_csv(os.path.join(out, 'tables.csv'), tables)
    write_csv(os.path.join(out, 'columns.csv'), columns)
    n = sum(1 for t in tables if t['產生 DDL'] == 'Y')
    print(f'資料表 {n} 個產生 DDL；共 {len(tables)} 個物件、{len(columns)} 個欄位；警告 {len(warnings)}')
    for w in warnings:
        print(w)


if __name__ == '__main__':
    main()
