#!/usr/bin/env nu
ls **/*.nu
|insert lint {|file|
    if 'modules' in ($file.name|path dirname) {
        nu-check --as-module $file.name
    } else {
        nu-check $file.name
    }
}
|if not ($in|all lint) {
    error make --unspanned {
        msg: $"Following files failed linter check: ($in|where not lint|get name|str collect ', ')"
    }
}
