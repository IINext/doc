"""Magic xpa 專案 XML 解析工具。

把 Magic xpa 匯出的專案 XML（單一檔案格式，例如 Project.xml）轉成可讀的文字清單，
方便人工或 AI 閱讀、比對，作為轉換成 Python 的依據。

用法：
    python magic_dump.py EDB.xml                     # 列出所有程式的清單與統計
    python magic_dump.py EDB.xml 7                   # 輸出第 7 支程式的完整邏輯
    python magic_dump.py Project.xml 3 --with Files.xml
        # 程式用到其他元件（.ecf）的資料表時，加上該元件的專案 XML 才能顯示欄位名稱
"""
import sys
import xml.etree.ElementTree as ET

LEVEL = {'T': 'Task', 'R': 'Record', 'H': 'Handler', 'C': 'Control', 'V': 'Variable',
         'F': 'Function', 'G': 'Group'}
LU_TYPE = {'P': 'Prefix', 'S': 'Suffix', 'M': 'Main', 'V': 'Verification', 'C': 'Change'}
TASK_TYPE = {'B': 'Batch', 'O': 'Online', 'C': 'Rich Client'}
BLOCK = {'I': 'Block If', 'E': 'Block Else', 'L': 'Block Loop'}
# Initial Mode：Batch 任務的模式決定每筆記錄做什麼（D = 刪除所有符合 Range 的記錄）
INITIAL_MODE = {'M': 'Modify', 'C': 'Create', 'D': 'Delete', 'Q': 'Query', 'E': 'As Parent'}
LINK_MODE = {'R': 'Query', 'W': 'Write', 'A': 'Create', 'J': 'Inner Join', 'O': 'Left Outer Join'}


def val(e, path, attr='val'):
    x = e.find(path) if e is not None else None
    return x.get(attr) if x is not None else None


class Table:
    def __init__(self, name, obj=None):
        self.name = name
        self.phys = obj.get('PhysicalName') if obj is not None else None
        self.cols = {c.get('id'): c.get('name') for c in obj.findall('Columns/Column')} if obj is not None else {}

    def label(self):
        return f'{self.name} ({self.phys})' if self.phys and self.phys != self.name else self.name


class Project:
    """專案層級的資料：程式清單、資料表、元件資料表。"""

    def __init__(self, path, extra=()):
        self.root = ET.parse(path).getroot()
        self.tasks = self.root.findall('ProgramsRepository/Programs/Task')
        self.objs = self.root.findall('DataSourceRepository/DataObjects/DataObject')
        # 其他元件專案的資料表，用 Public 名稱對應
        public = {}
        for p in extra:
            for d in ET.parse(p).getroot().findall('DataSourceRepository/DataObjects/DataObject'):
                if d.get('Public'):
                    public.setdefault(d.get('Public'), d)
        self.comp = {}
        for ci, c in enumerate(self.root.findall('ComponentsRepository/Components/Component'), 1):
            # LNK/DB 的 obj 是元件資料表的「位置」（第幾個），不是 id
            for pos, o in enumerate(c.findall('ComponentDataObjects/Object'), 1):
                pub = val(o, 'PublicName')
                self.comp[(str(ci), str(pos))] = Table(f'{c.get("name")}:{pub}', public.get(pub))

    def table(self, db):
        """db 是含 obj/comp 屬性的元素（LNK/DB、Information/DB）。"""
        if db is None or not db.get('obj'):
            return None
        obj, comp = db.get('obj'), db.get('comp')
        if comp and comp != '-1':
            return self.comp.get((comp, obj), Table(f'comp{comp}.obj{obj}'))
        i = int(obj)
        if 1 <= i <= len(self.objs):
            return Table(self.objs[i - 1].get('name'), self.objs[i - 1])
        return Table(f'obj{obj}')

    def program_name(self, obj):
        i = int(obj)
        return self.tasks[i - 1].find('Header').get('Description') if 1 <= i <= len(self.tasks) else f'prg{obj}'


class Task:
    def __init__(self, project, task, parent=None):
        self.p = project
        self.task = task
        self.parent = parent
        self.exprs = [x.get('val') for x in task.findall('Expressions/Expression/ExpSyntax')]
        self.cols = {c.get('id'): c.get('name') for c in task.findall('Resource/Columns/Column')}
        self.main = project.table(task.find('Information/DB'))
        self.subtasks = task.findall('Task')
        self.tables = []   # Select 所屬資料表的堆疊：主資料表、Link…

    def user_event(self, ev):
        """使用者事件名稱：PublicObject obj 是該任務 EVNT 清單的位置，找不到就往上層找。"""
        obj = val(ev, 'PublicObject', 'obj')
        if not obj:
            return ''
        t = self
        while t is not None:
            evnts = t.task.findall('EVNT')
            if int(obj) <= len(evnts) and evnts[int(obj) - 1].get('DESC'):
                return evnts[int(obj) - 1].get('DESC')
            t = t.parent
        return f'#{obj}'

    def event(self, ev):
        et = val(ev, 'EventType')
        if et == 'U':
            return f'User:{self.user_event(ev)}'
        return f'{et}:{val(ev, "InternalEventID") or val(ev, "PublicObject", "obj") or ""}'

    def exp(self, n):
        if n in (None, 'Y'):
            return None
        if n == 'N':
            return 'No'
        try:
            return self.exprs[int(n) - 1]
        except (ValueError, IndexError):
            return f'#{n}'

    def cond(self, op):
        c = op.find('Condition')
        if c is None:
            return ''
        e = self.exp(c.get('Exp') or c.get('val'))
        return f'   [Cond: {e}]' if e else ''

    def sql(self, pad):
        f = self.task.find('SQL_FORM')
        if f is None:
            return f'{pad}Main Source: SQL 查詢'
        stmt = (val(f, 'SQL_STMT_U') or val(f, 'SQL_STMT') or '').strip()
        ins = [self.exp(val(a, 'Exp')) or '?' for a in f.findall('INARG/Arguments/Argument')]
        outs = [a.get('Var') or '?' for a in f.findall('OUTARG/Arguments/Argument')]
        lines = [f'{pad}Main Source: SQL 查詢（資料庫 {f.get("DB")}）']
        lines += [f'{pad}    | {x}' for x in stmt.splitlines()]
        if ins:
            lines.append(f'{pad}    輸入 ' + ', '.join(f':{i}={e}' for i, e in enumerate(ins, 1)))
        if outs:
            lines.append(f'{pad}    輸出 → ' + ', '.join(outs))
        return '\n'.join(lines)

    def args(self, op):
        out = []
        for a in op.findall('Arguments/Argument'):
            if val(a, 'Skip') == 'Y':
                out.append('-')
            elif val(a, 'Var'):
                out.append(val(a, 'Var'))
            else:
                out.append(self.exp(val(a, 'Expression')) or '?')
        return ', '.join(out)

    def line(self, op, depth):
        pad = '  ' * depth
        t = op.tag
        if t == 'Remark':
            txt = val(op, 'Text') or ''
            return pad + (f'// {txt.strip()}' if txt.strip() else '')
        if t == 'Select':
            col = val(op, 'Column')
            if val(op, 'Type') == 'R':
                kind = 'Real'
                tbl = self.tables[-1] if self.tables else None
                name = tbl.cols.get(col) if tbl else None
                name = name or val(op, 'REAL_VNAME_TXT') or f'col{col}'
            else:
                kind = 'Parameter' if val(op, 'IsParameter') == 'Y' else 'Virtual'
                name = self.cols.get(col, f'col{col}')
            s = f'{pad}{op.get("Name")}: {kind:<9} {name}'
            init = self.exp(val(op, 'ASS'))
            if init:
                s += f'   = {init}'
            for tag in ('Range', 'Locate'):
                r = op.find(tag)
                if r is not None:
                    lo, hi = self.exp(r.get('MIN')), self.exp(r.get('MAX'))
                    if lo or hi:
                        s += f'   {tag}: {lo or ""}' + (f' .. {hi or ""}' if hi != lo else '')
            return s
        if t == 'Update':
            inc = ' (Incremental)' if val(op, 'Incremental') == 'Y' else ''
            return f'{pad}Update {val(op, "Variable")} = {self.exp(val(op, "WithValue"))}{inc}{self.cond(op)}'
        if t == 'Evaluate':
            return f'{pad}Evaluate {self.exp(val(op, "Expression"))}{self.cond(op)}'
        if t == 'BLOCK':
            return f'{pad}{BLOCK.get(op.get("Type"), "Block")}{self.cond(op)}'
        if t == 'END_BLK':
            return f'{pad}End Block'
        if t == 'END_LINK':
            if len(self.tables) > 1:
                self.tables.pop()
            return f'{pad}End Link'
        if t == 'DATAVIEW_SRC':
            self.tables = [self.main] if self.main else [Table('(無主資料表)')]
            if op.get('Type') == 'Q':
                return self.sql(pad)
            if not self.main:
                return f'{pad}Main Source: (無)'
            return f'{pad}Main Source: {self.main.label()}  index={op.get("IDX") or val(self.task, "Information/Key/Column")}'
        if t == 'LNK':
            tbl = self.p.table(op.find('DB')) or Table('?')
            self.tables.append(tbl)
            return (f'{pad}Link {LINK_MODE.get(op.get("Mode"), op.get("Mode"))} {tbl.label()}'
                    f'  index={op.get("Key")}{self.cond(op)}')
        if t == 'CallTask':
            obj = int(val(op, 'TaskID', 'obj') or 0)
            if val(op, 'OperationType') == 'T':
                target = self.subtasks[obj - 1].find('Header').get('Description') \
                    if 0 < obj <= len(self.subtasks) else f'subtask{obj}'
                target = f'[子任務] {target}'
            else:
                target = f'[程式 #{obj}] {self.p.program_name(obj)}'
            return f'{pad}Call {target}({self.args(op)}){self.cond(op)}'
        if t == 'Invoke':
            kind = val(op, 'OperationType')
            ret = f'  -> {val(op, "RETDVAL")}' if val(op, 'RETDVAL') else ''
            if kind == 'U':      # 外部 DLL 函式，名稱放在運算式裡，例如 '@OLE32.CoCreateGuid'
                return f'{pad}Invoke UDF {self.exp(val(op, "TaskID", "obj"))}({self.args(op)}){ret}{self.cond(op)}'
            if kind == 'B':      # Call by name
                cab, prg = self.exp(val(op, 'CabinetName', 'Exp')), self.exp(val(op, 'ProgramName', 'Exp'))
                return f'{pad}Call By Name {prg} (cabinet {cab})({self.args(op)}){ret}{self.cond(op)}'
            if kind == 'O':      # 作業系統指令
                return f'{pad}Invoke OS Command {self.exp(val(op, "Command"))}{self.cond(op)}'
            if kind == '.':      # 內嵌 .NET 程式碼
                code = (val(op, 'SnippetCode') or '').strip('\n')
                body = '\n'.join(f'{pad}    | {x}' for x in code.splitlines())
                return f'{pad}Invoke .NET {val(op, "FunctionName")}({self.args(op)}){ret}{self.cond(op)}\n{body}'
            return f'{pad}Invoke ({kind})({self.args(op)}){ret}{self.cond(op)}'
        if t == 'RaiseEvent':
            return f'{pad}Raise Event {self.event(op.find("Event"))}{self.cond(op)}'
        if t == 'STP':
            kind = 'Error' if op.get('Mode') == 'E' else 'Warning'
            return f'{pad}{kind} {self.exp(op.get("Exp")) or op.get("TXT")}{self.cond(op)}'
        return f'{pad}{t}{self.cond(op)}'

    def dump(self, depth=0):
        out = []
        h = self.task.find('Header')
        info = [TASK_TYPE.get(val(h, 'TaskType'), '?')]
        mode = val(self.task, 'Information/InitialMode')
        mexp = val(self.task, 'Information/InitialMode', 'Exp')
        if mexp:
            info.append(f'Mode=依運算式 {self.exp(mexp)}')
        elif mode and mode not in ('M', 'E'):
            info.append(f'Mode={INITIAL_MODE.get(mode, mode)}')
        out.append(f'{"  " * depth}=== {h.get("Description")}  [{", ".join(info)}]')
        for lu in self.task.findall('TaskLogic/LogicUnit'):
            lvl = LEVEL.get(val(lu, 'Level'), val(lu, 'Level'))
            if lvl in ('Task', 'Record'):
                head = f'{lvl} {LU_TYPE.get(val(lu, "Type"), val(lu, "Type"))}'
            elif lvl == 'Function':
                ret = self.exp(val(lu, 'ReturnValueExpression'))
                head = f'Function {val(lu, "TXT")}' + (f'  returns {ret}' if ret else '')
            else:
                head = f'{lvl} ({self.event(lu.find("Event"))})'
            out.append(f'{"  " * depth}--- {head}')
            d = depth + 1
            for ll in lu.findall('LogicLines/LogicLine'):
                for op in ll:
                    if op.tag in ('END_BLK', 'END_LINK') or (op.tag == 'BLOCK' and op.get('Type') == 'E'):
                        d = max(depth + 1, d - 1)
                    out.append(self.line(op, d))
                    if op.tag in ('BLOCK', 'LNK'):
                        d += 1
        for child in self.subtasks:
            out.extend(Task(self.p, child, self).dump(depth + 1))
        return out


def main():
    args = sys.argv[1:]
    extra = []
    while '--with' in args:
        i = args.index('--with')
        extra.append(args[i + 1])
        del args[i:i + 2]
    project = Project(args[0], extra)
    if len(args) > 1:
        i = int(args[1])
        print('\n'.join(Task(project, project.tasks[i - 1]).dump()))
        return
    for i, t in enumerate(project.tasks, 1):
        h = t.find('Header')
        print(f'{i:3} {TASK_TYPE.get(val(h, "TaskType"), "?"):<11} '
              f'lines={len(list(t.iter("LogicLine"))):<4} subtasks={len(list(t.iter("Task"))) - 1:<2} '
              f'{h.get("Description")}')


if __name__ == '__main__':
    main()
