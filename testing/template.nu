#!/usr/bin/env nu
# Use this script to view rendered Dockerfiles
# Requires jinja-cli installed
ls **/molecule.yml
|each {|file|
    open $file.name
    |get platforms
    |each {|platform|
        echo {item: $in}
        |to json
        |jinja -d - -f json ($file.name|path dirname|path join Dockerfile.j2)
    }
}
|flatten