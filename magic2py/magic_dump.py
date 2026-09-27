"""Magic xpa 專案 XML 解析工具。

把 Magic xpa 匯出的專案 XML（單一檔案格式，例如 Project.xml）轉成可讀的文字清單，
方便人工或 AI 閱讀、比對，作為轉換成 Python 的依據。

用法：
    python magic_dump.py Project.xml                 # 列出所有程式的清單與統計
    python magic_dump.py Project.xml 14              # 輸出第 14 支程式的完整邏輯
    python magic_dump.py Project.xml 14 > prg14.txt
"""
import sys
import xml.etree.ElementTree as ET

LEVEL = {'T': 'Task', 'R': 'Record', 'H': 'Handler', 'C': 'Control', 'V': 'Variable',
         'F': 'Function', 'G': 'Group'}
LU_TYPE = {'P': 'Prefix', 'S': 'Suffix', 'M': 'Main', 'V': 'Verification', 'C': 'Change'}
TASK_TYPE = {'B': 'Batch', 'O': 'Online', 'C': 'Rich Client'}
BLOCK = {'I': 'Block If', 'E': 'Block Else', 'L': 'Block Loop'}


def val(e, path, attr='val'):
    x = e.find(path) if e is not None else None
    return x.get(attr) if x is not None else None


class Program:
    def __init__(self, task, index, names):
        self.task = task
        self.index = index
        self.names = names  # 全域程式序號 -> 名稱
        self.exprs = [x.get('val') for x in task.findall('Expressions/Expression/ExpSyntax')]
        self.cols = {c.get('id'): c.get('name') for c in task.findall('Resource/Columns/Column')}

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

    def line(self, op, depth):
        pad = '  ' * depth
        t = op.tag
        if t == 'Remark':
            txt = val(op, 'Text') or ''
            return pad + (f'// {txt.strip()}' if txt.strip() else '')
        if t == 'Select':
            kind = 'Real' if val(op, 'Type') == 'R' else 'Virtual'
            if val(op, 'IsParameter') == 'Y':
                kind = 'Parameter'
            col = val(op, 'Column')
            name = self.cols.get(col, f'col{col}')
            s = f'{pad}{op.get("Name")}: {kind:<9} {name}'
            init = self.exp(val(op, 'ASS'))
            if init:
                s += f'   = {init}'
            for tag in ('Range', 'Locate'):
                r = op.find(tag)
                if r is not None:
                    lo, hi = self.exp(val(r, 'MIN') or r.get('MIN')), self.exp(val(r, 'MAX') or r.get('MAX'))
                    if lo or hi:
                        s += f'   {tag}: {lo} .. {hi}'
            return s
        if t == 'Update':
            inc = ' (Incremental)' if val(op, 'Incremental') == 'Y' else ''
            return f'{pad}Update {val(op, "Variable")} = {self.exp(val(op, "WithValue"))}{inc}{self.cond(op)}'
        if t == 'Evaluate':
            return f'{pad}Evaluate {self.exp(val(op, "Expression"))}{self.cond(op)}'
        if t == 'BLOCK':
            return f'{pad}{BLOCK.get(op.get("Type"), "Block")}{self.cond(op)}'
        if t in ('END_BLK', 'END_LINK'):
            return f'{pad}End {"Block" if t == "END_BLK" else "Link"}'
        if t == 'DATAVIEW_SRC':
            return f'{pad}Main Source ({"SQL" if op.get("Type") == "Q" else "Table"}) index={op.get("IDX")}'
        if t == 'LNK':
            db = op.find('DB')
            src = f'comp{db.get("comp")}.obj{db.get("obj")}' if db is not None and db.get('comp') else \
                f'obj{db.get("obj") if db is not None else "?"}'
            mode = {'R': 'Query', 'W': 'Write', 'C': 'Create', 'A': 'Inner Join', 'L': 'Left Join'}
            return f'{pad}Link {mode.get(op.get("Mode"), op.get("Mode"))} {src} key={op.get("Key")}{self.cond(op)}'
        if t in ('CallTask', 'Invoke'):
            tid = op.find('TaskID')
            target = ''
            if tid is not None:
                target = self.names.get(tid.get('obj'), f'prg{tid.get("obj")}') if tid.get('obj') else \
                    f'subtask {tid.get("isn") or ""}'
            args = []
            for a in op.findall('Arguments/Argument'):
                args.append(self.exp(val(a, 'Expression') or val(a, 'Exp')) or val(a, 'Variable') or '?')
            cmd = self.exp(val(op, 'Command'))
            desc = target or (f'OS/Command {cmd}' if cmd else val(op, 'FunctionName') or '')
            return f'{pad}{t} {desc}({", ".join(a for a in args if a)}){self.cond(op)}'
        if t == 'RaiseEvent':
            ev = op.find('Event')
            return f'{pad}Raise Event {val(ev, "EventType")}:{val(ev, "InternalEventID") or val(ev, "UserEvent") or ""}{self.cond(op)}'
        if t == 'STP':
            return f'{pad}{"Error" if op.get("Mode") == "E" else "Warning"} {self.exp(op.get("Exp")) or op.get("TXT")}{self.cond(op)}'
        return f'{pad}{t}{self.cond(op)}'

    def dump(self, task=None, depth=0):
        task = task if task is not None else self.task
        out = []
        h = task.find('Header')
        out.append(f'{"  " * depth}=== {h.get("Description")}  [{TASK_TYPE.get(val(h, "TaskType"), "?")}]')
        sub = Program(task, self.index, self.names) if task is not self.task else self
        for lu in task.findall('TaskLogic/LogicUnit'):
            ev = lu.find('Event')
            et = val(ev, 'EventType')
            lvl = LEVEL.get(val(lu, 'Level'), val(lu, 'Level'))
            if lvl in ('Task', 'Record'):
                head = f'{lvl} {LU_TYPE.get(val(lu, "Type"), val(lu, "Type"))}'
            elif lvl == 'Function':
                ret = sub.exp(val(lu, 'ReturnValueExpression'))
                head = f'Function {val(lu, "TXT")}' + (f'  returns {ret}' if ret else '')
            else:
                head = f'{lvl} ({et}:{val(ev, "InternalEventID") or val(ev, "PublicObject", "obj") or ""})'
            out.append(f'{"  " * depth}--- {head}')
            d = depth + 1
            for ll in lu.findall('LogicLines/LogicLine'):
                for op in ll:
                    if op.tag in ('END_BLK', 'END_LINK'):
                        d = max(depth + 1, d - 1)
                    if op.tag == 'BLOCK' and op.get('Type') == 'E':
                        d = max(depth + 1, d - 1)
                    out.append(sub.line(op, d))
                    if op.tag in ('BLOCK', 'LNK'):
                        d += 1
        for child in task.findall('Task'):
            out.extend(sub.dump(child, depth + 1))
        return out


def load(path):
    root = ET.parse(path).getroot()
    tasks = root.findall('ProgramsRepository/Programs/Task')
    names = {}
    for i, t in enumerate(tasks, 1):
        names[str(i)] = t.find('Header').get('Description')
    return root, tasks, names


def main():
    root, tasks, names = load(sys.argv[1])
    if len(sys.argv) > 2:
        i = int(sys.argv[2])
        print('\n'.join(Program(tasks[i - 1], i, names).dump()))
        return
    for i, t in enumerate(tasks, 1):
        h = t.find('Header')
        print(f'{i:3} {TASK_TYPE.get(val(h, "TaskType"), "?"):<11} '
              f'lines={len(list(t.iter("LogicLine"))):<4} subtasks={len(list(t.iter("Task"))) - 1:<2} '
              f'{h.get("Description")}')


if __name__ == '__main__':
    main()
