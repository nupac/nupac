## Default path
`scripts` subdirectory in the Nushell's config folder. Type `$nu.config-path|path dirname` in your shell to find it.

## Cache index
By default, the cache index refreshes after a day from previous download. 

Can be modified in `nupac.nu/freshness` but it's advised to keep it this way (one can simply use `nupac refresh` when needed). 

## Commands
- `nupac install`: *Installs provided set of packages and optionally adds them to the global scope*
  - `...packages`: packages you want to install
  - `--add-to-config(-a)`: add packages to config
