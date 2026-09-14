#!/usr/bin/env bats
#
# Rebrand note: the original upstream test file sourced a `lib/system.sh`
# and called `is_pkg_installed` -- neither exists anywhere in this repo
# (only lib/colors.sh, lib/helpers.sh, lib/utils.sh; the real distro-check
# entry point is get_distro_by_bin in lib/helpers.sh, and copy_with_blacklist
# is in lib/utils.sh). Rewritten against the actual current functions
# instead of carrying the stale test forward.
#
# Distro detection is isolated via a PATH that points ONLY at a per-test
# fake bin dir, not the real system PATH. Shell-function shadowing
# (pacman() { return 1; }) does NOT work here: get_distro_by_bin only
# checks `command -v pacman`, which succeeds as soon as a function of
# that name exists at all, regardless of what it returns -- and this is a
# real Arch box, so a PATH that still includes /usr/bin would find the
# genuine system pacman no matter what's stubbed alongside it.

setup() {
    source "$BATS_TEST_DIRNAME/../lib/colors.sh"
    source "$BATS_TEST_DIRNAME/../lib/helpers.sh"
    source "$BATS_TEST_DIRNAME/../lib/utils.sh"

    FAKE_BIN="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$FAKE_BIN"
}

stub() {
    for name in "$@"; do
        printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKE_BIN/$name"
        chmod +x "$FAKE_BIN/$name"
    done
}

@test "get_distro_by_bin detects arch via pacman" {
    stub pacman
    run env PATH="$FAKE_BIN" /usr/bin/bash -c "source '$BATS_TEST_DIRNAME/../lib/helpers.sh'; get_distro_by_bin"
    [ "$status" -eq 0 ]
    [ "$output" = "arch" ]
}

@test "get_distro_by_bin detects fedora via dnf when pacman is absent" {
    stub dnf
    run env PATH="$FAKE_BIN" /usr/bin/bash -c "source '$BATS_TEST_DIRNAME/../lib/helpers.sh'; get_distro_by_bin"
    [ "$status" -eq 0 ]
    [ "$output" = "fedora" ]
}

@test "get_distro_by_bin detects opensuse via zypper when pacman/dnf are absent" {
    stub zypper
    run env PATH="$FAKE_BIN" /usr/bin/bash -c "source '$BATS_TEST_DIRNAME/../lib/helpers.sh'; get_distro_by_bin"
    [ "$status" -eq 0 ]
    [ "$output" = "opensuse" ]
}

@test "get_distro_by_bin reports unknown when no package manager resolves" {
    run env PATH="$FAKE_BIN" /usr/bin/bash -c "source '$BATS_TEST_DIRNAME/../lib/helpers.sh'; get_distro_by_bin"
    [ "$status" -eq 0 ]
    [ "$output" = "unknown" ]
}

@test "get_aur_helper prefers paru over yay when both are present" {
    stub paru yay
    run env PATH="$FAKE_BIN" /usr/bin/bash -c "source '$BATS_TEST_DIRNAME/../lib/helpers.sh'; get_aur_helper"
    [ "$status" -eq 0 ]
    [ "$output" = "paru" ]
}

@test "get_aur_helper reports empty when neither paru nor yay is present" {
    run env PATH="$FAKE_BIN" /usr/bin/bash -c "source '$BATS_TEST_DIRNAME/../lib/helpers.sh'; get_aur_helper"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "install_package doesn't touch the AUR helper when pacman succeeds" {
    printf '#!/usr/bin/bash\nexec "$@"\n' > "$FAKE_BIN/sudo"
    chmod +x "$FAKE_BIN/sudo"
    printf '#!/usr/bin/bash\nexit 0\n' > "$FAKE_BIN/pacman"
    chmod +x "$FAKE_BIN/pacman"
    printf '#!/usr/bin/bash\necho "$@" > "%s/paru-called-with"\nexit 0\n' "$BATS_TEST_TMPDIR" > "$FAKE_BIN/paru"
    chmod +x "$FAKE_BIN/paru"

    run env PATH="$FAKE_BIN" /usr/bin/bash -c "source '$BATS_TEST_DIRNAME/../lib/colors.sh'; source '$BATS_TEST_DIRNAME/../lib/helpers.sh'; install_package jq"
    [ "$status" -eq 0 ]
    [ ! -f "$BATS_TEST_TMPDIR/paru-called-with" ]
}

@test "install_package falls back to the AUR helper when pacman can't find the package" {
    # Absolute-path shebangs, not `#!/usr/bin/env bash`: these stubs (unlike
    # stub()'s exit-0 ones above, only ever probed via `command -v`) are
    # actually executed, and `env` would look up `bash` using the very
    # PATH we've overridden to just $FAKE_BIN.
    #
    # sudo just execs through -- this stub environment isn't testing
    # privilege elevation, only the pacman-fails -> AUR-helper-tried path.
    printf '#!/usr/bin/bash\nexec "$@"\n' > "$FAKE_BIN/sudo"
    chmod +x "$FAKE_BIN/sudo"
    # Real pacman exits non-zero for a package not in any configured repo.
    printf '#!/usr/bin/bash\nexit 1\n' > "$FAKE_BIN/pacman"
    chmod +x "$FAKE_BIN/pacman"
    printf '#!/usr/bin/bash\necho "$@" > "%s/paru-called-with"\nexit 0\n' "$BATS_TEST_TMPDIR" > "$FAKE_BIN/paru"
    chmod +x "$FAKE_BIN/paru"

    run env PATH="$FAKE_BIN" /usr/bin/bash -c "source '$BATS_TEST_DIRNAME/../lib/colors.sh'; source '$BATS_TEST_DIRNAME/../lib/helpers.sh'; install_package hadolint-bin"
    [ "$status" -eq 0 ]
    [ "$(cat "$BATS_TEST_TMPDIR/paru-called-with")" = "-S --needed --noconfirm hadolint-bin" ]
}

@test "install_package fails clearly when pacman can't find the package and no AUR helper exists" {
    printf '#!/usr/bin/bash\nexec "$@"\n' > "$FAKE_BIN/sudo"
    chmod +x "$FAKE_BIN/sudo"
    printf '#!/usr/bin/bash\nexit 1\n' > "$FAKE_BIN/pacman"
    chmod +x "$FAKE_BIN/pacman"

    run env PATH="$FAKE_BIN" /usr/bin/bash -c "source '$BATS_TEST_DIRNAME/../lib/colors.sh'; source '$BATS_TEST_DIRNAME/../lib/helpers.sh'; install_package hadolint-bin"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no AUR helper"* ]]
}

@test "copy_with_blacklist copies normal files and preserves blacklisted ones" {
    src="$BATS_TEST_TMPDIR/src"
    dst="$BATS_TEST_TMPDIR/dst"
    mkdir -p "$src/keep-me"
    echo "new-content" > "$src/normal.txt"
    echo "new-secret" > "$src/keep-me/local.conf"

    # Existing target already has a locally-modified version of the
    # blacklisted file, which must survive the copy untouched.
    mkdir -p "$dst/keep-me"
    echo "old-local-content" > "$dst/keep-me/local.conf"

    blacklist="$BATS_TEST_TMPDIR/blacklist"
    echo "keep-me/local.conf" > "$blacklist"

    run copy_with_blacklist "$src" "$dst" "$blacklist"
    [ "$status" -eq 0 ]
    [ "$(cat "$dst/normal.txt")" = "new-content" ]
    [ "$(cat "$dst/keep-me/local.conf")" = "old-local-content" ]
}
