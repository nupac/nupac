#!/usr/bin/env nu

# used to install nupac from PR branch on CI/CD
let default_branch = ($env|get --ignore-errors NUPAC_DEFAULT_BRANCH|default "main")

let noconfirm = ($env|get --ignore-errors NUPAC_NO_CONFIRM|default false|into bool)

let nupac_repo_cache = $"https://raw.githubusercontent.com/skelly37/nupac/($default_branch)/repo-cache.json"
let nupac_module = $"https://raw.githubusercontent.com/skelly37/nupac/($default_branch)/modules/nupac/nupac.nu"
let nupac_json = $"https://raw.githubusercontent.com/skelly37/nupac/($default_branch)/modules/nupac/nupac.json"

def scripts-path [] {
    $env
    |get --ignore-errors "NUPAC_DEFAULT_LIB_DIR"
    |default (
        $nu.config-path
        |path dirname
        |path join "nupac"
    )
}

mkdir (
    (scripts-path)
    |path join "nupac"
)

# nupac index
let nu_pkgs = (
    (scripts-path)|
    path join "nu-pkgs.nu"
)

let repo_cache_path = (
    (scripts-path)|
    path join "repo-cache.json"
)

let nupac_path = (
    (scripts-path)
    |path join "nupac/nupac.nu"
    |into string
)

let nupac_json_path = (
    (scripts-path)
    |path join "nupac/nupac.json"
    |into string
)

fetch $nupac_repo_cache
|save $repo_cache_path

fetch $nupac_json
|save $nupac_json_path

let expected_json_hash = (open $repo_cache_path
    |where name == nupac
    |get checksum.0
)

let actual_json_hash = (
    open --raw $nupac_json_path
    |hash sha256
)

if ($expected_json_hash != $actual_json_hash) {
    print $"Expected: ($expected_json_hash)"
    print $"Actual:   ($actual_json_hash)"
    rm -r (scripts-path)
    error make --unspanned {msg: "nupac json checksum mismatch"}
}

fetch $nupac_module
|save $nupac_path

let expected_nupac_hash = (
    open $nupac_json_path
    |get checksum
)

let actual_nupac_hash = (
    open $nupac_path
    |hash sha256
)

if ($expected_nupac_hash != $actual_nupac_hash) {
    print $"Expected: ($expected_nupac_hash)"
    print $"Actual:   ($actual_nupac_hash)"
    rm -r (scripts-path)
    error make --unspanned {msg: "nupac checksum mismatch"}
}


if not ($nu_pkgs|path exists) {
    print 'Creating default nu-pkgs file'

    echo (["use " $nupac_path " * # added automatically by nupac"] | str collect)
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
