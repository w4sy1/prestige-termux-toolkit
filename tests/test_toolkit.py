import unittest
from app import command

class ToolkitTests(unittest.TestCase):
    def test_git_is_local_read(self):self.assertIn('status',command('GIT','.'))
    def test_ssh_no_remote(self):self.assertEqual(command('SSH','.'),['ssh','-Q','key'])
    def test_unknown(self):
        with self.assertRaises(ValueError):command('EXEC','.')
