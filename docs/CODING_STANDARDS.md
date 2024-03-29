# Nupac's team work & coding standards

First of all: **read thoroughly the existing documentation** before opening an issue, PR or starting some discussion. It is short but should anwser most of your questions. If you cannot read a few markdown pages, you definitely will not fit here well.

Some of them are forced on you (like squash before merge) by our design, some require your cooperation. Treat this document as both code of conducut for nupac contributors but also an explanation why we do some things the certain way (and why you should either obey them or come up with better ones). We believe that design limitations are not bad as long as users know why they are limited and why they should not think of some hacky ways to baypass the limitations.

## Git(hub)

### Always squash before merge on main branch

We do not want to flood the main branch with each commit from each PR. This way the changes are better visible, one can simply launch commits and see diffs for the squashed PR commits. Also, PRs (especially draft ones) simply tend to contain trash.

## Open issues when you want to change something in the code

Unless it is a critical hotfix, try to open issues with the desired change and proper tags, so your ideas can be discussed, contested and/or enhanced. Of course, you could also open a draft PR but you take a risk of wasting time on coding something unwanted.

## Check open PRs and issue assignees before starting to work on something

Rather self-explanatory, do not duplicate someone else's job

## Do not even think of bypassing the main branch protections

They exist for certain reasons. Do not merge without proper review & CI/CD flow. Otherwise you risk causing a disaster.

## Do not ignore priority tags

Again, they exist for a certain reason. Do not enhance docs with low priority, if there is a critical bugfix needed.

## Use the suggestion mechanism whenever possible

Suggestions are more easily appliable, plus you can be credited in co-commit for a good suggestion.

## Link branch to related issue(s) before starting a PR

The issue(s) will be autoclosed on completion, so no one can pick up an already solved issue.

## Coding

We try to stick to (only **try** because written rules must not replace your brain and reason) the following rules (the higher position, the highest importance):

1) [KISS](https://en.wikipedia.org/wiki/KISS_principle)
2) [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
3) [Functional programming paradigm](https://en.wikipedia.org/wiki/Functional_programming#Concepts): (e.g. unnecessary state is a source of potential disaster)
4) [Code review](https://en.wikipedia.org/wiki/Code_review): We improve our code and talk about it as long as at least one person can find at least one line they disagree with
5) [TDD](https://en.wikipedia.org/wiki/Test-driven_development)
6) *Nushellization*: if something can be done in *more nu way*, it should be done this way (e.g. try using `fetch` instead of `wget`)
  - Exception: We use jsons instead of nuons. Nuons are not human-readable when auto-generated by nu (and they do not have pre-commit hooks fixing them). We are not a Sysiphus that would debug them manually, this is too error-prone (at least for now), sorry. Jsons make our work simply too smooth, to drop them in the current stage of development.
7) [Pre-commit](https://pre-commit.com/#install): You do not need to know pre-commit or configure it. Just run [setup-pre-commit.nu](https://github.com/skelly37/nupac/blob/main/setup-pre-commit.nu). It helps with keeping the code clean & consistent
8) Use long flags, i.e. (`--version` instead of `-v`); the code is way more clear and the reviewer does not need to read `--help` to understand what `open -r` could mean.

## Testing
### The whole interface must be tested

Does not matter if you are adding a new command or just refactoring an old one, you have to prove by tests that it works correctly.

### Run tests locally before push, if possible on your machine

Github has strict ratelimits, while we have a decent [guide](https://github.com/skelly37/nupac/blob/main/testing/TESTING.md) about testing. Of course, Github Actions exists for some reason, but it would be nice of you to catch typos on your high-end machine :)
