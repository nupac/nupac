## Nushell's package metadata documentation
### What is package metadata?
A json with attributes written below, bundlded with your nu_scripts package, that make the whole Nushell package manager work.

## Required attributes
### Displayed to the users
- **author**: Who owns the package
- **name**: Name of the package
- **short-desc**: What does this package do?
- **version**: Current version of the package

### Just for the nupac
- **TEMPORARILY OFF**, see: https://github.com/skelly37/nupac/issues/90
  - **checksum**: SHA256 checksum of the installer or .nu file
- **os**: List of supported operating systems, available: `["android" "linux" "macos" "windows"]`
- **raw-url**: download URL of the package
- **url**: URL of the package

## Optional attributes
### Displayed to the users
- **pre-install-msg**: Displayed to the user before installation
- **post-install-msg**: Displayed to the user after installation

### Just for the nupac
- **installer**: URL to a custom installer defined by the author, contains e.g. installing dependencies from git repositories or winget, kind of pre-install hook. *Still has to be in nu_scripts/installers for security reasons*
- **keywords**: Used by `nupac search` functonality
- **nu-dependencies**: List of packages from nu_scripts to fetch before proceeding to the actual installation, kind of pre-install hook
