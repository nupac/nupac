#!/usr/bin/env nu
ls molecule/default/*.yml
|path basename --columns [name]
|where name not-in [molecule.yml, prepare.yml]
|each {|test|
    with-env [TEST $"($test.name)"] {
        molecule test
    }
}
