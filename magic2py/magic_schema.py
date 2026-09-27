"""Magic xpa 資料表定義 → PostgreSQL。

讀取一個或多個 Magic xpa 專案 XML 的 DataSourceRepository，合併後產生：
    postgresql.sql   CREATE TABLE / 索引 / 註解
    tables.csv       資料表清單（含 View、本機資料來源的表）
    columns.csv      欄位字典（Magic 型態、Picture、對應的 PostgreSQL 型態）
    conflicts.csv    同一個資料表在不同專案裡定義不一致的欄位

用法：
    python magic_schema.py schema/ Files.xml EDB.xml Doc.xml Home.xml --db Default --db Master
    python magic_schema.py schema/ Files.xml EDB.xml --native-types

多個專案連到同一個資料庫時，同名（實體名稱）的資料表合併成一個：
欄位取聯集，varchar 取較長的長度；其他型態不一致時，採用有寫明 Oracle 型態（SqlType）的定義，
都沒有就以第一個專案為準，並記錄在 conflicts.csv。
每個專案產生 DDL 的資料來源，自動選資料表最多的那一個
（Memory、SQLite、Mobile 這類本機資料來源除外）；
同一個資料庫在各專案裡名稱不同時，用 --db 列出所有名稱，例如 --db Default --db Master。

預設「保留原本的儲存方式」：日期仍是 char(8)（YYYYMMDD）、時間是 char(6)（HHMMSS）、
邏輯欄位是 smallint（0/1），這樣從 Oracle 搬資料時可以原封不動。
加上 --native-types 會改成 date / time / boolean，搬資料時需要轉換（見 README）。
"""
import csv
import os
import re
import sys
import xml.etree.ElementTree as ET

LOCAL_SOURCES = ('Memory', 'SQLite', 'Mobile', 'Log')


def q(name):
    """PostgreSQL 識別字：英文字母一律轉小寫（Oracle 不分大小寫），並加雙引號。

    中文不受影響；像「Y牢固完整度」這種中英混合的名稱會變成「y牢固完整度」，
    和 View 裡沒加引號的寫法（PostgreSQL 會轉小寫）一致。
    """
    return '"' + name.lower().replace('"', '""') + '"'


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


def val(e, path):
    x = e.find(path)
    return x.get('val') if x is not None else None


def main_source(objs):
    counts = {}
    for d in objs:
        src = d.get('data_source') or ''
        if val(d, 'ObjectType') == 'T' and d.findall('Columns/Column') and not src.startswith(LOCAL_SOURCES):
            counts[src] = counts.get(src, 0) + 1
    return max(counts, key=counts.get) if counts else None   # 只有本機暫存表的專案


def parse_project(objs, native, project, dbs=None):
    """回傳 (資料表模型 dict, tables 列, columns 列, 警告)。

    資料表模型：{實體名稱小寫: {'phys', 'name', 'columns': {欄位小寫: col}, 'indexes': [...]}}
    col = {'dbname', 'type', 'nullable', 'default', 'magic'}
    """
    sources = set(dbs) if dbs else {main_source(objs)}
    model, tables, columns, warnings = {}, [], [], []
    for pos, d in enumerate(objs, 1):
        name, phys, src = d.get('name'), d.get('PhysicalName'), d.get('data_source')
        cols = d.findall('Columns/Column')
        if not cols:
            continue  # 分隔用的空項目
        kind = {'T': 'Table', 'V': 'View'}.get(val(d, 'ObjectType'), val(d, 'ObjectType'))
        if phys and phys.upper().startswith('MV_'):
            kind = 'Materialized View'
        generate = src in sources and kind == 'Table'
        if generate and phys.lower() in model:
            warnings.append(f'{project}：略過 {name}（{phys}），與 {model[phys.lower()]["name"]} 的實體名稱重複')
            generate = False
        tables.append({'專案': project, '序號': pos, 'Magic 名稱': name, 'Public 名稱': d.get('Public') or '',
                       '實體名稱': phys, '資料來源': src, '種類': kind, '欄位數': len(cols),
                       '產生 DDL': 'Y' if generate else 'N'})

        # 依 DB 欄位名稱分組：同一個 DB 欄位可能被多個 Magic 欄位對應
        phys_cols = [c.find('PropertyList/_FieldPhysical') for c in cols]
        dbnames = [p.get('Name') or c.get('name') for c, p in zip(cols, phys_cols)]
        groups = {}
        for i, n in enumerate(dbnames):
            groups.setdefault(n.lower(), []).append(i)

        tcols = {}
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
            columns.append({'專案': project, '實體名稱': phys, 'Magic 名稱': name, '位置': i + 1,
                            'Magic 欄位': c.get('name'), 'DB 欄位': dbname,
                            'Magic 型態': f'{p.get("attribute")}/{p.get("storage")}',
                            'Picture': p.get('PIC_U') or '', 'Size': p.get('Size') or '',
                            'Oracle SqlType': p.get('SqlType') or '', 'PostgreSQL': '' if computed else t,
                            'Null': 'Y' if nullable else 'N', '預設值': default or '', '備註': note})
            if not computed and group[0] == i:
                tcols[dbname.lower()] = {'dbname': dbname, 'type': t, 'nullable': nullable, 'default': default,
                                         'magic': [cols[j].get('name') for j in group],
                                         'sqltype': p.get('SqlType') or '', 'project': project}
        if not generate:
            continue

        indexes = []
        for ix in d.findall('Indexes/Index'):
            if val(ix, 'IndexType') == 'V':
                continue  # Magic 虛擬索引，資料庫中不存在
            segs = []
            for sg in ix.findall('Segments/Segment'):
                n = dbnames[int(sg.find('Column').get('val')) - 1]
                if not is_identifier(n):
                    warnings.append(f'{project}：略過索引 {name}.{ix.get("name")}（包含運算欄位）')
                    segs = None
                    break
                if n.lower() not in [s[0].lower() for s in segs]:  # 日期＋時間拆成兩段的只保留一段
                    segs.append((n, val(sg, 'Order') == 'D'))
            if segs:
                indexes.append({'name': val(ix, 'PhysicalName') or f'{phys}_{ix.get("id")}',
                                'primary': val(ix, 'Primary') == 'Y', 'unique': val(ix, 'Mode') == 'S',
                                'segs': segs})
        model[phys.lower()] = {'phys': phys, 'name': name, 'project': project, 'columns': tcols,
                               'indexes': indexes}
    return model, tables, columns, warnings


def varchar_len(t):
    m = re.fullmatch(r'varchar\((\d+)\)', t)
    return int(m.group(1)) if m else None


def merge(models):
    """合併多個專案的資料表模型。回傳 (合併後模型, 衝突列)。"""
    merged, conflicts = {}, []
    for model in models:
        for key, tbl in model.items():
            if key not in merged:
                merged[key] = {**tbl, 'columns': dict(tbl['columns']), 'indexes': list(tbl['indexes']),
                               'names': [f'{tbl["project"]}：{tbl["name"]}']}
                continue
            base = merged[key]
            base['names'].append(f'{tbl["project"]}：{tbl["name"]}')
            for ck, col in tbl['columns'].items():
                old = base['columns'].get(ck)
                if old is None:
                    base['columns'][ck] = col
                    continue
                old['nullable'] = old['nullable'] or col['nullable']
                if old['type'] == col['type']:
                    continue
                a, b = varchar_len(old['type']), varchar_len(col['type'])
                if a and b:
                    old['type'] = f'varchar({max(a, b)})'
                    continue
                row = {'實體名稱': base['phys'], 'DB 欄位': old['dbname'],
                       '專案 1': old['project'], '型態 1': old['type'], 'SqlType 1': old['sqltype'],
                       '專案 2': col['project'], '型態 2': col['type'], 'SqlType 2': col['sqltype']}
                if col['sqltype'] and not old['sqltype']:   # 有明寫 Oracle 型態的定義比較可信
                    base['columns'][ck] = {**col, 'nullable': old['nullable']}
                    row['採用'], row['原因'] = col['type'], f'{col["project"]} 有 SqlType'
                else:
                    row['採用'] = old['type']
                    row['原因'] = f'{old["project"]} 有 SqlType' if old['sqltype'] else '都沒有 SqlType，請用 Oracle 確認'
                conflicts.append(row)
            names = {ix['name'].lower() for ix in base['indexes']}
            base['indexes'] += [ix for ix in tbl['indexes'] if ix['name'].lower() not in names]
    return merged, conflicts


def render(merged):
    ddl = []
    for tbl in merged.values():
        tname = q(tbl['phys'])
        body = []
        for col in tbl['columns'].values():
            s = f'    {q(col["dbname"])} {col["type"]}'
            if col['default'] is not None:
                s += f' DEFAULT {col["default"]}'
            if not col['nullable']:
                s += ' NOT NULL'
            body.append(s)
        extra = []
        has_pk = False
        for ix in tbl['indexes']:
            segs = [q(n) + (' DESC' if desc else '') for n, desc in ix['segs']]
            if ix['primary'] and not has_pk:
                body.append(f'    PRIMARY KEY ({", ".join(q(n) for n, _ in ix["segs"])})')
                has_pk = True
            else:
                unique = 'UNIQUE ' if ix['unique'] or ix['primary'] else ''
                extra.append(f'CREATE {unique}INDEX {q(ix["name"])} ON {tname} ({", ".join(segs)});')
        ddl.append('-- ' + '；'.join(tbl['names']))
        ddl.append(f'CREATE TABLE {tname} (\n' + ',\n'.join(body) + '\n);')
        ddl.extend(extra)
        ddl.append(f'COMMENT ON TABLE {tname} IS {sql_str(tbl["name"])};')
        for col in tbl['columns'].values():
            if col['magic'] != [col['dbname']]:
                ddl.append(f'COMMENT ON COLUMN {tname}.{q(col["dbname"])} IS {sql_str(" / ".join(col["magic"]))};')
        ddl.append('')
    return ddl


def write_csv(path, rows):
    if not rows:
        if os.path.exists(path):
            os.remove(path)
        return
    with open(path, 'w', newline='', encoding='utf-8-sig') as f:  # utf-8-sig：Excel 可直接開
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def main():
    argv = sys.argv[1:]
    dbs = []
    while '--db' in argv:
        i = argv.index('--db')
        dbs.append(argv[i + 1])
        del argv[i:i + 2]
    args = [a for a in argv if not a.startswith('--')]
    native = '--native-types' in argv
    out, sources = args[0], args[1:]
    models, tables, columns, warnings = [], [], [], []
    for path in sources:
        project = re.sub(r'^[0-9a-f]{8}-', '', os.path.splitext(os.path.basename(path))[0])
        m, t, c, w = parse_project(load(path), native, project, dbs)
        models.append(m)
        tables += t
        columns += c
        warnings += w
    merged, conflicts = merge(models)
    os.makedirs(out, exist_ok=True)
    projects = '、'.join(t['專案'] for t in {t['專案']: t for t in tables}.values())
    header = [f'-- 由 magic_schema.py 從 {projects} 產生'
              f'{"（--native-types）" if native else ""}，請勿手動修改']
    header += [f'-- 注意：{w}' for w in warnings]
    header += [f'-- 型態衝突：{c["實體名稱"]}.{c["DB 欄位"]} {c["專案 1"]}={c["型態 1"]}、'
               f'{c["專案 2"]}={c["型態 2"]}，採用 {c["採用"]}（{c["原因"]}）' for c in conflicts]
    with open(os.path.join(out, 'postgresql.sql'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(header + [''] + render(merged)))
    write_csv(os.path.join(out, 'tables.csv'), tables)
    write_csv(os.path.join(out, 'columns.csv'), columns)
    write_csv(os.path.join(out, 'conflicts.csv'), conflicts)
    print(f'資料表 {len(merged)} 個；共 {len(tables)} 個物件、{len(columns)} 個欄位；'
          f'型態衝突 {len(conflicts)}；警告 {len(warnings)}')
    for w in warnings:
        print(w)


if __name__ == '__main__':
    main()
