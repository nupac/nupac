#!/usr/bin/env nu

let REQUIRED_ATTRIBUTES = ["author" "name" "os" "short-desc" "raw-url" "url" "version"]
let DEFAULT_ATTRIBUTES = {"pre-install-msg": "",
    "post-install-msg": "",
    "keywords": [],
    "nu-dependencies": [],
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
    |sort
}

def check-required-attributes [
    metadata
] {
    let missing_columns = ($REQUIRED_ATTRIBUTES|where $it not-in ($metadata|columns)|str collect ", ")

    if (not ($missing_columns|empty?)) {
        error make --unspanned {
            msg: $"Required columns: ($missing-columns) not present in metadata"
        }
    }

    $REQUIRED_ATTRIBUTES
    |each { |attribute|
        $metadata
        |each { |entry|
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
    let attr = (
        $DEFAULT_ATTRIBUTES
        |merge {$metadata}
    )

    if "long-desc" not-in ($attr|columns) {
        $attr
        |insert "long-desc" $attr.short-desc
    } else {
        $attr
    }
}

ls modules
|each {|module|
    let metadata = (
        add-optional-attributes (get-metadata $module.name)
        |upsert checksum {open $module.name|hash sha256}
    )
    check-required-attributes $metadata
    echo $metadata
}
|save repo-cache.json
