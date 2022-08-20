#!/usr/bin/env nu
ls molecule/default/*.yml
|path basename --columns [name]
|where name not-in [molecule.yml, prepare.yml]
|each {|test|
    let-env TEST = $"($test.name)"
    let-env GITHUB_HEAD_REF = (git branch --show-current)
    molecule test
}
