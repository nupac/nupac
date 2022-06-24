#?name: nupac
#?version: 0.1.0
#?short-desc: package manager for nushell
#?long-desc: >
#?    Very long description
#?    of nushell as package manager
#?    wow so many words
#?url: https://github.com/skelly37/nupac/blob/main/modules/nupac.nu
#?script-raw-url: https://raw.githubusercontent.com/skelly37/nupac/main/modules/nupac.nu
#?keywords:
#? - package
#? - management

# If the enviroment variable exists
def is-in-env [name: string] {
    not ($env | get -i name | empty?)
}

# Specified value, env value or hardcoded value of the flag
def get-flag-value [
    flag: bool
    env-var: string
    ] {
    if ($flag) {
        true
    } else if (is-in-env $env-var) {
        $env | get $env-var
    } else {
        false
    }
}

# Path where packages will be installed, can be changed to any other directory provided it is added to NU_LIB_DIRS variable
def scripts-path [] {
    if (is-in-env "NUPAC_DEFAULT_LIB_DIR") {
        $env.NUPAC_DEFAULT_LIB_DIR
    } else {
        $nu.config-path
        |path dirname
        |path join 'scripts'
    }
    
}

# We store cache index locally to avoid redownloading it on every command invocation
def repo [] {
    (scripts-path|path join 'nupac.json')
}

# tweak this value if you want to change how often cache is refreshed
def freshness [] {
    1day
}
# sets the keywords field to empty string if missing to maintain data shape across packages
def keywords [] {
    upsert keywords {|x|
        if 'keywords' not-in ($x|columns) {
            ' '
        } else if ($x.keywords|describe) starts-with list {
            $x.keywords|str collect ', '
        } else {
            $x.keywords
        }
    }
}

# checks if $env.NUPAC_IGNOREPKG has been declared (ignores installing and upgrading packages in the list)
def get-ignored [] {
    if "NUPAC_IGNOREPKG" in (env).name {
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

# downloads fresh repository cache
def update-repo [] {
    fetch https://raw.githubusercontent.com/skelly37/nupac/main/nupac.json
    |save (repo)

    if ($env.LAST_EXIT_CODE == 0) {
        print "Repository cached updated successfully"
    } else {
        print "Error updating the repository cache"
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
    |keywords
}

# whether the action was approved or not
def user-approves [] {
    if (($env | get -i "NUPAC_NO_CONFIRM") == true) {
        true
    } else {
        input "Do you want to proceed? [Y/n]"
        |$in in ['' 'y' 'Y']
    }
}

# returns packages with names matching provided arguments
# if no arguments were provided returns all packages
def get-packages [
    ...names
    --all
] {
    ls (scripts-path)
    |where ($it.name|path parse|get extension) == nu
    |each {|package|
     get-metadata (scripts-path|path join $package.name)
    }
    |keywords
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
def add-to-config [
    content: string
] {
    open $nu.config-path
        |lines -s
        |append $content
        |str collect (char nl)
        |save $nu.config-path
}

# removes use statement from config on package removal
def remove-from-config [
    content: string
] {
    open $nu.config-path
    |lines -s
    |where $it != $content
    |str collect (char nl)
    |save $nu.config-path
}

# actual package installation happens here
def install-package [
    package: record
    --add-to-config(-a): bool
] {
    print $"Installing ($package.name)"
    fetch ($package.script-raw-url | into string)
    |save (scripts-path|path join ($package.script-url|path basename))

    if $add-to-config {
        add-to-config (config-entry ($package.script-url|path basename))
    }
}
# actual package removal happens here
def remove-package [
    package: record
] {
    print $"Uninstalling ($package.name)"
    rm -r (scripts-path|path join ($package.script-url|path basename))
    remove-from-config (config-entry ($package.script-url|path basename))
}

# checks whether version in repo cache is newer than version in script metadata, installs newer version if yes
def upgrade-package [
    package: record
] {
    if (get-repo-contents|where name == $package.name|get -i 0.version) > $package.version {
        print $"Upgrading package ($package.name)"
        install-package $package.name
    } else {
        print $"Package ($package.name) up to date, not upgrading"
    }
}

# Installs provided set of packages and optionally adds them to the global scope
export def "nupac install" [
    ...packages: string # packages you want to install
    --add-to-config(-a):bool # add packages to config
    #
    # Examples:
    #
    # Install package named example
    #> nupac install example
    #
    # Install packages example, second-example and third-example
    #> nupac install example second-example third-example
    #
    # Installs package named example and adds it to global scope
    #> nupac install example -a
] {
    let add-to-config = (get-flag-value $add-to-config "NUPAC_ADD_TO_SCRIPTS_LIST")

    let to-ins = (
    get-repo-contents 
    |where name in $packages
    |where name not-in (get-ignored)
    )

    if ($to-ins|empty?) {
        print "No packages to install"
    } else {
        print ($to-ins | select name version)
        print "The listed packages will be installed"

        if (user-approves) {
            if $add-to-config {
                $to-ins
                |each {|package|
                    install-package $package --add-to-config
                } 
            } else {
                $to-ins
                |each {|package|    
                install-package $package
                }
            }
        }
    }   
}

# Lists installed packages
export def "nupac list" [] {
    get-packages
    |move short-desc long-desc --after name
}

# Refreshes the repo cache
export def "nupac refresh" [] {
  update-repo
}

# Removes provided set of packages and removes use statement from config.nu
export def "nupac remove" [
    ...packages: string
    #
    # Examples:
    #
    # Remove package named example
    #> nupac remove example
    #
    # Remove packages example, second-example and third-example
    #> nupac remove example second-example third-example
] {
    let to-del = (get-repo-contents | where name in $packages)
    
    if ($to-del|empty?) {
        print "No packages to remove"
    } else {
        print ($to-del | select name version)
        print "The listed packages will be removed"
        
        if (user-approves) {
            $to-del
            |each {|package|
            remove-package $package
            }
        }
    }
}

# Searches remote repository for packages matching query with name, descriptions or keywords
export def "nupac search" [
    query: string
    #
    # Examples:
    #
    # Search for package named example
    #> nupac search example
] {
    get-repo-contents
    |where name =~ $query or short-desc =~ $query or long-desc =~ $query or keywords =~ $query
    |reject script-url script-raw-url
}


# Upgrades all or selected packages
export def "nupac upgrade" [
    ...packages:string
    --all(-a)
    --ignore-self(-i)
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
    #> nupac upgrade --all --ignore-self
] {
    let ignore-self = (get-flag-value $ignore-self "NUPAC_IGNORE_SELF")

    if (($packages|length) > 0 or $all) {
        let to_upgrade = (
            (get-packages $packages $all)
            |where name not-in (get-ignored)
            |where name != (if $ignore-self {"nupac"} else {""})
        )

        if ($to_upgrade|empty?) {
            print "No upgrades found"
        } else {
            print ($to_upgrade | select name version)
            print "The listed packages will be upgraded"

            if (user-approves) {
                $to_upgrade
                |each {|package|
                upgrade-package $package
                }
            }
        }
    } else {
        error make {
          msg: "Either a list of packages or --all flag must be provided"
        }
    }
}
