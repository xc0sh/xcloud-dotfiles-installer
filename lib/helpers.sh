#!/usr/bin/env bash

# --- Helper to identify the Linux distro ---
get_distro_by_bin() {
    if command -v pacman &> /dev/null; then echo "arch";
    elif command -v dnf &> /dev/null; then echo "fedora";
    elif command -v zypper &> /dev/null; then echo "opensuse";
    else echo "unknown"; fi
}

# --- Helper to find an installed AUR helper, if any ---
get_aur_helper() {
    if command -v paru &> /dev/null; then echo "paru";
    elif command -v yay &> /dev/null; then echo "yay";
    else echo ""; fi
}

# --- Helper to install a package disto agnostic. On Arch, packages not in
# the official repos (pacman exits non-zero, e.g. "target not found") fall
# back to an installed AUR helper (paru preferred, then yay) so AUR-only
# entries in setup/dependencies/packages* actually install instead of
# silently failing. If no AUR helper is present, error clearly rather than
# leaving the caller to guess why a package never showed up. ---
install_package() {
    local pkg=$1; local distro=$(get_distro_by_bin)
    case "$distro" in
        arch)
            if sudo pacman -S --needed --noconfirm "$pkg" 2> /dev/null; then
                return 0
            fi
            local aur_helper
            aur_helper=$(get_aur_helper)
            if [ -n "$aur_helper" ]; then
                info "  - $pkg not in the official repos, trying AUR via $aur_helper..."
                "$aur_helper" -S --needed --noconfirm "$pkg"
                return $?
            fi
            error "$pkg is not in the official repos, and no AUR helper (paru/yay) is installed to fall back to. Install paru or yay, or install $pkg manually."
            return 1
            ;;
        fedora) sudo dnf install -y "$pkg" ;;
        opensuse) sudo zypper install -y "$pkg" ;;
    esac
}

# --- Helper to check command and install if not available ---
check_and_install() {
    local cmd=$1; local pkg=$2
    if command -v "$cmd" &> /dev/null; then return 0; fi

    warn "✗ $cmd is not installed. Installing now..."
    install_package "$pkg"

    # echo -n -e "${YELLOW}Do you want to install $pkg now? (y/n): ${NC}" >&2
    # read -r response
    # if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    #     eval "$install_cmd"
    # else
    #     error "Required tool $pkg missing. Exiting."; exit 1
    # fi
}

# --- Helper to get content from URL or Local File ---
get_json_content() {
    local source=$1
    if [[ "$source" =~ ^https?:// ]]; then
        curl -sL "$source"
    elif [ -f "$source" ]; then
        cat "$source"
    else
        return 1
    fi
}
