""" Test custom management commands """

from unittest.mock import patch

from psycopg2 import OperationalError as Psycopg2Error

from django.core.management import call_command
from django.db.utils import OperationalError
# SimpleTestCase avoids creating any DB setup behind the scenes
from django.test import SimpleTestCase


@patch('core.management.commands.wait_for_db.Command.check')
class CommandTests(SimpleTestCase):
    """ Test Commands """

    # the patched_check parameter will be supplied by the patch decorator
    def test_wait_for_db_ready(self, patched_check):
        """ Test waiting for DB """
        patched_check.return_value = True

        call_command('wait_for_db')

        patched_check.assert_called_once_with(databases=['default'])
    # we want to patch sleep in this test only.
    # This will replace actual sleep with a MagicMock object that does nothing

    @patch('time.sleep')
    def test_wait_for_db_delay(self, patched_sleep, patched_check):
        """ Test waiting for DB when getting OperationalError """
        # note the order of mocked arguments ==>
        # the closer the patch to the declaration
        # the earlier it should appear in the list of arguments

        # The following line says:
        # The first 2 times the mocked method will return Psycopg2Error
        # The the following 3 times it will raise an OperationalError
        # Then it will return True
        patched_check.side_effect = [Psycopg2Error] * 2 + \
            [OperationalError] * 3 + [True]

        call_command('wait_for_db')

        self.assertEqual(patched_check.call_count, 6)

        patched_check.assert_called_with(databases=['default'])
