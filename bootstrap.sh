#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR]\033[0m %s\n" "$*"; }

ensure_oh_my_zsh() {
  if [ -d "${ZSH:-$HOME/.oh-my-zsh}" ]; then
    info "oh-my-zsh already present at ${ZSH:-$HOME/.oh-my-zsh}"
    return
  fi

  info "Installing oh-my-zsh into ${ZSH:-$HOME/.oh-my-zsh}"
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${ZSH:-$HOME/.oh-my-zsh}"
}

ensure_zsh_plugins() {
  local zsh_custom="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"

  # zsh-autosuggestions plugin
  local autosug_dir="$zsh_custom/plugins/zsh-autosuggestions"
  if [ -d "$autosug_dir" ]; then
    info "zsh-autosuggestions already installed"
  else
    info "Installing zsh-autosuggestions plugin"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$autosug_dir"
  fi
}

ensure_fzf() {
  if command -v fzf >/dev/null 2>&1; then
    info "fzf already installed"
    return
  fi

  if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew (brew) not found; skipping fzf install"
    return
  fi

  info "Installing fzf via Homebrew"
  if ! brew list fzf >/dev/null 2>&1; then
    if brew install fzf; then
      info "fzf installed; adding shell integration to ~/.zshrc"
      printf '\nsource <(fzf --zsh)\n' >> "$HOME/.zshrc"
    else
      warn "brew install fzf failed; install manually"
    fi
  else
    info "fzf already present in Homebrew"
  fi
}

ensure_tpm_and_plugins() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [ -d "$tpm_dir" ]; then
    info "tmux plugin manager (tpm) already installed"
  else
    info "Installing tmux plugin manager (tpm)"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  if command -v tmux >/dev/null 2>&1; then
    info "Installing tmux plugins via tpm"
    # Non-interactive plugin install
    "$tpm_dir/bin/install_plugins" || warn "tmux plugin install script failed; run Prefix+I inside tmux"
  else
    warn "tmux not found on PATH; skipping automatic tmux plugin install"
  fi
}

backup_file() {
  local target="$1"

  if [ -L "$target" ]; then
    info "Removing existing symlink: $target"
    rm "$target"
  elif [ -f "$target" ]; then
    local backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"
    warn "Backing up existing file: $target -> $backup"
    mv "$target" "$backup"
  fi
}

link_dotfile() {
  local source_rel="$1"
  local target_name="$2"

  local source="$REPO_DIR/$source_rel"
  local target="$HOME/$target_name"

  if [ ! -e "$source" ]; then
    warn "Source not found, skipping: $source_rel"
    return
  fi

  backup_file "$target"
  info "Linking $source_rel -> $target"
  ln -s "$source" "$target"
}

main() {
  info "Bootstrapping dotfiles from $REPO_DIR"

  # Core dotfiles
  link_dotfile ".zshrc" ".zshrc"
  link_dotfile ".tmux.conf" ".tmux.conf"

  # Shell framework and plugins used in .zshrc
  ensure_oh_my_zsh
  ensure_zsh_plugins

  # CLI tools
  ensure_fzf

  # Tmux plugin manager and plugins used in .tmux.conf
  ensure_tpm_and_plugins

  info "Done. Open a new shell session to pick up the changes."
}

main "$@"


