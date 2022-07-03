#!/usr/bin/env nu
# Use this script to view rendered Dockerfiles
# Requires jinja-cli installed
open molecule.yml
|get platforms
|each {|item|
    echo {item: $item}
    |to json
    |jinja -d - -f json Dockerfile.j2
}