#!/usr/bin/env nu

let REQUIRED-ATTRIBUTES = ["author" "name" "os" "short-desc" "raw-url" "url" "version"]
let DEFAULT-ATTRIBUTES = {"pre-install-msg": "",
    "post-install-msg": "",
    "keywords": [], 
    "nu-dependencies": "", 
    "installer": "",
    "os": ["android" "macos" "linux" "windows"]
}

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

def check-required-attributes [
    metadata
] {
    if (($metadata |columns| append $REQUIRED-ATTRIBUTES | uniq) != ($metadata|columns)) {
        error make {msg: $"Some required attributes not present in metadata"}
        exit 1
    }

    $REQUIRED-ATTRIBUTES
    |each { |attribute|
        $metadata
        | each { |entry|
            if ($entry|get $attribute|empty?) {
                error make {msg: $"($entry) lacks required attribute: ($attribute)"}
                exit 1
            }
        }
    }
}

def add-optional-attributes [
    metadata
] {
    $DEFAULT-ATTRIBUTES
    | merge {$metadata}
}


ls modules
|each {|module|
    let metadata = (add-optional-attributes (get-metadata $module.name))
    check-required-attributes $metadata
    echo $metadata
}
| save nupac.nuon
