# NUPAC 
Nu package manager written entirely in nu



## Name
To be discussed, just a suggestion.


## What would it do?
Download nu scripts, functions, plugins etc. and install them in valid locations (or add to config).


## How would it work?
### Server side
On server there would be a .nu file with syntax like that:

```
[
[name link version]; 
[wolfram https://raw.githubusercontent.com/nushell/nu_scripts/main/api_wrappers/wolframalpha.nu 1.0] 
[math_functions https://raw.githubusercontent.com/nushell/nu_scripts/main/maths/math_functions.nu 1.1]
]
```

In the beginning we could operate on raw plain text with source on Github. Developing kind of our own repo shouldn't be a priority.

Note that keeping such .nu would be a security measurement, since users would be able to download only code approved in PRs. It'd also save us unnecessary `from csv` calls in comparison to .csv formats. We already import nu table


### User side
1) Fetch and then keep up to date .nu from the server (like `pacman -Sy`/`apt update` updating mirrorlist)
2) Look for the query in the fetched "mirrorlist"
3) Download the file and put it in ./local/bin or source it in config.toml 

### Additional notes:
- Update would simply mean download and replace in case your version is older than the one in .nu. This could be temporarily solved by storing a .nu file with downloaded scripts and their versions locally.
- Until there's no independent built-in for extracting archives, when needed, we could use this funciton: https://github.com/nushell/nu_scripts/blob/main/data_extraction/ultimate_extractor.nu
- In the future we could add a requirement to make first line of the package a #comment actually being a description of the package. Thanks to that, users would see whether they want to download it or not. Descriptions would be populated automatically from the included packages. But that is to be implemented when the basic PoC is good to go.
- Keeping a local .nu of installed packages could help us easily find out whether the package is already installed or not, while doing something like `nupac search $package`.


## Example of downloading a script
```
let username = (whoami)
let filename = "wolframalpha"
let path = ("/home" + $username + "/.config/nu/scripts/" + $filename + ".nu")
let link = "https://raw.githubusercontent.com/nushell/nu_scripts/main/api_wrappers/wolframalpha.nu"
fetch $link | save $path
let to_echo = ($filename + " saved in " + $path)
echo $to_echo
```


## Desired output of search
```
Found 1 package!
wolfram (1.0) — WolframAlpha API wrappers written entirely in nu [not installed]
Proceed to install? [Y/n]
```

and when installed...

```
Found 1 package!
wolfram (1.0) — WolframAlpha API wrappers written entirely in nu [installed]
Proceed to reinstall? [y/N]
```


## Proposed list of commands
- `nupac install` — download to /home/$username/.config/nu/scripts and source package in config or add the script to /home/$username/./local/bin
- `nupac uninstall` — delete package and unsource it from config if needed.
- `nupac install $package to $path` — specify installation path of a package (won't be sourced)
- `nupac search` — just look for the matching package(s) in our "mirrorlist" .csv and list all packages with version, description and installation status.
- `nupac upgrade` — update "mirrorlist" .csv, then look for newer versions of packages from "installed" .csv


## TODO list and progress status:
Firstly I have to say that I'll focus on Linux development. When nupac works flawlessly on Linux, I'll start adjusting it to Windows as well. I'm going to need someone that could test and debug the script on Mac.

I'd rather have the list completed accordingly to this order but of course any help is appreciated.

- [x] Develop a way to organize needed files:
  - ~/.local/bin — for independent scripts, like for Python. 
  - ~/.config/nu/scripts — for scripts to be sourced in config.toml
  - ~/.config/nu/.nupac/ — place for 2 files:
    - packages_list.nu — list of packages in repo, format explained before
    - installed_packages.nu — self-explanatory
- [ ] Create sample template of local and server-side `.nu` files for `nupac`
  - [ ] Do it as a .nu file to `source` or do .csv file and `open mirrorlist.csv | from csv`? nu is a nice format but sourcing instead of creating a disposable, local variable seems like an overkill to me.
- [ ] `nupac install`
- [ ] `nupac search`
- [ ] `nupac uninstall`
- [ ] `nupac upgrade`
- [ ] `nupac install $package to $path`
- [ ] Start porting to Windows
- [ ] Find a tester for Mac
- [ ] Add package description from `packages_list.nu` handling for `nupac install` and `nupac search` (Mentioned [here](#desired-output-of-search))
- [ ] Write a simple documentation
- [ ] Plan and organize merging `nupac` with the [main repo](https://github.com/nushell/nushell). 
- [ ] Further development in a more or less distant future...
