def get_mirrorlist [] {
	let LINK = https://raw.githubusercontent.com/skelly37/nupac/main/mirrorlist.nu
	echo "Updating mirrorlist..."
	(fetch https://raw.githubusercontent.com/skelly37/nupac/main/mirrorlist.nu) | save /tmp/nu_mirrorlist.nu
	if (echo /tmp/nu_mirrorlist.nu | path exists) {
		source /tmp/nu_mirrorlist.nu
		echo $mirrorlist
	} { echo "Error fetching mirrorlist" }
}
