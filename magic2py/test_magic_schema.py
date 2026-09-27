"""magic_schema 型態對應規則的測試。"""
import unittest
import xml.etree.ElementTree as ET

from magic_schema import is_identifier, merge, parse_picture, pg_type


def phys(**attrs):
    return ET.Element('_FieldPhysical', {k: str(v) for k, v in attrs.items()})


class PgTypeTest(unittest.TestCase):
    def test_alpha_and_unicode(self):
        self.assertEqual(pg_type(phys(attribute='A', storage=3, Size=10), False)[0], 'varchar(10)')
        # Unicode 的 Size 是 bytes，字數是一半
        self.assertEqual(pg_type(phys(attribute='U', storage=32, Size=80), False)[0], 'varchar(40)')
        self.assertEqual(pg_type(phys(attribute='A', storage=3), False)[0], 'varchar')

    def test_numeric(self):
        self.assertEqual(pg_type(phys(attribute='N', storage=4, Size=2), False)[0], 'smallint')
        self.assertEqual(pg_type(phys(attribute='N', storage=4, Size=4), False)[0], 'integer')
        self.assertEqual(pg_type(phys(attribute='N', storage=6, Size=8, PIC_U='N10.4CZ'), False)[0],
                         'numeric(14,4)')
        self.assertEqual(pg_type(phys(attribute='N', storage=6, Size=8, PIC_U='10.3',
                                      SqlType='NUMBER(18,4)'), False)[0], 'numeric(18,4)')

    def test_string_date_time(self):
        d = phys(attribute='D', storage=19, Size=8, SqlType='char(8)', DB_DEF_VAL_U="'00000000'",
                 allowed_null='N')
        self.assertEqual(pg_type(d, False)[0], 'char(8)')
        self.assertEqual(pg_type(d, True)[0], 'date')
        t = phys(attribute='T', storage=24, Size=6, SqlType='char(6)', allowed_null='N')
        self.assertEqual(pg_type(t, False)[0], 'char(6)')
        self.assertEqual(pg_type(t, True)[0], 'time')

    def test_oracle_date(self):
        d = phys(attribute='D', storage=19, Size=8, allowed_null='Y')
        self.assertEqual(pg_type(d, False, paired=True)[0], 'timestamp(0)')
        self.assertEqual(pg_type(phys(attribute='D', storage=19, SqlType='DATE'), False)[0], 'timestamp(0)')

    def test_guess_is_flagged(self):
        t, note = pg_type(phys(attribute='D', storage=19, Size=8, allowed_null='Y'), False)
        self.assertEqual(t, 'timestamp(0)')
        self.assertIn('推測', note)

    def test_logical_and_blob(self):
        b = phys(attribute='B', storage=15, Size=1)
        self.assertEqual(pg_type(b, False)[0], 'smallint')
        self.assertEqual(pg_type(b, True)[0], 'boolean')
        self.assertEqual(pg_type(phys(attribute='O', storage=34), False)[0], 'text')
        self.assertEqual(pg_type(phys(attribute='O', storage=29), False)[0], 'bytea')


def table(project, **cols):
    return {'t': {'phys': 'T', 'name': 't', 'project': project, 'indexes': [],
                  'columns': {k: {'dbname': k, 'type': t, 'nullable': False, 'default': None, 'magic': [k],
                                  'sqltype': sq, 'project': project} for k, (t, sq) in cols.items()}}}


class MergeTest(unittest.TestCase):
    def test_union_and_varchar_max(self):
        merged, conflicts = merge([table('A', a=('varchar(10)', ''), b=('integer', '')),
                                   table('B', a=('varchar(60)', ''), c=('char(8)', ''))])
        cols = merged['t']['columns']
        self.assertEqual(list(cols), ['a', 'b', 'c'])
        self.assertEqual(cols['a']['type'], 'varchar(60)')
        self.assertEqual(conflicts, [])

    def test_sqltype_wins(self):
        merged, conflicts = merge([table('A', d=('numeric(10,0)', '')), table('B', d=('char(8)', 'char(8)'))])
        self.assertEqual(merged['t']['columns']['d']['type'], 'char(8)')
        self.assertEqual(conflicts[0]['採用'], 'char(8)')

    def test_conflict_without_sqltype_keeps_first(self):
        merged, conflicts = merge([table('A', x=('varchar(1)', '')), table('B', x=('numeric(3,1)', ''))])
        self.assertEqual(merged['t']['columns']['x']['type'], 'varchar(1)')
        self.assertIn('Oracle', conflicts[0]['原因'])


class HelperTest(unittest.TestCase):
    def test_is_identifier(self):
        self.assertTrue(is_identifier('最後更新日'))
        self.assertTrue(is_identifier('Serial_Num'))
        self.assertFalse(is_identifier('異動日期||異動時間'))
        self.assertFalse(is_identifier('DBMS_LOB.GETLENGTH(圖檔)'))

    def test_parse_picture(self):
        self.assertEqual(parse_picture('N10.4CZ A'), (10, 4))
        self.assertEqual(parse_picture('5CZ'), (5, 0))
        self.assertIsNone(parse_picture('YYYY/MM/DD'))


if __name__ == '__main__':
    unittest.main()
