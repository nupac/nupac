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

def required-attributes [] {
    echo ["author" "name" "os" "short-desc" "raw-url" "url" "version"]
}

def check-required-attributes [
    metadata
] {
    required-attributes
    |each { |attribute|
            if ($attribute not-in ($metadata|columns)) {
                error make {msg: $"$($attribute) not present in metadata"}
                exit 1
            } else {
                $metadata
                | each { |entry|
                    if ($entry|get $attribute|empty?) {
                        error make {msg: $"($entry) lacks required attribute: ($attribute)"}
                        exit 1
                    }
                }
            }
        }
}

def default-attributes [] {
    {"pre-install-msg": "",
    "post-install-msg": "",
    "keywords": [], 
    "nu-dependencies": "", 
    "installer": "",
    "os": ["android" "macos" "linux" "windows"]}
}

def add-optional-attributes [
    metadata
] {
    default-attributes
    | merge {$metadata}
}


ls modules
|each {|module|
    let metadata = (add-optional-attributes (get-metadata $module.name))
    check-required-attributes $metadata
    echo $metadata
}
| save nupac.json
