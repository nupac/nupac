#!/usr/bin/env nu
ls **/*.nu
|each {|file|
    if ($file.name|path dirname) == modules {
        nu-check --as-module $file.name
    } else {
        nu-check $file.name
    }
}
|all? $it