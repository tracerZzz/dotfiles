#!/usr/bin/env bash
# ============================================================================
# Interactive, non-invasive installer for dotfiles (macOS & Linux)
# Safe to run locally or via curl:
#   curl -fsSL https://raw.githubusercontent.com/tracerZzz/dotfiles/main/install.sh | bash
# ============================================================================
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/tracerZzz/dotfiles.git}"
OS_NAME="$(uname -s)"

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  C_RESET="\033[0m"
  C_BOLD="\033[1m"
  C_GREEN="\033[32m"
  C_YELLOW="\033[33m"
  C_BLUE="\033[34m"
  C_RED="\033[31m"
else
  C_RESET="" C_BOLD="" C_GREEN="" C_YELLOW="" C_BLUE="" C_RED=""
fi

info()  { printf "%b[INFO]%b %s\n" "$C_BLUE" "$C_RESET" "$1"; }
ok()    { printf "%b[ OK ]%b %s\n" "$C_GREEN" "$C_RESET" "$1"; }
warn()  { printf "%b[WARN]%b %s\n" "$C_YELLOW" "$C_RESET" "$1"; }
err()   { printf "%b[ERR ]%b %s\n" "$C_RED" "$C_RESET" "$1" >&2; }

ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local hint="[Y/n]"
  [[ "$default" == "n" ]] && hint="[y/N]"

  # When piped via `curl | bash`, read from /dev/tty if available
  local reply=""
  if [[ -r /dev/tty ]]; then
    printf "%b%s %s:%b " "$C_BOLD" "$prompt" "$hint" "$C_RESET" >/dev/tty
    IFS= read -r reply </dev/tty || reply=""
  else
    reply=""
  fi

  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

append_line_once() {
  local file="$1"
  local marker="$2"
  local line="$3"

  touch "$file"
  if grep -Fq "$marker" "$file"; then
    ok "已存在引用，跳过写入: $file"
  else
    printf "\n%s\n" "$line" >> "$file"
    ok "已追加一行引用到: $file"
  fi
}

clone_if_missing() {
  local repo_url="$1"
  local dest="$2"
  local label="$3"

  if [[ -d "$dest" ]]; then
    ok "$label 已存在，跳过"
  else
    info "正在克隆 $label ..."
    git clone --depth=1 "$repo_url" "$dest"
    ok "$label 安装完成"
  fi
}

main() {
  printf "\n%b=== dotfiles 非侵入式安装向导 (%s) ===%b\n\n" "$C_BOLD" "$OS_NAME" "$C_RESET"

  if [[ "$OS_NAME" != "Darwin" && "$OS_NAME" != "Linux" ]]; then
    err "暂不支持当前系统: $OS_NAME（仅支持 macOS 与 Linux）"
    exit 1
  fi

  # 1. Check required prerequisites
  info "1. 检查必备前置依赖..."
  local missing_req=()
  for cmd in git zsh curl python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_req+=("$cmd")
    fi
  done

  if (( ${#missing_req[@]} > 0 )); then
    err "缺少必备前置命令: ${missing_req[*]}"
    if [[ "$OS_NAME" == "Darwin" ]]; then
      warn "macOS 请先运行: xcode-select --install"
    else
      warn "Ubuntu/Debian 请先运行: sudo apt update && sudo apt install -y ${missing_req[*]}"
      warn "CentOS/RHEL   请先运行: sudo yum install -y ${missing_req[*]}"
    fi
    exit 1
  fi
  ok "基础命令齐全 (git, zsh, curl, python3)"

  if [[ "$OS_NAME" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1 || [[ -x /opt/homebrew/bin/brew ]] || [[ -x /usr/local/bin/brew ]]; then
      ok "Homebrew 已安装"
    else
      warn "未检测到 Homebrew（macOS 推荐安装）："
      warn '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    fi
  fi

  # 2. Ensure dotfiles repo exists locally (public HTTPS, no GitHub login needed)
  info "2. 准备 dotfiles 目录 ($DOTFILES_DIR)..."
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    git clone --depth=1 "$DOTFILES_REPO" "$DOTFILES_DIR"
    ok "已克隆仓库到 $DOTFILES_DIR"
  elif [[ -d "$DOTFILES_DIR/.git" ]]; then
    ok "检测到已有仓库: $DOTFILES_DIR"
    if ask_yes_no "是否尝试拉取最新更新 (git pull --ff-only)?" "n"; then
      git -C "$DOTFILES_DIR" pull --ff-only || warn "拉取跳过（可能有本地未提交修改或网络不可用）"
    fi
  else
    ok "检测到已有配置目录（非 Git 目录，如 rsync 同步）: $DOTFILES_DIR"
  fi

  # 3. Check Oh My Zsh
  local omz_dir="${ZSH:-$HOME/.oh-my-zsh}"
  local omz_custom="${ZSH_CUSTOM:-$omz_dir/custom}"
  if [[ ! -d "$omz_dir" ]]; then
    warn "未检测到 Oh My Zsh ($omz_dir)"
    if ask_yes_no "是否现在安装 Oh My Zsh?" "y"; then
      RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
      ok "Oh My Zsh 安装完成"
    else
      warn "已跳过 Oh My Zsh（Zsh 主题和插件需要它才能生效）"
    fi
  else
    ok "Oh My Zsh 已安装"
  fi

  # 4. Optional: Powerlevel10k & Zsh plugins
  if [[ -d "$omz_dir" ]] && ask_yes_no "是否安装 Powerlevel10k 主题及 Zsh 插件 (autosuggestions, syntax-highlighting)?" "y"; then
    clone_if_missing "https://github.com/romkatv/powerlevel10k.git" "$omz_custom/themes/powerlevel10k" "Powerlevel10k"
    clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions.git" "$omz_custom/plugins/zsh-autosuggestions" "zsh-autosuggestions"
    clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$omz_custom/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
  fi

  # 5. Non-invasive Zsh hook
  if ask_yes_no "是否在 ~/.zshrc 末尾追加一行引用 common.zsh（不覆盖原配置）?" "y"; then
    append_line_once \
      "$HOME/.zshrc" \
      "dotfiles/zsh/common.zsh" \
      '[[ -f "$HOME/dotfiles/zsh/common.zsh" ]] && source "$HOME/dotfiles/zsh/common.zsh"'
  fi

  # 6. Non-invasive Vim hook & optional plugins
  if ask_yes_no "是否在 ~/.vimrc 末尾追加一行引用 common.vim（不覆盖原配置）?" "y"; then
    append_line_once \
      "$HOME/.vimrc" \
      "dotfiles/vim/common.vim" \
      "if filereadable(expand('~/dotfiles/vim/common.vim')) | source ~/dotfiles/vim/common.vim | endif"

    if ask_yes_no "是否安装 vim-plug 及 5 个轻量 Vim 插件？（外网 VPS 可选 N 使用零插件模式）" "y"; then
      if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
        info "正在下载 vim-plug ..."
        curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
          https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
      fi
      info "正在安装 Vim 插件 (:PlugInstall)..."
      vim -E -s -u "$HOME/.vimrc" +PlugInstall +qall || true
      ok "Vim 插件安装步骤已执行（如遇网络中断可随时在 Vim 内运行 :PlugInstall）"
    fi
  fi

  # 7. Optional: autojump
  if ! command -v autojump >/dev/null 2>&1 && [[ ! -d "$HOME/.autojump" ]]; then
    if ask_yes_no "是否安装 autojump 目录跳转工具?" "n"; then
      if [[ "$OS_NAME" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
        brew install autojump || warn "Homebrew 安装失败，可手动克隆 wting/autojump 运行 python3 install.py"
      else
        local tmp_aj
        tmp_aj="$(mktemp -d)"
        git clone --depth=1 https://github.com/wting/autojump.git "$tmp_aj"
        (cd "$tmp_aj" && python3 install.py)
        rm -rf "$tmp_aj"
        ok "autojump 已免 sudo 安装到 ~/.autojump"
      fi
    fi
  else
    ok "autojump 已安装"
  fi

  # 8. Optional: goenv
  if ! command -v goenv >/dev/null 2>&1 && [[ ! -d "$HOME/.goenv" ]]; then
    if ask_yes_no "是否安装 Go 版本管理工具 goenv?" "n"; then
      if [[ "$OS_NAME" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
        brew install goenv
      else
        git clone --depth=1 https://github.com/go-nv/goenv.git "$HOME/.goenv"
      fi
      ok "goenv 安装完成（重启终端后用 goenv install <版本> 安装 Go）"
    fi
  else
    ok "goenv 已安装"
  fi

  # 9. Final reminders
  printf "\n%b=== 安装完成 ===%b\n" "$C_GREEN$C_BOLD" "$C_RESET"
  echo "1. 执行以下任一命令使 Zsh 配置生效: source ~/.zshrc 或 exec zsh"
  echo "2. 速查表: 终端敲 hh | Vim 内敲 :hh (或 \\?)"
  if [[ "$OS_NAME" == "Darwin" ]]; then
    echo "3. [macOS] iTerm2 偏好导入: Settings -> General -> Settings -> 指向 ~/dotfiles/macos/iterm2 (保存方式选 Manually)"
    echo "4. [macOS] 如未安装字体: brew install --cask font-meslo-lg-nerd-font"
  fi
  echo "提示: 如需在本机使用 Git 提交代码，请手动配置当前机器的身份信息 (git config --global user.name/email)。"
}

main "$@"
