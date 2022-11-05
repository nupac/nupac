#!/usr/bin/env nu

pip install pre-commit

fetch https://raw.githubusercontent.com/nupac/nupac/main/.pre-commit-config.yaml
|save .pre-commit-config.yaml

pre-commit install

pre-commit run --all-files
