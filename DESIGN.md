## Default path
`scripts` subdirectory in the Nushell's config folder. Type `$nu.config-path|path dirname` in your shell to find it.

## Cache index
By default, the cache index refreshes after a day from previous download. 

Can be modified in `nupac.nu/freshness` but it's advised to keep it this way (one can simply use `nupac refresh` when needed). 

## Commands
- `nupac install`: *Installs provided set of packages and optionally adds them to the global scope*
  - `...packages`: packages you want to install
  - `--add-to-config(-a)`: add packages to config, *optional*

- `nupac remove`: *Removes provided set of packages and removes use statement from config.nu*
  - `...packages`: packages you want to remove

- `nupac refresh`: *Refreshes the repo cache*

- `nupac search`: *Searches remote repository for packages matching query with name, descriptions or keywords*
  - `query`: query to look for

- `nupac list`: *Lists installed nu packages*

- `nupac upgrade`: *Upgrades all or selected packages*
  - `...packages`: packages you want to upgrade
  - `--all(-a)`: apply all available upgrades, *optional*
  - `--ignore-self(-i)`: do not upgrade nupac

export def "nupac upgrade" [
    ...packages:string
    --all(-a)
    --ignore-self(-i)
