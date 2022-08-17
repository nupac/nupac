#!/usr/bin/env nu
ls **/*.nu
|insert lint {|x|
    if 'modules' in ($x.name|path dirname) {
        nu-check --as-module $x.name
    } else {
        nu-check $x.name
    }
}
|if not ($in|all? lint) {
    error make --unspanned {
        msg: $"Following files failed linter check: ($in|where not lint|get name|str collect ', ')"
    }
}
