# ============================================================================
# Portable Zsh Common Config (macOS & Linux, managed in ~/dotfiles)
# Usage: Append this single line to any machine's ~/.zshrc:
#   [[ -f "$HOME/dotfiles/zsh/common.zsh" ]] && source "$HOME/dotfiles/zsh/common.zsh"
# ============================================================================

# Resolve dotfiles root dynamically (no hardcoded username or directory)
export DOTFILES_DIR="${DOTFILES_DIR:-${${(%):-%x}:A:h:h}}"

# Helper to prepend directory to PATH only if it exists and isn't already present
_dotfiles_add_path() {
  [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"
}

# OS-specific environment setup
case "$(uname -s)" in
  Darwin)
    # Homebrew compatibility (Apple Silicon & Intel)
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    ;;
  Linux)
    # Standard official Go tarball path on Linux (if installed without goenv)
    _dotfiles_add_path "/usr/local/go/bin"
    ;;
esac

# User local binaries & optional local Node.js (auto-enabled only if present)
_dotfiles_add_path "$HOME/.local/bin"
_dotfiles_add_path "$HOME/.local/node/bin"

# Optional goenv version manager (Option A: shared GOPATH=$HOME/go across versions)
if [[ -d "$HOME/.goenv" ]]; then
  export GOENV_ROOT="$HOME/.goenv"
  export GOENV_DISABLE_GOPATH=1
  _dotfiles_add_path "$GOENV_ROOT/bin"
fi
if (( $+commands[goenv] )); then
  eval "$(goenv init -)"
  export GOPATH="${GOPATH:-$HOME/go}"
  [[ -n "${GOROOT:-}" ]] && _dotfiles_add_path "$GOROOT/bin"
  _dotfiles_add_path "$GOPATH/bin"
else
  # Fallback Go user binaries when Go is installed without goenv
  _dotfiles_add_path "$HOME/go/bin"
fi

unset -f _dotfiles_add_path

# Quick Shell & iTerm2 cheatsheet (pretty rendered)
alias hh='python3 "$DOTFILES_DIR/scripts/vh.py" "$DOTFILES_DIR/cheatsheets/shell.md" | less -FRX'

# ============================================================================
# Oh My Zsh Theme & Plugins (safe to load even after oh-my-zsh.sh)
# ============================================================================
_omz_dir="${ZSH:-$HOME/.oh-my-zsh}"
_omz_custom="${ZSH_CUSTOM:-$_omz_dir/custom}"

# Powerlevel10k theme + portable style config
if [[ -f "$_omz_custom/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  source "$_omz_custom/themes/powerlevel10k/powerlevel10k.zsh-theme"
  if [[ -f "$DOTFILES_DIR/zsh/p10k.zsh" ]]; then
    source "$DOTFILES_DIR/zsh/p10k.zsh"
    # Fallback to clean ASCII icons in web terminals without Nerd Fonts
    if [[ "${DOTFILES_ASCII_PROMPT:-}" == "1" ]]; then
      typeset -g POWERLEVEL9K_MODE=ascii
      typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=''
      typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
      (( $+functions[p10k] )) && p10k reload
    fi
  fi
fi

# Built-in plugins (only load if installed and not already active)
if ! (( $+functions[j] )) && [[ -f "$_omz_dir/plugins/autojump/autojump.plugin.zsh" ]]; then
  if (( $+commands[autojump] )) || [[ -d "$HOME/.autojump" ]] || [[ -f /usr/share/autojump/autojump.zsh ]]; then
    source "$_omz_dir/plugins/autojump/autojump.plugin.zsh"
  fi
fi
if ! (( $+functions[sudo-command-line] )) && [[ -f "$_omz_dir/plugins/sudo/sudo.plugin.zsh" ]]; then
  source "$_omz_dir/plugins/sudo/sudo.plugin.zsh"
fi

# Third-party plugins (zsh-syntax-highlighting MUST stay last)
if ! (( $+functions[_zsh_autosuggest_start] )) && [[ -f "$_omz_custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$_omz_custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
if ! (( $+functions[_zsh_highlight] )) && [[ -f "$_omz_custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$_omz_custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

unset _omz_dir _omz_custom
