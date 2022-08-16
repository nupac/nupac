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
    json: path
] {
    open $json
    |sort
}

def check-required-attributes [
    metadata: record
] {
    let missing-columns = ($REQUIRED_ATTRIBUTES|where $it not-in ($metadata|columns)|str collect ", ")

    if (not ($missing-columns|empty?)) {
        error make --unspanned {
            msg: $"Required columns: ($missing-columns) not present in metadata"
        }
    }

    $REQUIRED_ATTRIBUTES
    |each { |attribute|
        $metadata
        |each { |entry|
            if ($entry|get $attribute|empty?) {
                error make --unspanned {msg: $"($entry) lacks required attribute: ($attribute)"}
            }
        }
    }

    echo $metadata
}

def add-optional-attributes [
    metadata: record
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

def get-metadata-jsons [] {
    ls modules
    |where type == dir
    |get name
    |path basename
    |each {|dir|
        ["modules" $dir ([$dir ".json"] | str collect)]
        |path join
    }
}

get-metadata-jsons
|each {|json|
    let metadata = (check-required-attributes (add-optional-attributes (get-metadata $json)))

    # otherwise the developer has to manually insert a checksum for their installer
    if ($metadata.installer|empty?) {
        $metadata
        |upsert checksum {open --raw ($json | str replace "(.+).json$" "$1.nu") | hash sha256}
        |sort
        |save $json
    }

    $metadata
    |sort
    |upsert checksum {open --raw $json | hash sha256}
}
|sort
|save repo-cache.json
