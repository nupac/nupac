## Default path
`scripts` subdirectory in the Nushell's config folder. Type `$nu.config-path|path dirname` in your shell to find it.

## Cache index
By default, the cache index refreshes after a day from previous download.

Can be modified in `nupac.nu/freshness` but it's advised to keep it this way (one can simply use `nupac refresh` when needed).

## Commands
Each command has its own help accessible with one of these standard, interchangeable ways:
- `help <command>`
- `<command> -h`
- `<command> --help`

- `nupac`: *Displays help (list of all commands)*
  - `-v/--version`: Displays nupac's version instead of help
- `nupac install`: *Installs provided set of packages and optionally adds them to the global scope*
  - `...packages`: packages you want to install
  - `--add-to-scope(-a)`: add packages to global scope, *optional*
  - `--long(-l):`: display long package descriptions instead of short ones *optional*

- `nupac list`: *Lists installed nu packages*
  - `--long(-l):`: display long package descriptions instead of short ones *optional*

- `nupac refresh`: *Refreshes the repo cache*

- `nupac remove`: *Removes provided set of packages and removes use statement from config.nu*
  - `...packages`: packages you want to remove

- `nupac search`: *Searches remote repository for packages matching query with name, descriptions or keywords*
  - `query`: query to look for
  - `--all(-a)`: display also packages unsupported by your operating system
  - `--long(-l):`: display long package descriptions instead of short ones *optional*

- `nupac upgrade`: *Upgrades all or selected packages*
  - `...packages`: packages you want to upgrade
  - `--all(-a)`: apply all available upgrades, *optional*
  - `--ignore-self(-i)`: do not upgrade nupac, *optional*
  - `--long(-l):`: display long package descriptions instead of short ones *optional*
- `nupac version`: *Displays verbose nupac version with all its metadata*
## Enviromental variables
Simple nupac config, just declare the specific variable in your env, if you want to override the default value.

- `$env.NUPAC_ADD_TO_SCRIPTS_LIST`: *If true, the scripts will be added to the aggregated list of nu scripts*
  - If not declared, nupac will act as if it's false and it will not add them to the list of scripts to maintain
- `$env.NUPAC_DEFAULT_LIB_DIR`: *A directory where nupac installs files and looks for them*
  - If not declared, scripts directory in nushell's config directory will be used
- `$env.NUPAC_IGNOREPKG`: *A list of scripts names excluded from the install/upgrade process*
  - If not declared, no script will be excluded from the install/upgrade process
- `$env.NUPAC_IGNORE_SELF`: *If true, nupac won't upgrade itself*
  - If not declared, nupac will act as if it's false and it will upgrade itself when needed
- `$env.NUPAC_NO_CONFIRM`: *If true, the user won't be prompted whether they want to proceed with the action*
  - If not declared, nupac will act as if it's false and it will prompt for a confirmation
- `$env.NUPAC_USE_LONG_DESC`: *If true, nupac will display long package descriptions*
  - If not declared, nupac will use short package descriptions
