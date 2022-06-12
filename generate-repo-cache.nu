#!/usr/bin/env nu

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

ls modules
|each {|module|
    get-metadata $module.name
}
|save nupac.json