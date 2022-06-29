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

def check-required-attributes [
    metadata
] {
    $metadata
    |each { |entry|
        ["author" "name" "os" "short-desc" "url" "version" "keywords"]
        |each {|attribute|
            if ($attribute not-in $entry) {
                error make {msg: $"$($entry) lacks: $($attribute)"}
                exit 1
            }
        }
    }
}

def add-optional-attributes [
    metadata
] {
    if ("name" not-in $metadata) {
                error make {msg: $"$($metadata) lacks: name"}
                exit 1
    }

    {"pre-install-msg": "",
    "post-install-msg": "",
    "keywords": $metadata.name, 
    "nu-dependencies": "", 
    "installer": "",
    "os": ["android" "macos" "linux" "windows"]}
    | merge {$metadata}
}


ls modules
|each {|module|
    let metadata = (add-optional-attributes (get-metadata $module.name))
    check-required-attributes $metadata
    echo $metadata
}
| save nupac.json