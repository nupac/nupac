import unittest
import pexpect


class NupacFixture(unittest.TestCase):
    NU_COMMAND: str = "/usr/bin/nu"
    CUSTOM_CONFIG_FLAG: str = "-c"
    CONFIG_FILE: str = "todo"
    EXECUTE_COMMAND_FLAG: str = "-e"

    def run_nu_command(self, command: str) -> str:
        return pexpect.runu(
            f"{self.NU_COMMAND} {self.EXECUTE_COMMAND_FLAG} '{command}'")


if __name__ == '__main__':
    unittest.main()
