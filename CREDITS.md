# Credits

xCloud Dotfiles Installer is a rebranded personal fork of
[**ml4w-dotfiles-installer**](https://github.com/mylinuxforwork/ml4w-dotfiles-installer)
by **Stephan Raabe** ([@mylinuxforwork](https://github.com/mylinuxforwork)).

The overwhelming majority of the logic in this repository (the profile manager, the
symlink/backup system, the `.dotinst` format) originates from that upstream project.
This fork strips ML4W-specific branding and retargets install paths and the example
`.dotinst` profile for personal use — it does not represent original design work
beyond that, aside from a rewrite of `tests/test_system.bats` (the upstream test file
referenced a `lib/system.sh` and an `is_pkg_installed` function that no longer exist
in the current `lib/` layout; it was rewritten against the actual current functions).

Licensed under the GNU General Public License v3.0, same as upstream (see `LICENSE`).
Per GPLv3 section 5, this notice states that the files have been modified from the
original.

Copyright (C) 2026 Marius Kristiansen <marius@xcloud.gg> for the modifications.
Copyright (C) Stephan Raabe for the original work.

Used by [xc0sh/dotfiles](https://github.com/xc0sh/dotfiles), itself a fork of
[mylinuxforwork/dotfiles](https://github.com/mylinuxforwork/dotfiles) — see that
repository's own `CREDITS.md`.
