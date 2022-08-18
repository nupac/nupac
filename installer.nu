#!/usr/bin/env nu

# used to install nupac from PR branch on CI/CD
let default_branch = ($env|get --ignore-errors NUPAC_DEFAULT_BRANCH|default 'main')

let noconfirm = ($env|get --ignore-errors NUPAC_NO_CONFIRM|default false|into bool)

let nupac_module = $"https://raw.githubusercontent.com/skelly37/nupac/($default_branch)/modules/nupac.nu"

# Directory where nupac modules will be stored
let install_path = ($env|get --ignore-errors NUPAC_DEFAULT_LIB_DIRS|default $env.NU_LIB_DIRS.0)

# nupac index
let nu_pkgs = ($install_path|path join 'nu-pkgs.nu')

mkdir $install_path
fetch $nupac_module|save ($install_path|path join ($nupac_module|path basename))

if not ($nu_pkgs|path exists) {
    print 'Creating default nu-pkgs file'

    echo 'use nupac/nupac.nu *'
    |save --append $nu_pkgs

    let add_source = ($noconfirm or (input "Do you want to add nu-pkgs to your config.nu file? [y/N] "|$in in ['y' 'Y']))
    if $add_source {
        open $nu.config-path
        |lines
        |append $"source ($nu_pkgs)"
        |str collect (char nl)
        |save $nu.config-path
    } else {
        print 'You will have to source the nu-pkgs file manually'
    }
} else {
    error make --unspanned {
        msg: 'nu-pkgs already exists.'
    }
}
print 'nupac has been successfully installed'
