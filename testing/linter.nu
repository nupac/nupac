#!/usr/bin/env nu

let files = (ls -f **/*.nu | get name)
$files

let statuses = (
    $files
    | each { |file|
        print -n ""
        if "modules" in ($file|path dirname) {     
            nu-check --as-module $file
        } else {
            nu-check $file
        }
    }
)

$statuses

if ($statuses | any {|status| $status == false}) {
    error make --unspanned {
        msg: "nu-check failed on some files"
    }
}
