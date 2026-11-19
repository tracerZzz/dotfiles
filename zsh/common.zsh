# ============================================================================
# Portable Zsh Common Config (managed in ~/dotfiles)
# Usage: Append this single line to any machine's ~/.zshrc:
#   [[ -f "$HOME/dotfiles/zsh/common.zsh" ]] && source "$HOME/dotfiles/zsh/common.zsh"
# ============================================================================

# Resolve dotfiles root dynamically (no hardcoded username or directory)
export DOTFILES_DIR="${DOTFILES_DIR:-${${(%):-%x}:A:h:h}}"

# Homebrew compatibility (Apple Silicon & Intel)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# User local binaries (avoid duplicate PATH entries)
if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

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
  [[ -f "$DOTFILES_DIR/zsh/p10k.zsh" ]] && source "$DOTFILES_DIR/zsh/p10k.zsh"
fi

# Built-in plugins (only load if not already active)
if ! (( $+functions[j] )) && [[ -f "$_omz_dir/plugins/autojump/autojump.plugin.zsh" ]]; then
  source "$_omz_dir/plugins/autojump/autojump.plugin.zsh"
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
