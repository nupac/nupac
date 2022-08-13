#!/usr/bin/env nu

def download-nu [
    version: string = latest
    --debug(-d): bool
] {
    let version = if ($version == 'latest') {'latest'} else { $"tags/($version)" }
    if $debug {print $"version is ($version)"}

    #let dir-name = ($nu.temp-path|path join (random chars))
    let dir-name = (random chars)
    if $debug {print $"dir is ($dir-name)"}

    let libc = if (ldd --version|lines|find glibc|empty?) { 'musl' } else { 'gnu' }
    if $debug {print $"libc is ($libc)"}

    let data = (
        fetch $"https://api.github.com/repos/nushell/nushell/releases/($version)"
        |get assets
        |where name =~ ($nu.os-info).name
        |where name =~ ($nu.os-info).arch
        |where name =~ $libc
        |get 0
    )
    mkdir $dir-name
    cd $dir-name
    fetch $data.browser_download_url -b -o $data.name
    tar -xf $data.name
}
download-nu latest -d
#download-nu 0.66.2
