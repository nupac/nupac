import unittest
import subprocess

class NupacInstallTest(unittest.TestCase):
    def setUp(self) -> None:
        subprocess.run("nupac")

    def testInstall(self):
        pass

    def testInstallWithAddToScope(self):
        pass

    def testInstallWithLongDescription(self):
        pass
