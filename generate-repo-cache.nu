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
        ["author" "name" "os" "short-desc" "url" "version"]
        |each {|attribute|
            if ($attribute not-in $entry) {
                error make {msg: "Files lack required attributes"}
                exit 1
            }
        }
    }

}


ls modules
|each {|module|
    let metadata = (get-metadata $module.name)
    check-required-attributes $metadata
}