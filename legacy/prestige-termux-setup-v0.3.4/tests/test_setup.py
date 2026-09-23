from pathlib import Path
import tempfile
import unittest
from app import configure,restore,PROFILES

class SetupTests(unittest.TestCase):
    def test_preserve_and_restore(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'.bashrc';p.write_text('existing\n')
            result=configure(d);self.assertIn('existing',p.read_text())
            self.assertFalse(configure(d)['changed'])
            restore(d,result['backup']);self.assertEqual(p.read_text(),'existing\n')
    def test_reject_changed_config(self):
        with tempfile.TemporaryDirectory() as d:
            result=configure(d);(Path(d)/'.bashrc').write_text('user edit')
            with self.assertRaises(ValueError):restore(d,result['backup'])
    def test_full_contains_all(self):
        for name,packages in PROFILES.items():self.assertTrue(set(packages)<=set(PROFILES['full']))
