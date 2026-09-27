"""oracle_schema 型態對應規則的測試。"""
import unittest

from oracle_schema import category, default_fits, family, pg_type


def col(t, length='', char_length='', precision='', scale=''):
    return {'DATA_TYPE': t, 'DATA_LENGTH': length, 'CHAR_LENGTH': char_length,
            'DATA_PRECISION': precision, 'DATA_SCALE': scale}


class PgTypeTest(unittest.TestCase):
    def test_text(self):
        self.assertEqual(pg_type(col('VARCHAR2', 60, 60)), 'varchar(60)')
        self.assertEqual(pg_type(col('NVARCHAR2', 512, 256)), 'varchar(256)')   # NVARCHAR2 的長度看字數
        self.assertEqual(pg_type(col('CHAR', 8, 8)), 'char(8)')

    def test_number(self):
        self.assertEqual(pg_type(col('NUMBER', 22, 0, 1, 0)), 'smallint')
        self.assertEqual(pg_type(col('NUMBER', 22, 0, 5, 0)), 'integer')
        self.assertEqual(pg_type(col('NUMBER', 22, 0, 10, 0)), 'bigint')
        self.assertEqual(pg_type(col('NUMBER', 22, 0, 14, 4)), 'numeric(14,4)')
        self.assertEqual(pg_type(col('NUMBER', 22, 0, '', '')), 'numeric')

    def test_other(self):
        self.assertEqual(pg_type(col('DATE', 7)), 'timestamp(0)')
        self.assertEqual(pg_type(col('TIMESTAMP(9)', 11)), 'timestamp(6)')
        self.assertEqual(pg_type(col('NCLOB', 4000)), 'text')
        self.assertEqual(pg_type(col('BLOB', 4000)), 'bytea')
        self.assertEqual(pg_type(col('RAW', 16)), 'bytea')


class HelperTest(unittest.TestCase):
    def test_category(self):
        self.assertEqual(category('TEMP_0279318'), 'Magic 暫存表')
        self.assertEqual(category('FIL300B_20230301'), '備份（名稱含日期）')
        self.assertEqual(category('FIL0010'), '業務')

    def test_family(self):
        self.assertEqual(family('bigint'), family('numeric(10,0)'))
        self.assertNotEqual(family('char(8)'), family('numeric(10,0)'))

    def test_default_fits(self):
        self.assertTrue(default_fits("' '", 'varchar(10)'))
        self.assertFalse(default_fits("'00000000'", 'bigint'))
        self.assertTrue(default_fits('0', 'numeric(14,4)'))
        self.assertFalse(default_fits('0', 'char(8)'))


if __name__ == '__main__':
    unittest.main()
