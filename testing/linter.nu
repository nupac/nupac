#!/usr/bin/env nu
cd ..
ls **/*.nu
|insert lint {|x|
    if ($x.name|path dirname) == modules {
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
