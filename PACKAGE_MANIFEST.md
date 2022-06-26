## Nushell's package manifest documentation
### What is this package manifest?
Metadata inserted at the beginning of your nu_scripts package that make the whole Nushell package manager work.


## Syntax:
`#?attribute: value`


## Required attributes
### Displayed to the users
- **name**: Name of the package
- **version**: Current version of the package
- **author**: Who owns the package
- **short description**: What does this package do?

### Just for the nupac
- **url**: URL of the package
- **os**: List of supported operating systems {***TODO*** all possible values}

## Optional attributes
### Displayed to the users
- **pre-install-message**: Displayed to the user before installation
- **post-install-message**: Displayed to the user after installation

### Just for the nupac
- **keywords**: Used by `nupac search` functonality
- **nu-dependencies**: List ofpackages from nu_scripts to fetch before proceeding to the actual installation
- **installer**: URL to a custom installer defined by the author, contains e.g. installing dependencies from git repositories or winget. *Still has to be in nu_scripts/installers for security reasons*
