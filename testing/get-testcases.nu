#!/usr/bin/env nu
# This script generates list of tests to run by Github Actions
ls **/molecule/default/*.yml
|get name
|path basename
|where $it not-in [prepare.yml molecule.yml throws-error-on-checksum-mismatch.yml]
|to json --raw
|print $"::set-output name=matrix::($in)"
