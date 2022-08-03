# Nupac's team work & coding standards

First of all: **read thoroughly the existing documentation** before opening an issue, PR or starting some discussion. It's short but should anwser most of your questions. If you cannot read a few markdown pages, you definitely won't fit here well.

## Git(hub)

### Always squash before merge on main branch

We do not want to flood the main branch with each commit from each PR. This way the changes are better visible, one can simply launch commits and see diffs for the squashed PR commits. Also, PRs (especially draft ones) simply tend to contain trash. 

## Open issues when you want to change something in the code

Unless it's a critical hotfix, try to open issues with the desired change and proper tags, so your ideas can be discussed, contested and/or enhanced. Of course, you could also open a draft PR but you take a risk of wasting time on coding something unwanted.

## Check open PRs and issue assignees before starting to work on something

Rather self-explanatory, don't duplicate someone else's job

## Do not even think of bypassing the main branch protections

They exist for certain reasons. Don't merge without proper review & CI/CD flow. Otherwise you risk causing a disaster.

## Do not ignore priority tags

Again, they exist for a certain reason. Don't enhance docs with low priority, if there's a critical bugfix needed.


## Coding

We try to stick to (only **try** because written rules must not replace your brain and reason) the following rules (the higher position, the highest importance):

1) [KISS](https://en.wikipedia.org/wiki/KISS_principle)
2) [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
3) [Functional programming paradigm](https://en.wikipedia.org/wiki/Functional_programming#Concepts) (e.g. unnecessary state is a source of potential disaster)
4) [TDD](https://en.wikipedia.org/wiki/Test-driven_development)
5) *Nushellization*, i.e. if something can be done in *more nu way*, it should be done this way (e.g. replace jsons with nuons whenever possible)

## Testing
**TBD**