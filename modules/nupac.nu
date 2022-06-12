#?name: nupac
#?version: 0.1.0
#?short-desc: package manager for nushell
#?long-desc: >
#?    Very long description
#?    of nushell as package manager
#?    wow so many words
#?keywords:
#? - package
#? - management

# Path where packages will be installed, can be changed to any other directory provided it is added to NU_LIB_DIRS variable
def scripts-path [] {
    $nu.config-path
    |path dirname
    |path join 'scripts'
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
    echo "placeholder"
    fetch https://raw.githubusercontent.com/skelly37/nupac/main/nupac.json
    |save (repo)
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

# returns packages with names matching provided arguments
# if no arguments were provided returns all packages
def get-packages [
    ...names
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
        } else {
            true
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
    --add-to-config(-a):bool
] {
    print $"Installing ($package.name)"
    fetch $package.script-raw-url
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
    if (get-mirrorlist|where name == $package.name|get -i 0.version) > $package.version {
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
    get-mirrorlist
    |where name in $packages
    |each {|package|
        if $add-to-config {
            install-package $package --add-to-config
        } else {
            install-package $package
        }
    }
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
    get-mirrorlist
    |where name in $packages
    |each {|package|
        remove-package $package
    }
}
# Refreshes the repo cache
export def "nupac refresh" [] {
  update-repo
}

# Searches remote repository for packages matching query
export def "nupac search" [
    query: string
    #
    # Examples:
    #
    # Search for package named example
    #> nupac search example
] {
    get-mirrorlist
    |where name =~ $query or short-desc =~ $query or long-desc =~ $query or keywords =~ $query
    |reject script-url script-raw-url
}
# Lists installed packages
export def "nupac list" [] {
    get-packages
    |move short-desc long-desc --after name
}
# Upgrades packages
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
    if ($packages|length) > 0 {
        get-packages $packages
        |where name != (if $ignore-self {'nupac'})
        |each {|package|
            print $"upgrading ($package.name)"
            upgrade-package $package
        }
    } else if $all {
        print "upgrading all packages"
        get-packages
        |where name != (if $ignore-self {'nupac'})
        |each {|package|
            print $"upgrading ($package.name)"
            upgrade-package $package
        }
    } else {
        error make {
          msg: "Either a list of packages or --all flag must be provided"
        }
    }
}
