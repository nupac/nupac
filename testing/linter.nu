#!/usr/bin/env nu

let invalid_files = (
    ls -f **/*.nu
    | select name
    | insert lint-status {|file|
        if 'modules' in ($file.name|path dirname) {
            nu-check --as-module $file.name
        } else {
            nu-check $file.name
        }
    }
    | where lint-status == false
    | do -i {get name}
)

if (not ($invalid_files|is-empty)) {
    $invalid_files
    error make --unspanned {
        msg: "Listed files did not pass the nu-check lint"
    }
}