from pathlib import Path
import tempfile
import unittest
from configuration import configure,restore,quote_git
from unittest.mock import patch
import os

class ConfigurationTests(unittest.TestCase):
    def test_git_ssh_backup_restore(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);(root/'.gitconfig').write_text('[core]\n editor = vim\n')
            result=configure(root,'Test User','test@example.invalid',True)
            self.assertIn('Test User',(root/'.gitconfig').read_text());self.assertTrue((root/'.ssh/config').exists())
            self.assertFalse(configure(root,'Test User','test@example.invalid',True)['changed'])
            restore(root,result['backup']);self.assertEqual((root/'.gitconfig').read_text(),'[core]\n editor = vim\n');self.assertFalse((root/'.ssh/config').exists())
    def test_validation_before_writes(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(ValueError):configure(d,'Name',None)
            self.assertEqual(list(Path(d).iterdir()),[])
    def test_git_injection(self):
        with self.assertRaises(ValueError):quote_git('name\n[alias]\n x=!bad')

    def test_failed_atomic_write_preserves_original(self):
        with tempfile.TemporaryDirectory() as temporary:
            # Match configure's canonical root even when TEMP uses an 8.3 alias.
            root=Path(temporary).resolve();config=root/'.bashrc';config.write_text('original')
            replace=os.replace
            def fail(source,target):
                if Path(target)==config:raise OSError('fixture failure')
                return replace(source,target)
            with patch('configuration.os.replace',side_effect=fail):
                with self.assertRaises(OSError):configure(root)
            self.assertEqual(config.read_text(),'original')
            backup=next((root/'backup').iterdir());self.assertTrue(restore(root,backup)['restored'])
            self.assertEqual(list(root.glob('*.tmp')),[])

    def test_partial_multi_file_configuration_can_be_rolled_back(self):
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary).resolve();(root/'.bashrc').write_text('old shell');(root/'.gitconfig').write_text('old git')
            replace=os.replace
            def fail(source,target):
                if Path(target)==root/'.gitconfig':raise OSError('fixture failure')
                return replace(source,target)
            with patch('configuration.os.replace',side_effect=fail):
                with self.assertRaises(OSError):configure(root,'Fixture','fixture@example.invalid')
            restore(root,next((root/'backup').iterdir()))
            self.assertEqual((root/'.bashrc').read_text(),'old shell')
            self.assertEqual((root/'.gitconfig').read_text(),'old git')
