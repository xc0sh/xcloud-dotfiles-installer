# xCloud Dotfiles Installer

An authentic, modular, and safe way to deploy Linux configurations. This script acts as a professional **Profile Manager** that allows you to manage multiple dotfile setups, handles distribution-specific dependencies for **Arch**, **Fedora**, and **openSUSE**, and uses an intelligent symlinking system with automated backups.

This is a personal fork of [mylinuxforwork/ml4w-dotfiles-installer](https://github.com/mylinuxforwork/ml4w-dotfiles-installer), rebranded and maintained independently by [xCloud](https://xcloud.gg). See [CREDITS.md](CREDITS.md) for full upstream attribution. It is the installer used by [xc0sh/dotfiles](https://github.com/xc0sh/dotfiles).

## 🚀 Key Features

* **Distro Agnostic:** Detects your package manager (Pacman, DNF, or Zypper) automatically.
* **Safe Sandbox:** Dotfiles are first copied to a local folder before being symlinked to `$HOME`.
* **Proactive Symlinking:** Automatically detects if a symlink points to a different ID and replaces it.
* **Automated Backups:** Full profile snapshots and symlink backups organized by Project ID and Timestamp.
* **Developer Friendly:** Supports local `.dotinst` files and local repository sources for rapid testing.
* **Test Mode:** Verify package installation and setup logic without touching your files.
* **User Overrides:** Support for individual user `post.sh` scripts per profile.

---

## 🛠 Installation

To install the installer script to your local system:

1. **Clone the repository.**
```bash
git clone https://github.com/xc0sh/xcloud-dotfiles-installer

```
2. **Run the installation:**
```bash
cd xcloud-dotfiles-installer
make install

```
3. **Ensure your PATH includes local bins:**
Make sure `~/.local/bin` is in your environment `$PATH`.

Alternatively, use the one-line bootstrap (installs base dependencies, clones this repo, runs `make install`, and launches the installer against xCloud Dotfiles in one step):

```bash
curl -fsSL https://raw.githubusercontent.com/xc0sh/xcloud-dotfiles-installer/main/demo/setup.sh | bash

```

---

## 📖 Usage

### Standard Installation (Remote)

To install a dotfiles profile using a remote URL:

```bash
xcloud-dotfiles-installer --install https://raw.githubusercontent.com/xc0sh/dotfiles/main/hyprland-dotfiles.dotinst

```

### Developer Installation (Local)

To test a local configuration file during development:

```bash
xcloud-dotfiles-installer --install ~/Projects/dotfiles/dev.dotinst

```

### 🧪 Test Mode (Setup Only)

Run the entire installation process—including package installation and pre/post scripts—without staging files or creating symlinks in your home directory. This is ideal for testing dependency logic on new distros:

```bash
xcloud-dotfiles-installer --install ~/Projects/dotfiles/dev.dotinst --testmode

```

---

## 🏗 For Content Creators: The `.dotinst` File

### Remote Profile Example (Production)

```json
{
  "name": "xCloud Dotfiles",
  "id": "gg.xcloud.dotfiles",
  "version": "2.16",
  "author": "xCloud",
  "homepage": "https://xcloud.gg",
  "source": "https://github.com/xc0sh/dotfiles.git",
  "subfolder": "dotfiles",
  "restore": [
    {
      "title": "Hyprland Monitor Layout",
      "source": ".config/hypr/conf/monitors.conf"
    }
  ]
}

```

---

## 🛠 Advanced Customization

### 1. Personal Overrides (User post.sh)

Users can define their own personal post-installation steps that run after the repository's standard scripts. This allows for system-specific tweaks (like enabling local services or setting hardware-specific drivers) without modifying the original dotfiles.

**To add an override:**

1. Create the profile config folder: `mkdir -p ~/.config/xcloud-dotfiles-installer/[PROFILE_ID]`
2. Create your script: `nano ~/.config/xcloud-dotfiles-installer/[PROFILE_ID]/post.sh`
3. Make it executable: `chmod +x ~/.config/xcloud-dotfiles-installer/[PROFILE_ID]/post.sh`

The installer will detect this script and run it at the very end of the setup logic.

### 2. Blacklist (File Preservation)

The blacklist allows you to prevent specific files in a profile from being overwritten during an update. This is useful for configuration files you want to manage manually or keep strictly local.

**Example:**
To prevent the installer from overwriting your local monitor setup or a specific theme file, add them to `~/.config/xcloud-dotfiles-installer/[PROFILE_ID]/blacklist`:

```text
# Blacklist Example
.config/hypr/conf/monitors.conf
.config/waybar/style.css
# You can also blacklist entire directories
.config/my-private-app/

```

Files listed here will be skipped during the staging process, preserving your local versions.

---

## 🔄 Restore & Update Logic

1. **Automatic Profile Backup:** Before updates, your profile folder is backed up to `~/.mydotfiles/backups/profile-updates/ID/<timestamp>`.
2. **Selective Restoration:** Interactive menu via `gum` to select which custom configurations to keep.
3. **Intelligent Merge:** Selected items are merged into the new source before deployment.

---

## 🛡 Safety & Backups

The installer uses a highly organized backup system:

1. **Symlink Backups:** If a file in `$HOME` is replaced, it is moved to `~/.mydotfiles/backups/[PROJECT_ID]/[TIMESTAMP]`.
2. **Active Replacement:** If the installer detects an existing symlink pointing to a *different* project ID, it proactively recreates the link to point to the currently active profile.

---

## 🧪 Testing

```bash
make test

```

Runs the `bats` test suite in `tests/` against the real `lib/helpers.sh`/`lib/utils.sh` functions (distro detection, blacklist-aware copying), with package managers stubbed via an isolated `PATH` rather than mocked as shell functions — this machine class of installer runs on real Arch/Fedora/openSUSE boxes, so the tests must not accidentally see whichever package manager the CI/dev machine actually has installed.

## 🤝 Contributing

The logic is separated into `utils.sh` and `helpers.sh` (distro/package helpers live in `helpers.sh`; symlink deployment, backup, and profile orchestration live in `utils.sh`), plus `colors.sh` for shared UI output. Feel free to add new utility functions or installation modules.
