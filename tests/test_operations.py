import unittest
from app import command


class OperationsTests(unittest.TestCase):
    def test_routes_and_storage(self):
        self.assertEqual(command('NETWORK','.','routes'),['ip','route'])
        self.assertEqual(command('SYSTEM','.','storage'),['df','-h'])

    def test_ping_rejects_shell_and_options(self):
        for value in ('-f','localhost;whoami','192.168.1.1 && id'):
            with self.assertRaises(ValueError):command('NETWORK','.','ping',value)
        self.assertEqual(command('NETWORK','.','ping','192.168.1.1')[-1],'192.168.1.1')

    def test_operation_matches_category(self):
        with self.assertRaises(ValueError):command('GIT','.','ping','192.168.1.1')
