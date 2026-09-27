"""magic_views 轉換規則的測試。"""
import os
import tempfile
import unittest

from magic_views import convert, extract_oracle_csv, fix_duplicate_aliases, preclean


class ConvertTest(unittest.TestCase):
    def conv(self, sql):
        out, err = convert(sql)
        self.assertEqual(err, '')
        return out

    def test_identifiers_lowercase_quoted(self):
        out = self.conv('CREATE VIEW ViewFIL0012 AS SELECT A.Serial_Num, A.Y牢固完整度 FROM FIL0020 A')
        self.assertIn('CREATE OR REPLACE VIEW "viewfil0012"', out)
        self.assertIn('"a"."serial_num"', out)
        self.assertIn('"a"."y牢固完整度"', out)

    def test_force_editionable_and_schema_removed(self):
        out = self.conv('CREATE OR REPLACE FORCE EDITIONABLE VIEW "APK"."VIEWOFEMP" ("SERIALNO") AS '
                        'SELECT A.Serial_Num FROM APK.FIL0010 A')
        self.assertIn('VIEW "viewofemp"', out)
        self.assertNotIn('apk', out.lower())

    def test_concat_ignores_null_like_oracle(self):
        out = self.conv("CREATE VIEW v AS SELECT rtrim(b.n)||'.'||a.x c FROM t a LEFT JOIN u b ON b.k = a.k")
        self.assertIn('CONCAT(RTRIM("b"."n"), \'.\', "a"."x")', out)
        self.assertNotIn('||', out)

    def test_substr_uses_oracle_semantics(self):
        out = self.conv('CREATE VIEW v AS SELECT substr(a.x, 1, 6) m, substr(a.x, 3) r FROM t a')
        self.assertIn('ORA_SUBSTR("a"."x", 1, 6)', out)
        self.assertIn('ORA_SUBSTR("a"."x", 3)', out)

    def test_trunc_date_units(self):
        out = self.conv("CREATE VIEW v AS SELECT trunc(sysdate) d, trunc(a.d, 'MM') m FROM t a")
        self.assertIn("DATE_TRUNC('day', CURRENT_TIMESTAMP)", out)
        self.assertIn("DATE_TRUNC('month', \"a\".\"d\")", out)

    def test_nvl_decode(self):
        out = self.conv("CREATE VIEW v AS SELECT nvl(a.x, ' ') x, decode(a.s, '1', 'Y', 'N') s FROM t a")
        self.assertIn("COALESCE(\"a\".\"x\", ' ')", out)
        self.assertIn('CASE WHEN', out)

    def test_to_number_without_format_kept(self):
        out = self.conv('CREATE VIEW v AS SELECT to_number(a.x) n FROM t a')
        self.assertIn('TO_NUMBER("a"."x")', out)

    def test_listagg_number_cast_to_text(self):
        out = self.conv("CREATE VIEW v AS SELECT listagg(a.n, ',') within group (order by a.k) s FROM t a")
        self.assertIn('STRING_AGG(CAST("a"."n" AS TEXT)', out)

    def test_group_by_constant_removed(self):
        out = self.conv("CREATE VIEW v AS SELECT a.k, ' ' x, count(*) c FROM t a GROUP BY a.k, ' '")
        self.assertTrue(out.endswith('GROUP BY "a"."k"'))

    def test_outer_join_plus_reported(self):
        out, err = convert('CREATE VIEW v AS SELECT a.k FROM t a, u b WHERE a.k = b.k(+)')
        self.assertIsNone(out)
        self.assertIn('(+)', err)


class OracleCsvTest(unittest.TestCase):
    def test_parse_sqlplus_csv_with_column_list(self):
        views = '\r\n"VIEW_NAME","TEXT"\r\n"V1","SELECT A.X, nvl(A.Y,\' \') FROM T A\r\r\nWHERE A.Z = \'""\'"\r\n' \
                '"V2","(SELECT 1 FROM DUAL)"\r\n'
        cols = '\r\n"TABLE_NAME","COLUMN_ID","COLUMN_NAME","DATA_TYPE","DATA_LENGTH","CHAR_LENGTH",' \
               '"DATA_PRECISION","DATA_SCALE","NULLABLE","OBJECT_TYPE"\r\n' \
               '"V1",2,"Y2","VARCHAR2",1,1,,,"Y","VIEW"\r\n"V1",1,"X1","VARCHAR2",1,1,,,"Y","VIEW"\r\n' \
               '"V2",1,"C","UNDEFINED",,,,,"Y","VIEW"\r\n'
        with tempfile.TemporaryDirectory() as d:
            vp, cp = os.path.join(d, 'v.csv'), os.path.join(d, 'c.csv')
            with open(vp, 'w', encoding='utf-8', newline='') as f:
                f.write(views)
            with open(cp, 'w', encoding='utf-8', newline='') as f:
                f.write(cols)
            got = extract_oracle_csv(vp, cp)
        self.assertEqual(sorted(got), ['V1', 'V2'])
        self.assertTrue(got['V1']['sql'].startswith('CREATE VIEW "V1" ("X1", "Y2") AS SELECT'))
        self.assertIn("WHERE A.Z = '\"'", got['V1']['sql'])
        self.assertIn('已失效', got['V2']['desc'])


class PrecleanTest(unittest.TestCase):
    def test_fullwidth_parens_outside_strings(self):
        notes = []
        self.assertEqual(preclean("SELECT （a） FROM t WHERE x = '（備註）'", notes),
                         "SELECT (a) FROM t WHERE x = '（備註）'")
        self.assertTrue(notes)


class DuplicateAliasTest(unittest.TestCase):
    def test_rename_by_column_owner(self):
        cols = {'fil0030': {'k', 'c1', 'c2'}, 'viewfil3102': {'代碼', '名稱'}, 'fil0013': {'廠別編號', '廠別名稱'}}
        sql = ('SELECT "m"."名稱", "m"."廠別名稱" FROM "fil0030" AS "a" '
               'LEFT JOIN "viewfil3102" AS "m" ON "a"."c1" = "m"."代碼" '
               'LEFT JOIN "fil0013" AS "m" ON "a"."c2" = "m"."廠別編號"')
        out = fix_duplicate_aliases(sql, cols.get)
        self.assertIn('"m"."名稱"', out)
        self.assertIn('"m_2"."廠別名稱"', out)
        self.assertIn('"m_2"."廠別編號"', out)
        self.assertIn('AS "m_2"', out)

    def test_ambiguous_returns_none(self):
        cols = {'t1': {'x'}, 't2': {'x'}}
        self.assertIsNone(fix_duplicate_aliases('SELECT "m"."x" FROM "t1" AS "m", "t2" AS "m"', cols.get))


if __name__ == '__main__':
    unittest.main()
