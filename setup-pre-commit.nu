#!/usr/bin/env nu

pip install pre-commit

pre-commit install

pre-commit run --all-files
