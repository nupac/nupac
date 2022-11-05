# get enviroment flag's value or return false
def get-env-flag [
    name: string
] {
    $env
    |get --ignore-errors $name
    |default false
}

# Specified value, env value or hardcoded value of the flag
def get-flag-value [
    flag: bool
    env_var: string
] {
    if ($flag) {
        true
    } else {
        get-env-flag $env_var
    }
}

# Nupac base directory, can be changed to any other directory provided it is added to NU_LIB_DIRS variable
def nupac-path [] {
    $env
    |get --ignore-errors "NUPAC_DEFAULT_LIB_DIR"
    |default (
        $nu.config-path
        |path dirname
        |path join "nupac"
    )
}

# Directory where per-package subdirs are created
def packages-path [] {
    nupac-path
    |path join 'packages'
}

# proxy file which holds autogenerated imports which itself should be imported by config.nu
def nu-pkgs [] {
    nupac-path
    |path join 'nu-pkgs.nu'
}

# We store cache index locally to avoid redownloading it on every command invocation
def repo [] {
    nupac-path
    |path join 'repo-cache.json'
}

# tweak this value if you want to change how often cache is refreshed
def freshness [] {
    1day
}

# checks if $env.NUPAC_IGNOREPKG has been declared (ignores installing and upgrading packages in the list)
def get-ignored [] {
    get --ignore-errors "NUPAC_IGNOREPKG"
    |default []
}

# returns record containing script metadata
def get-metadata [
    package_name: string
] {
    open (
        [(packages-path) $package_name "metadata.json"]
        |path join
    )
}

# returns all packages if os-supported, else raises errors and returns empty table (temp workaround for error errors)
def packages-to-process [
    packages: table
    long: bool
] {
    let unsupported_pkgs = (
        $packages
        |where $nu.os-info.name not-in $it.os
    )

    let packages = (
        $packages
        |where $it not-in $unsupported_pkgs
    )

    if (not ($unsupported_pkgs|is-empty)) {
        user-readable-pkg-info $unsupported_pkgs $long
        error make --unspanned {
            msg: "The listed packages cannot be installed, because OS is not supported"
        }
    } else {
        $packages
    }
}

# downloads fresh repository cache
def update-repo [] {
    fetch $"https://raw.githubusercontent.com/nupac/packages/main/repo-cache.json"
    |save (repo)

    if ($env.LAST_EXIT_CODE == 0) {
        print "Repository cache updated successfully"
    } else {
        error make --unspanned {
            msg: "Could not update the repository cache"
        }
    }
}

# returns cached contents of nupac repo
def get-repo-contents [] {
    if not (repo|path exists) {
        print "Repository cache does not exist, fetching"
        update-repo
    } else if (ls --long (repo)|get 0.modified) < ((date now) - (freshness|into duration)) {
        print $"Repository cache older than (freshness), refreshing"
        update-repo
    } else {
        ignore
    }
    open (repo)
}

# whether the action was approved or not
def user-approves [] {
    if (get-env-flag "NUPAC_NO_CONFIRM"|into bool) {
        true
    } else {
        input "Do you want to proceed? [Y/n] "
        |$in in ['' 'y' 'Y']
    }
}

# returns packages with names matching provided arguments
# if no arguments were provided returns all packages
def get-packages [
    ...names: string
    --all: bool
] {
    ls (packages-path)
    |where type == dir
    |get name
    |path basename
    |each {|package|
        get-metadata $package
    }
    |where {|it|
        if ($names|length) > 0 {
            $it.name in $names
        } else if $all {
            true
        } else {
            false
        }
    }
}

# returns formatted use statement that is added to config.nu on package installation
def config-entry [
    package: string
] {
    $"use ($package) * # added automatically by nupac"
}

# adds use statement to config so the package is available in global scope
def add-to-scope [
    content: string
] {
    if (not ((nu-pkgs) | path exists)) {
        touch (nu-pkgs)
    }

    open (nu-pkgs)
    |lines --skip-empty
    |append $content
    |uniq
    |str collect (char nl)
    |save (nu-pkgs)
}

# removes use statement from config on package removal
def remove-from-config [
    content: string
] {
    if ((nu-pkgs) | path exists) {
        open (nu-pkgs)
        |lines --skip-empty
        |where $it != $content
        |str collect (char nl)
        |save (nu-pkgs)
    }
}

# parent folder of the package location
def get-package-parent [
    package: record
] {
    [(packages-path) $package.name]
    |path join
}

# package location in the filesystem relative to nupac base dir
def get-package-location [
    package: record
] {
    [(get-package-parent $package) ($package.url|path basename)]
    |path join
}

# actual package installation happens here
def install-package [
    package: record
    add_to_scope: bool
] {
    if not ($package.pre-install-msg | is-empty) {
        print "Pre-install message:"
        print ($package.pre-install-msg | into string)
    }

    print $"Installing ($package.name)"
    (get-package-location $package | into string)
    mkdir (get-package-parent $package| into string)
    fetch ($package.raw-url | into string)
    |save (get-package-location $package | into string)
    fetch ($package.raw-url | into string | str replace --string (($package.name|into string) + ".nu") "metadata.json")
    |save (get-package-location $package | into string | str replace --string (($package.name|into string) + ".nu") "metadata.json")

# TODO:
# 1) compare json sha256 with the one in repo
# 2) compare nu sha256 with the one in json

    #if not (verify-checksum $package) {
    #    remove-package $package.name
    #    error make --unspanned {
    #      msg: "File checksum is incorrect, aborting"
    #    }
    #}

    if $add_to_scope {
        add-to-scope (config-entry ((get-package-location $package) | into string))
    }

    if not ($package.post-install-msg | is-empty) {
        print "Post-install message:"
        print ($package.post-install-msg | into string)
    }
}
# verifies whether sha checksum of the downloaded file matches the checksum in the repo cache
#def verify-checksum [
#    package: record
#] {
#    let file_checksum = (
#        open (get-package-location $package | into string)
#        |hash sha256
#    )
#    let cache_checksum = (
#        open (repo)
#        |where name == $package.name && short-desc == $package.short-desc
#        |get --ignore-errors 0.checksum
#    )
#    $cache_checksum == $file_checksum
#}

# actual package removal happens here
def remove-package [
    package: record
] {
    print $"Uninstalling ($package.name)"
    rm --recursive (get-package-parent $package | into string)
    remove-from-config (config-entry ((get-package-location $package) | into string))
}

# checks whether version in repo cache is newer than version in script metadata, installs newer version if yes
def upgrade-package [
    package: record
] {
    if (get-repo-contents|where name == $package.name|get --ignore-errors 0.version) > $package.version {
        print $"Upgrading package ($package.name)"
        install-package $package.name false
    } else {
        print $"Package ($package.name) up to date, not upgrading"
    }
}

# display info about the package for the user
def user-readable-pkg-info [
    pkgs: table
    long: bool
] {
    let desc = (
        if $long {
            "long-desc"
        } else {
            "short-desc"}
    )

    $pkgs
    |select name version author os $desc
    |update cells --columns ["author" "os"] {|x| $x|str collect ', '}
    |rename name version "author(s)" "supported OS" description
}

# prompt user what's going to be done
def display-action-data [
    pkgs: table
    action: string
    long: bool
] {
    let action = if ($action|str ends-with "e") {
        $action
    } else {
        $action + "e"
    }

    print (user-readable-pkg-info $pkgs $long)
    print ($"The listed packages will be ($action)d")
}

# Nushell package manager
export def "nupac" [
    --version(-v): bool # Display nupac version instead of help
    --help(-h): bool # Display this help message
] {
    mkdir (nupac-path)

    if $version {
        nupac version
        |get version
    } else {
        nupac --help
    }
}

# Installs provided set of packages and optionally adds them to the global scope
export def "nupac install" [
    ...packages: string # packages to install
    --add-to-scope(-a): bool # add packages to config
    --long(-l): bool # display long package descriptions instead of short ones
    #
    # Examples:
    #
    # Install package named example
    #> nupac install example
    #
    # Install packages example, second-example and third-example
    #> nupac install example second-example third-example
    #
    # Install package named example and add it to global scope
    #> nupac install example -a
] {
    mkdir (nupac-path)

    let add_to_scope = (get-flag-value $add_to_scope "NUPAC_ADD_TO_SCRIPTS_LIST")
    let long = (get-flag-value $long "NUPAC_USE_LONG_DESC")

    let to_ins = ((
        packages-to-process (
            get-repo-contents
            |where name in $packages
            |where name not-in (get-ignored)
        ) $long
    ))
    if ($to_ins|is-empty) {
        print "No packages to install"
    } else {
        display-action-data $to_ins "install" $long
        if (user-approves) {
            $to_ins
            |each {|package|
                install-package $package $add_to_scope
            }
        }
    }
}

# Lists installed packages
export def "nupac list" [
    --long(-l): bool # display long package descriptions instead of short ones
] {
    mkdir (nupac-path)
    user-readable-pkg-info (get-packages --all) (get-flag-value $long "NUPAC_USE_LONG_DESC")
}

# Refreshes the repository cache
export def "nupac refresh" [] {
  mkdir (nupac-path)
  update-repo
}

# Removes provided set of packages and removes use statement from nu-pkgs.nu
export def "nupac remove" [
    ...packages: string # packages to remove
    --long(-l): bool # display long package descriptions instead of short ones
    #
    # Examples:
    #
    # Remove package named example
    #> nupac remove example
    #
    # Remove packages example, second-example and third-example
    #> nupac remove example second-example third-example
] {
    mkdir (nupac-path)

    let long = (get-flag-value $long "NUPAC_USE_LONG_DESC")

    let to_del = (get-repo-contents | where name in $packages)

    if ($to_del|is-empty) {
        print "No packages to remove"
    } else {
        display-action-data $to_del "remove" $long

        if (user-approves) {
            $to_del
            |each {|package|
                remove-package $package
            }
        }
    }
}

# Searches remote repository for packages matching query with name, descriptions or keywords
export def "nupac search" [
    query: string
    --all(-a): bool # display also packages unsupported by your operating system
    --long(-l): bool # display long package descriptions instead of short ones
    #
    # Examples:
    #
    # Search for package named example
    #> nupac search example
    #
    # Search for package named example and display also packages unsupported by your OS
    #> nupac search example --all
] {
    mkdir (nupac-path)

    let long = (get-flag-value $long "NUPAC_USE_LONG_DESC")

    let found = (
        get-repo-contents
        |where name =~ $query or short-desc =~ $query or long-desc =~ $query or $query in keywords or $query in author
    )

    if $all {
        user-readable-pkg-info $found $long
    } else {(
        user-readable-pkg-info (
            $found
            |where $nu.os-info.name in $it.os
        ) $long
    )}
}

# Installs the latest version of nupac (either upgrade or re-install)
export def "nupac self-upgrade" [] {
    let default_branch = ($env|get --ignore-errors NUPAC_DEFAULT_BRANCH|default "refactor/metadata-jsons")
    let nupac_module = $"https://raw.githubusercontent.com/nupac/nupac/($default_branch)/nupac.nu"
    let nupac_json = $"https://raw.githubusercontent.com/nupac/nupac/($default_branch)/metadata.json"

    let install_path = ($env
        |get --ignore-errors "NUPAC_DEFAULT_LIB_DIR"
        |default (
            $nu.config-path
            |path dirname
            |path join "nupac"
        )
        |path join "packages"
        |path join "nupac"
    )

    print "Upgrading nupac..."
    print ("Currently installed version: " + (nupac -v | into string))

    fetch $nupac_module
    |save ($install_path | path join "nupac.nu")

    fetch $nupac_module
    |save ($install_path | path join "metadata.json")

    print ("Newly installed version: " + (nupac -v | into string))
}

# Upgrades all or selected packages
export def "nupac upgrade" [
    ...packages: string # packages to upgrade
    --all(-a): bool # upgrade all upgradeable packages
    --long(-l): bool # display long package descriptions instead of short ones
    #
    # Examples:
    #
    # Upgrade package named example
    #> nupac upgrade example
    #
    # Upgrade packages example, second-example and third-example
    #> nupac upgrade example second-example third-example
    #
    # Upgrade all packages
    #> nupac upgrade --all
    #
] {
    if ("nupac" in $packages) {
        error make --unspanned {
          msg: "To upgrade nupac, use: nupac self-upgrade"
        }
    }

    mkdir (nupac-path)

    let long = (get-flag-value $long "NUPAC_USE_LONG_DESC")

    if (($packages|length) > 0 or $all) {
        let to_upgrade = ( packages-to-process (
                (get-packages $packages $all)
                |where name not-in (get-ignored)
                |where name != "nupac"
            ) $long
        )

        if ($to_upgrade|is-empty) {
            print "No upgrades found"
        } else {
            display-action-data $to_upgrade "upgrade" $long

            if (user-approves) {
                $to_upgrade
                |each {|package|
                    upgrade-package $package
                }
            }
        }
    } else {
        error make --unspanned {
          msg: "Either a list of packages or --all flag must be provided"
        }
    }
}

# displays nupac's version
export def "nupac version" [] {
    mkdir (nupac-path)
    get-metadata "nupac"
}
