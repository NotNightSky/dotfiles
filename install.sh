#!/usr/bin/env bash
#
# install.sh - quick setup for NotNightSky/dotfiles (Hyprland, Arch)
#
# Bootstraps a fresh machine:
#   1. packages (pacman + AUR)
#   2. zsh + powerlevel10k
#   3. dotfiles repo (~/.dotfiles, bare repo with work-tree $HOME)
#   4. neovim plugins (lazy.nvim)
#   5. spotify theme (spicetify)
#   6. font cache
#
# Usage:
#   ./install.sh [options]
#
# Options:
#   --dry-run          print commands instead of running them
#   --no-packages      skip package installation
#   --no-apps          skip the spotify/spicetify step
#   --no-nvim          skip neovim plugin installation
#   --no-shell         skip oh-my-zsh / powerlevel10k setup
#   --layout bare      dotfiles repo as bare repo + work-tree $HOME (default)
#   --layout clone     dotfiles repo as a plain clone in ~/.dotfiles
#   -h, --help         show this help
#
# Re-running is safe: files that would be overwritten are copied to
# ~/.dotfiles-backups/<timestamp>/ before they are replaced.

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/NotNightSky/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
DRY_RUN=0
DO_PACKAGES=1
DO_APPS=1
DO_NVIM=1
DO_SHELL=1
LAYOUT="bare"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

# ---------------------------------------------------------------- helpers ---

if [[ -t 1 ]]; then
	C_RESET=$'\033[0m'
	C_INFO=$'\033[38;5;110m'
	C_OK=$'\033[38;5;114m'
	C_WARN=$'\033[38;5;179m'
	C_ERR=$'\033[38;5;167m'
else
	C_RESET="" C_INFO="" C_OK="" C_WARN="" C_ERR=""
fi

log() { printf '%s[dotfiles]%s %s\n' "$C_INFO" "$C_RESET" "$*"; }
ok() { printf '%s[  ok  ]%s %s\n' "$C_OK" "$C_RESET" "$*"; }
warn() { printf '%s[ warn ]%s %s\n' "$C_WARN" "$C_RESET" "$*" >&2; }
err() { printf '%s[ fail ]%s %s\n' "$C_ERR" "$C_RESET" "$*" >&2; }
die() {
	err "$*"
	exit 1
}

run() {
	if ((DRY_RUN)); then
		printf '  %s$ %s%s\n' "$C_INFO" "$*" "$C_RESET"
		return 0
	fi
	"$@"
}

has() { command -v "$1" >/dev/null 2>&1; }

usage() {
	sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'
	exit 0
}

# ------------------------------------------------------------------ args ---

while (($#)); do
	case "$1" in
	--dry-run) DRY_RUN=1 ;;
	--no-packages) DO_PACKAGES=0 ;;
	--no-apps) DO_APPS=0 ;;
	--no-nvim) DO_NVIM=0 ;;
	--no-shell) DO_SHELL=0 ;;
	--layout)
		LAYOUT="${2:-}"
		[[ "$LAYOUT" == "bare" || "$LAYOUT" == "clone" ]] || die "unknown layout: $LAYOUT"
		shift
		;;
	-h | --help) usage ;;
	*) die "unknown option: $1 (try --help)" ;;
	esac
	shift
done

((DRY_RUN)) && log "dry run: nothing is changed"

# ------------------------------------------------------------- preflight ---

log "preflight"
has git || die "git is required"
if [[ -r /etc/os-release ]]; then
	# shellcheck disable=SC1091
	. /etc/os-release
	log "system: ${PRETTY_NAME:-unknown} (${ID:-?})"
	[[ "${ID:-}" == "arch" ]] || warn "not Arch Linux - package steps may fail"
else
	warn "/etc/os-release not found, skipping OS check"
fi

# ------------------------------------------------------------- packages ---

REPO_PACKAGES=(
	# base
	git curl wget unzip base-devel cmake ninja pkgconf
	# shell
	zsh
	# editor / terminal
	neovim kitty
	# shell tooling
	eza ripgrep fd fzf jq
	# hyprland stack
	hyprland hypridle hyprlock hyprpaper hyprpicker wofi
	quickshell swaybg mako
	# wayland helpers
	grim slurp wl-clipboard cliphist playerctl
	# portals / desktop integration
	xdg-desktop-portal xdg-desktop-portal-hyprland gvfs gvfs-mtp kdeconnect
	# audio
	pipewire pipewire-pulse wireplumber
	# network
	networkmanager
	# fonts
	inter-font ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-common
	# theming
	nwg-look kvantum qt5ct qt6ct fontconfig
	# tools used by the configs
	cava fastfetch
)

AUR_PACKAGES=(
	spotify-spicetify-cli
	powerprofilesctl
	gallery-dl
)

install_packages() {
	if ((!DO_PACKAGES)); then
		log "skipping packages (--no-packages)"
		return
	fi

	if has pacman; then
		log "installing repo packages with pacman"
		if has sudo; then
			run sudo pacman -Syu --needed --noconfirm "${REPO_PACKAGES[@]}" ||
				warn "pacman failed - install the packages manually"
		else
			warn "sudo not found - install the packages manually"
		fi
	else
		warn "pacman not found - skipping repo packages"
	fi

	local helper=""
	for candidate in paru yay pikaur; do
		if has "$candidate"; then
			helper="$candidate"
			break
		fi
	done

	if [[ -n "$helper" ]]; then
		log "installing AUR packages with $helper"
		run "$helper" -S --needed --noconfirm "${AUR_PACKAGES[@]}"
	else
		warn "no AUR helper found (paru/yay) - install manually: ${AUR_PACKAGES[*]}"
	fi
}

install_packages

# ----------------------------------------------------------- shell setup ---

install_shell() {
	if ((!DO_SHELL)); then
		log "skipping shell setup (--no-shell)"
		return
	fi
	log "setting up zsh + powerlevel10k"
	if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
		run git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
	else
		ok "oh-my-zsh already present"
	fi
	if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
		run git clone --depth 1 https://github.com/romkatv/powerlevel10k.git \
			"$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
	else
		ok "powerlevel10k already present"
	fi
}

install_shell

# --------------------------------------------------------------- dotfiles ---

BACKUP_DIR="$HOME/.dotfiles-backups/$TIMESTAMP"

backup_file() {
	# Copy an existing file into the timestamped backup tree so nothing is
	# lost when a config is overwritten or dropped.
	# $2: optional path inside the repo - when given, identical files are skipped.
	local rel="$1"
	local src="$HOME/$rel"
	[[ -e "$src" ]] || return 0
	if [[ -n "${2:-}" ]]; then
		if git --git-dir="$DOTFILES_DIR" show "HEAD:$2" 2>/dev/null | cmp -s - "$src"; then
			return 0
		fi
	fi
	run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
	run cp -a "$src" "$BACKUP_DIR/$rel"
}

setup_dotfiles() {
	if [[ "$LAYOUT" == "clone" ]]; then
		log "cloning dotfiles into $DOTFILES_DIR"
		if [[ -d "$DOTFILES_DIR/.git" ]]; then
			run git -C "$DOTFILES_DIR" pull --ff-only
		else
			run git clone "$REPO_URL" "$DOTFILES_DIR"
		fi
		deploy_clone_layout
	else
		log "setting up bare repo + work-tree at $DOTFILES_DIR"
		if [[ -d "$DOTFILES_DIR" ]] && [[ -f "$DOTFILES_DIR/HEAD" ]]; then
			ok "repo already present"
		elif [[ -e "$DOTFILES_DIR" ]]; then
			die "$DOTFILES_DIR exists but is not a git repo - move it away and re-run"
		else
			run git clone --bare "$REPO_URL" "$DOTFILES_DIR"
		fi
		run git --git-dir="$DOTFILES_DIR" config core.bare false
		run git --git-dir="$DOTFILES_DIR" config core.worktree "$HOME"
		run git --git-dir="$DOTFILES_DIR" config status.showUntrackedFiles no
		run git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" pull --ff-only ||
			warn "pull failed - continuing with the local checkout"
		deploy_bare_layout
	fi
}

deploy_clone_layout() {
	local repo="$DOTFILES_DIR"
	local file target
	[[ -d "$repo/.git" ]] || {
		warn "no clone at $repo - nothing to deploy"
		return
	}
	while IFS= read -r -d '' file; do
		case "$file" in
		*.bak | *.bak/* | *.old | *.old[0-9] | *.back) continue ;;
		esac
		[[ -f "$repo/$file" ]] || continue
		target="$HOME/$file"
		run mkdir -p "$(dirname "$target")"
		if [[ -e "$target" ]] && ! cmp -s "$repo/$file" "$target"; then
			backup_file "$file"
		fi
		run cp -a "$repo/$file" "$target"
	done < <(git -C "$repo" ls-files -z)
	ok "dotfiles deployed from $repo"
}

deploy_bare_layout() {
	local file j
	local -a junk=()
	if [[ ! -d "$DOTFILES_DIR" ]]; then
		warn "no repo at $DOTFILES_DIR - nothing to deploy"
		return
	fi
	while IFS= read -r -d '' file; do
		case "$file" in
		*.bak | *.bak/* | *.old | *.old[0-9] | *.back)
			junk+=("$file")
			continue
			;;
		esac
		backup_file "$file" "$file"
	done < <(git --git-dir="$DOTFILES_DIR" ls-tree -r --name-only -z HEAD)
	run git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" reset --hard HEAD
	# keep old backups out of the installed home, but do not delete them
	for j in "${junk[@]}"; do
		backup_file "$j"
		run rm -rf "$HOME/$j"
		run rmdir --ignore-fail-on-non-empty "$HOME/$(dirname "$j")" 2>/dev/null || true
		run git --git-dir="$DOTFILES_DIR" update-index --skip-worktree "$j"
	done
	ok "dotfiles checked out into $HOME"
}

setup_dotfiles

# ------------------------------------------------------------------ nvim ---

setup_nvim() {
	if ((!DO_NVIM)); then
		log "skipping neovim plugins (--no-nvim)"
		return
	fi
	has nvim || {
		warn "neovim not found - skipping plugin install"
		return
	}
	log "installing neovim plugins (lazy.nvim)"
	run nvim --headless "+Lazy! sync" +qa || warn "neovim plugin sync failed - open nvim once to retry"
	ok "neovim plugins synced"
}

setup_nvim

# --------------------------------------------------------------- spotify ---

setup_spotify() {
	if ((!DO_APPS)); then
		log "skipping spotify setup (--no-apps)"
		return
	fi
	if ! has spicetify; then
		warn "spicetify not found - install spotify-spicetify-cli, then run:"
		warn "  spicetify config current_theme haimiya color_scheme haimiya && spicetify apply"
		return
	fi
	if ! has spotify; then
		warn "spotify not found - install spotify, then re-run this script"
		return
	fi
	log "applying spicetify theme (haimiya)"
	run spicetify config current_theme haimiya color_scheme haimiya
	run spicetify apply || warn "spicetify apply failed - run it manually"
	ok "spicetify theme applied"
}

setup_spotify

# ----------------------------------------------------------------- fonts ---

if has fc-cache; then
	log "refreshing font cache"
	run fc-cache -f
fi

# ---------------------------------------------------------------- summary ---

cat <<EOF

$(ok "done")

next steps:
  - log out and back in (or: exec zsh) to pick up the new shell
  - set zsh as default shell:   chsh -s /usr/bin/zsh "\$USER"
  - start hyprland:             Hyprland
  - open neovim once to finish plugin setup
  - kitty theme lives in ~/.config/kitty/kitty.conf (house-dark), reload with ctrl+shift+f5
  - cava theme: haimiya (see ~/.config/cava/config)
  - fastfetch logo: ~/.config/fastfetch/Mio.png

dotfiles repo: $DOTFILES_DIR
  update:  git --git-dir=$DOTFILES_DIR --work-tree=\$HOME pull
EOF
