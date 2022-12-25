from nupac_fixture import NupacFixture


class NupacTest(NupacFixture):
    EXPECTED_HEADERS = (
        "Nushell package manager",
        "Usage",
        "Subcommands",
        "Flags"
    )

    def assertContainsExpectedHeaders(self, output: str) -> None:
        for header in self.EXPECTED_HEADERS:
            self.assertIn(header, output)

    def splitVersion(self, output: str) -> tuple[int, int, int]:
        # return tuple(map(lambda x: int(x), output.split(".")))
        out = []
        for n in output.split("."):
            try:
                out.append(int(n))
            except ValueError:
                out.append(int(n[:n.find("\r\n")]))
        return tuple(out)

    def test_nupac_prints_help(self) -> None:
        self.assertContainsExpectedHeaders(self.run_nu_command("nupac"))

    def test_nupac_help(self) -> None:
        self.assertContainsExpectedHeaders(self.run_nu_command("nupac -h"))
        self.assertContainsExpectedHeaders(self.run_nu_command("nupac --help"))
        self.assertContainsExpectedHeaders(self.run_nu_command("help nupac"))

    def test_nupac_v(self) -> None:
        EXPECTED_VERSION_SUB_NUMBERS = 3

        short = self.run_nu_command("nupac -v")
        long = self.run_nu_command("nupac --version")

        self.assertEqual(EXPECTED_VERSION_SUB_NUMBERS, len(self.splitVersion(short)))
        self.assertEqual(EXPECTED_VERSION_SUB_NUMBERS, len(self.splitVersion(long)))
