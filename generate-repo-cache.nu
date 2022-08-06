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
    metadata_nuon: path
] {
    open $metadata_nuon
}

def check-required-attributes [
    metadata
] {
    let missing-columns = ($REQUIRED_ATTRIBUTES|where $it not-in ($metadata|columns)|str collect ", ")

    if (not ($missing-columns|empty?)) {
        error make {msg: $"Required columns: ($missing-columns) not present in metadata"}
        exit 1
    }

    $REQUIRED_ATTRIBUTES
    |each { |attribute|
        $metadata
        |each { |entry|
            if ($entry|get $attribute|empty?) {
                error make {msg: $"($entry) lacks required attribute: ($attribute)"}
            }
        }
    }

    echo $metadata
}

def add-optional-attributes [
    metadata
] {
    $DEFAULT_ATTRIBUTES
    |merge {$metadata}
}

do -i {rm repo-cache.nuon}

ls modules
|where type == dir
|get name
|each {|it|
    ls $it
    |get name
    |where $it =~ "*.nuon"
    |each {|module|
        check-required-attributes (add-optional-attributes (get-metadata $module))
        |to nuon
        |save repo-cache.nuon --append
    }
}
