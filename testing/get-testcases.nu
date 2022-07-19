#!/usr/bin/env nu
# This script generates list of tests to run by Github Actions
ls **/molecule/default/*.yml
|get name
|path parse
|where stem not-in [molecule prepare]
|get stem
|to json -r
|print $"::set-output name=matrix::($in)"
