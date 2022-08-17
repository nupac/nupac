#?name: nupac
#?author: [skelly37, Yethal]
#?version: 0.1.0
#?short-desc: package manager for nushell
#?long-desc: Nupac is a package manager written in nu and for nu. Source on https://github.com/skelly37/nupac
#?url: https://github.com/skelly37/nupac/blob/main/modules/nupac.nu
#?raw-url: https://raw.githubusercontent.com/skelly37/nupac/main/modules/nupac.nu
#?keywords: [package, management, manager, packages]
#?os: [android, linux, macos, windows]

# get enviroment flag's value or return false
def get-env-flag [
    name: string
] {
    $env
    |get -i $name
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

# Path where packages will be installed, can be changed to any other directory provided it is added to NU_LIB_DIRS variable
def scripts-path [] {
    $env
    |get -i "NUPAC_DEFAULT_LIB_DIR"
    |default ($nu.config-path
        |path dirname
        |path join 'scripts'
    )
}
# proxy file which holds autogenerated imports which itself should be imported by config.nu
def nu-pkgs [] {
    (scripts-path|path join 'nu-pkgs.nu')
}

# We store cache index locally to avoid redownloading it on every command invocation
def repo [] {
    (scripts-path|path join 'repo-cache.json')
}

# tweak this value if you want to change how often cache is refreshed
def freshness [] {
    1day
}

# checks if $env.NUPAC_IGNOREPKG has been declared (ignores installing and upgrading packages in the list)
def get-ignored [] {
    if ("NUPAC_IGNOREPKG" in $env) {
        $env.NUPAC_IGNOREPKG
    } else {
        []
    }
}

# returns record containing script metadata
def get-metadata [
    script: path
] {
    open $script
    |lines -s
    |where $it starts-with '#?'
    |str replace -a -s '#?' ''
    |str collect (char nl)
    |from yaml
}

# returns all packages if os-supported, else raises errors and returns empty table (temp workaround for error errors)
def packages-to-process [
    packages: table
    long: bool
] {
    let unsupported_pkgs = ($packages
        |where $nu.os-info.name not-in $it.os
    )

    let packages = (
        $packages
        |where $it not-in $unsupported_pkgs
    )

    if (not ($unsupported_pkgs|empty?)) {
        user-readable-pkg-info $unsupported_pkgs $long
        error make --unspanned {
            msg: "The listed packages cannot be installed, because OS is not supported"
        }
        []
    } else {
        $packages
    }
}

# downloads fresh repository cache
def update-repo [] {

    let branch = ($env|get -i "NUPAC_DEFAULT_BRANCH"|default 'main')

    fetch $"https://raw.githubusercontent.com/skelly37/nupac/($branch)/repo-cache.json"
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
        print "Repo cache does not exist, fetching"
        update-repo
    } else if (ls -l (repo)|get 0.modified) < ((date now) - (freshness|into duration)) {
        print $"Repo cache older than (freshness), refreshing"
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
    ls (scripts-path)
    |where ($it.name|path parse|get extension) == nu
    |each {|package|
        get-metadata (scripts-path|path join $package.name)
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
    open (nu-pkgs)
        |lines -s
        |append $content
        |str collect (char nl)
        |save (nu-pkgs)
}

# removes use statement from config on package removal
def remove-from-config [
    content: string
] {
    open (nu-pkgs)
    |lines -s
    |where $it != $content
    |str collect (char nl)
    |save (nu-pkgs)
}

# package location in the filesystem
def get-package-location [
    package: record
] {
    scripts-path
    |path join ($package.url|path basename)
}

# actual package installation happens here
def install-package [
    package: record
    add_to_scope: bool
] {
    if not ($package.pre-install-msg | empty?) {
        print "Pre-install message:"
        print ($package.pre-install-msg | into string)
    }

    print $"Installing ($package.name)"
    fetch ($package.raw-url | into string)
    |save (get-package-location $package | into string)

    if not (verify-checksum $package) {
        rm (get-package-location $package|into string)
        error make --unspanned {
          msg: "File checksum is incorrect, aborting"
        }
    }

    if $add_to_scope {
        add-to-scope (config-entry ($package.url|path basename))
    }

    if not ($package.post-install-msg | empty?) {
        print "Post-install message:"
        print ($package.post-install-msg | into string)
    }
}
# verifies whether sha checksum of the downloaded file matches the checksum in the repo cache
def verify-checksum [
    package: record
] {
    let file_checksum = (
        open (get-package-location $package | into string)
        |hash sha256
    )
    let cache_checksum = (
        open (repo)
        |where name == $package.name && short-desc == $package.short-desc
        |get -i 0.checksum
    )
    $cache_checksum == $file_checksum
}

# actual package removal happens here
def remove-package [
    package: record
] {
    print $"Uninstalling ($package.name)"
    rm -r (get-package-location $package | into string)
    remove-from-config (config-entry ($package.url|path basename))
}

# checks whether version in repo cache is newer than version in script metadata, installs newer version if yes
def upgrade-package [
    package: record
] {
    if (get-repo-contents|where name == $package.name|get -i 0.version) > $package.version {
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
    let desc = (if $long {
            "long-desc"
        } else {
            "short-desc"}
    )

    $pkgs
    |select name version author os $desc
    |update cells -c ["author" "os"] {|x| $x|str collect ', '}
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
    if $version {
        nupac version|get version
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
    let add_to_scope = (get-flag-value $add_to_scope "NUPAC_ADD_TO_SCRIPTS_LIST")
    let long = (get-flag-value $long "NUPAC_USE_LONG_DESC")

    let to_ins = ((
        packages-to-process (
            get-repo-contents
            |where name in $packages
            |where name not-in (get-ignored)
        ) $long
    ))
    if ($to_ins|empty?) {
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
    user-readable-pkg-info (get-packages --all) (get-flag-value $long "NUPAC_USE_LONG_DESC")
}

# Refreshes the repository cache
export def "nupac refresh" [] {
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
    let long = (get-flag-value $long "NUPAC_USE_LONG_DESC")

    let to_del = (get-repo-contents | where name in $packages)

    if ($to_del|empty?) {
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


# Upgrades all or selected packages
export def "nupac upgrade" [
    ...packages: string # packages to upgrade
    --all(-a): bool # upgrade all upgradeable packages
    --ignore-self(-i): bool # do not upgrade nupac
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
    # Upgrade all packages excluding nupac itself
    #> nupac upgrade --all --ignore_self
] {
    let ignore_self = (get-flag-value $ignore_self "NUPAC_IGNORE_SELF")
    let long = (get-flag-value $long "NUPAC_USE_LONG_DESC")

    if (($packages|length) > 0 or $all) {
        let to_upgrade = ( packages-to-process (
                (get-packages $packages $all)
                |where name not-in (get-ignored)
                |where name != (if $ignore_self {"nupac"} else {""})
            ) $long
        )

        if ($to_upgrade|empty?) {
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
    get-metadata (
        get-package-location (
            get-packages 'nupac'
            |get 0
        )
    )
}
