# NUPAC
Nu package manager written entirely in nu

## Current status:
**Initial implementation done a lot of work to be done still**

## TODO
- [ ] Test thoroughly including edge cases
- [ ] Compatibility tests on Windows and MacOS
- [ ] Write automated tests for nupac itself
- [ ] Write automated tests for package submission/update
- [ ] Actually push updated nupac.json to repo on push to main
- [ ] Expand metadata generation to include authors, links to repo etc
- [ ] Add proper ci/cd flow (Run tests on PRs, add linting)
- [ ] Write our own bug and issue templates (current ones are taken from nushell repo)
- [ ] Add proper review flow (branch permissions on github, autogenerated codeowners)
- [ ] Add standalone scripts management (currently only modules are supported)
- [ ] Add template files for new submissions
- [ ] Add ignore-pkg functionality
- [ ] Add dependencies management both internal and external
- [ ] Add automated license and copyright insertion
- [ ] Add supported OS to metadata and installation flow (so stuff like winget or homebrew completion doesn't show up on Linux etc)
- [ ] Add config flags
- [ ] Add ability to specify version in dependencies
- [ ] Add (autogenerated) changelog
- [ ] Add (autogenerated) human readable package index
