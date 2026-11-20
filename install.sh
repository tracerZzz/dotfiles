#!/usr/bin/env bash
# ============================================================================
# Interactive, non-invasive, hardened installer for dotfiles (macOS & Linux)
# Safe to run locally or via curl:
#   curl -fsSL https://raw.githubusercontent.com/tracerZzz/dotfiles/main/install.sh | bash
#
# Non-interactive CI options (optional):
#   DOTFILES_NONINTERACTIVE=1
#   DOTFILES_OPT_PULL=n           DOTFILES_OPT_OMZ=y
#   DOTFILES_OPT_ZSH_PLUGINS=y    DOTFILES_OPT_ZSH_HOOK=y
#   DOTFILES_OPT_VIM_HOOK=y       DOTFILES_OPT_VIM_PLUGINS=y
#   DOTFILES_OPT_AUTOJUMP=n       DOTFILES_OPT_GOENV=n
#   DOTFILES_OPT_GO_VERSION=""    DOTFILES_OPT_GOPROXY=n
#   DOTFILES_OPT_TMUX=n
# ============================================================================
set -euo pipefail

export GIT_TERMINAL_PROMPT=0

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/tracerZzz/dotfiles.git}"
NONINTERACTIVE="${DOTFILES_NONINTERACTIVE:-0}"
OS_NAME="$(uname -s)"

_TMP_DIRS=()
_WARNINGS=()

cleanup() {
  local d
  for d in "${_TMP_DIRS[@]:-}"; do
    if [[ -n "$d" && -d "$d" ]]; then
      rm -rf "$d" || true
    fi
  done
  return 0
}
trap cleanup EXIT INT TERM

# Colors (disabled if stdout is not a terminal)
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

record_warn() {
  warn "$1"
  _WARNINGS+=("$1")
}

make_tmp_dir() {
  local d
  d="$(mktemp -d)"
  _TMP_DIRS+=("$d")
  printf "%s" "$d"
}

curl_safe() {
  curl --connect-timeout 15 --max-time 60 "$@"
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local env_override="${3:-}"

  if [[ "$NONINTERACTIVE" == "1" ]]; then
    local val="${env_override:-$default}"
    [[ "$val" =~ ^[Yy]$ ]]
    return
  fi

  local hint="[Y/n]"
  [[ "$default" == "n" ]] && hint="[y/N]"

  local reply=""
  if [[ -r /dev/tty ]]; then
    printf "%b%s %s:%b " "$C_BOLD" "$prompt" "$hint" "$C_RESET" >/dev/tty
    IFS= read -r reply </dev/tty || reply=""
  fi

  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

ask_input() {
  local prompt="$1"
  local default="${2:-}"
  local env_override="${3:-}"

  if [[ "$NONINTERACTIVE" == "1" ]]; then
    printf "%s" "${env_override:-$default}"
    return
  fi

  local reply=""
  if [[ -r /dev/tty ]]; then
    if [[ -n "$default" ]]; then
      printf "%b%s [默认: %s]:%b " "$C_BOLD" "$prompt" "$default" "$C_RESET" >/dev/tty
    else
      printf "%b%s:%b " "$C_BOLD" "$prompt" "$C_RESET" >/dev/tty
    fi
    IFS= read -r reply </dev/tty || reply=""
  fi
  printf "%s" "${reply:-$default}"
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

# Atomic git clone: clones into a temp dir first so interrupted downloads never leave broken dirs
clone_atomic() {
  local repo_url="$1"
  local dest="$2"
  local label="$3"
  local check_file="${4:-}"

  if [[ -d "$dest" ]]; then
    if [[ -z "$check_file" || -e "$dest/$check_file" ]]; then
      ok "$label 已存在，跳过"
      return 0
    else
      warn "$label 目录存在但疑似残破（缺少 $check_file），跳过覆盖，请手动检查: $dest"
      return 0
    fi
  fi

  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  info "正在克隆 $label ..."
  if git clone --depth=1 "$repo_url" "$tmp_dir/repo"; then
    mkdir -p "$(dirname "$dest")"
    mv "$tmp_dir/repo" "$dest"
    ok "$label 安装完成"
    return 0
  else
    record_warn "$label 克隆失败（已自动清理临时目录），可稍后重试: $repo_url"
    return 1
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
      warn "Debian/Ubuntu 请先运行: sudo apt update && sudo apt install -y ${missing_req[*]}"
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
    if ! clone_atomic "$DOTFILES_REPO" "$DOTFILES_DIR" "dotfiles 仓库" "zsh/common.zsh"; then
      err "无法克隆 dotfiles 仓库，终止安装。"
      exit 1
    fi
  elif [[ -d "$DOTFILES_DIR/.git" ]]; then
    ok "检测到已有仓库: $DOTFILES_DIR"
    if ask_yes_no "是否尝试拉取最新更新 (git pull --ff-only)?" "n" "${DOTFILES_OPT_PULL:-}"; then
      git -C "$DOTFILES_DIR" pull --ff-only || record_warn "dotfiles 拉取更新失败（可能有本地未提交修改或网络问题）"
    fi
  else
    ok "检测到已有配置目录（非 Git 目录，如 rsync 同步）: $DOTFILES_DIR"
  fi

  # 3. Check Oh My Zsh
  local omz_dir="${ZSH:-$HOME/.oh-my-zsh}"
  local omz_custom="${ZSH_CUSTOM:-$omz_dir/custom}"
  if [[ ! -d "$omz_dir" ]]; then
    warn "未检测到 Oh My Zsh ($omz_dir)"
    if ask_yes_no "是否现在安装 Oh My Zsh?" "y" "${DOTFILES_OPT_OMZ:-}"; then
      local omz_script
      omz_script="$(make_tmp_dir)/install_omz.sh"
      if curl_safe -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" -o "$omz_script"; then
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$omz_script" || record_warn "Oh My Zsh 安装脚本返回异常"
        [[ -d "$omz_dir" ]] && ok "Oh My Zsh 安装完成"
      else
        record_warn "下载 Oh My Zsh 安装脚本失败（网络超时），已跳过"
      fi
    else
      warn "已跳过 Oh My Zsh（Zsh 主题和插件需要它才能生效）"
    fi
  else
    ok "Oh My Zsh 已安装"
  fi

  # 4. Optional: Powerlevel10k & Zsh plugins
  if [[ -d "$omz_dir" ]] && ask_yes_no "是否安装 Powerlevel10k 主题及 Zsh 插件 (autosuggestions, syntax-highlighting)?" "y" "${DOTFILES_OPT_ZSH_PLUGINS:-}"; then
    clone_atomic "https://github.com/romkatv/powerlevel10k.git" "$omz_custom/themes/powerlevel10k" "Powerlevel10k" "powerlevel10k.zsh-theme" || true
    clone_atomic "https://github.com/zsh-users/zsh-autosuggestions.git" "$omz_custom/plugins/zsh-autosuggestions" "zsh-autosuggestions" "zsh-autosuggestions.zsh" || true
    clone_atomic "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$omz_custom/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting" "zsh-syntax-highlighting.zsh" || true
  fi

  # 5. Non-invasive Zsh hook
  if ask_yes_no "是否在 ~/.zshrc 末尾追加一行引用 common.zsh（不覆盖原配置）?" "y" "${DOTFILES_OPT_ZSH_HOOK:-}"; then
    append_line_once \
      "$HOME/.zshrc" \
      "dotfiles/zsh/common.zsh" \
      '[[ -f "$HOME/dotfiles/zsh/common.zsh" ]] && source "$HOME/dotfiles/zsh/common.zsh"'
  fi

  # 6. Non-invasive Vim hook & optional plugins
  if ask_yes_no "是否在 ~/.vimrc 末尾追加一行引用 common.vim（不覆盖原配置）?" "y" "${DOTFILES_OPT_VIM_HOOK:-}"; then
    append_line_once \
      "$HOME/.vimrc" \
      "dotfiles/vim/common.vim" \
      "if filereadable(expand('~/dotfiles/vim/common.vim')) | source ~/dotfiles/vim/common.vim | endif"

    if command -v vim >/dev/null 2>&1; then
      local vim_plug_default="y"
      if [[ -f "$HOME/.vim/autoload/plug.vim" && -d "$HOME/.vim/plugged/onehalf" ]]; then
        ok "检测到 Vim 插件已安装，默认跳过联网更新"
        vim_plug_default="n"
      fi

      if ask_yes_no "是否安装/更新 vim-plug 及 5 个轻量 Vim 插件？（外网 VPS 可选 N 使用零插件模式）" "$vim_plug_default" "${DOTFILES_OPT_VIM_PLUGINS:-}"; then
        if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
          info "正在下载 vim-plug ..."
          if ! curl_safe -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"; then
            record_warn "vim-plug 下载失败，已跳过 Vim 插件安装"
          fi
        fi
        if [[ -f "$HOME/.vim/autoload/plug.vim" ]]; then
          info "正在安装 Vim 插件 (:PlugInstall，如网络卡顿可按 Ctrl+C 跳过，稍后在 Vim 内运行 :PlugInstall)..."
          vim -E -s -u "$HOME/.vimrc" +PlugInstall +qall || true
          ok "Vim 插件安装步骤已执行"
        fi
      fi
    else
      warn "未检测到 vim 命令，已写入 ~/.vimrc 引用，安装 vim 后即可直接生效"
    fi
  fi

  # 7. Optional: autojump (user-space install without sudo)
  if ! command -v autojump >/dev/null 2>&1 && [[ ! -d "$HOME/.autojump" ]]; then
    if ask_yes_no "是否安装 autojump 目录跳转工具?" "n" "${DOTFILES_OPT_AUTOJUMP:-}"; then
      local tmp_aj
      tmp_aj="$(make_tmp_dir)"
      if git clone --depth=1 "https://github.com/wting/autojump.git" "$tmp_aj/autojump"; then
        if (cd "$tmp_aj/autojump" && python3 install.py >/dev/null); then
          ok "autojump 已免 sudo 安装到 ~/.autojump"
        else
          record_warn "autojump 安装脚本执行失败"
        fi
      else
        record_warn "autojump 仓库克隆失败，已跳过"
      fi
    fi
  else
    ok "autojump 已安装"
  fi

  # 8. Optional: goenv + Go version (Option A: shared GOPATH=$HOME/go)
  local goenv_ready=0
  if command -v goenv >/dev/null 2>&1 || [[ -x "$HOME/.goenv/bin/goenv" ]]; then
    ok "goenv 已安装"
    goenv_ready=1
  else
    if ask_yes_no "是否安装 Go 版本管理工具 goenv（统一安装到 ~/.goenv）?" "n" "${DOTFILES_OPT_GOENV:-}"; then
      if clone_atomic "https://github.com/go-nv/goenv.git" "$HOME/.goenv" "goenv" "bin/goenv"; then
        goenv_ready=1
      fi
    fi
  fi

  if (( goenv_ready == 1 )) && [[ "${DOTFILES_OPT_GO_VERSION+set}" == "set" || "$NONINTERACTIVE" != "1" ]]; then
    local goenv_bin
    goenv_bin="$(command -v goenv 2>/dev/null || echo "$HOME/.goenv/bin/goenv")"
    if [[ -x "$goenv_bin" ]] && ask_yes_no "是否现在通过 goenv 安装一个 Go 版本?" "n" "${DOTFILES_OPT_GO_INSTALL:-}"; then
      local latest_go
      latest_go="$("$goenv_bin" install -l 2>/dev/null | grep -E '^[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+$' | tail -n 1 | tr -d '[:space:]' || true)"
      local target_go
      target_go="$(ask_input "请输入要安装的 Go 版本号" "${latest_go:-1.24.0}" "${DOTFILES_OPT_GO_VERSION:-}")"
      if [[ -n "$target_go" ]]; then
        info "正在安装 Go $target_go（下载二进制包可能需要数十秒，卡住可按 Ctrl+C 稍后手动执行 goenv install $target_go）..."
        if GOENV_ROOT="$HOME/.goenv" "$goenv_bin" install -s "$target_go" && GOENV_ROOT="$HOME/.goenv" "$goenv_bin" global "$target_go"; then
          ok "Go $target_go 安装并设为全局默认成功"
          if ask_yes_no "是否为本机设置国内 Go 代理 (go env -w GOPROXY=https://goproxy.cn,direct)? 海外 VPS / 公司内网请选 N" "n" "${DOTFILES_OPT_GOPROXY:-}"; then
            "$HOME/.goenv/shims/go" env -w GOPROXY=https://goproxy.cn,direct && ok "已设置本机 GOPROXY（保存在 ~/.config/go/env，不影响仓库）"
          fi
        else
          record_warn "Go $target_go 安装失败，可稍后手动运行: goenv install $target_go"
        fi
      fi
    fi
  fi

  # 9. Optional (Linux only): tmux for SSH session persistence
  if [[ "$OS_NAME" == "Linux" ]]; then
    if command -v tmux >/dev/null 2>&1; then
      ok "tmux 已安装"
    elif ask_yes_no "是否安装 tmux（Linux/SSH 防断连保活，需包管理权限）?" "n" "${DOTFILES_OPT_TMUX:-}"; then
      local pkg_prefix=""
      if [[ "$(id -u)" -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
        pkg_prefix="sudo"
      fi
      if command -v apt-get >/dev/null 2>&1; then
        if $pkg_prefix apt-get update && $pkg_prefix apt-get install -y tmux; then
          ok "tmux 安装完成"
        else
          record_warn "tmux 安装失败，可稍后手动执行: sudo apt install -y tmux"
        fi
      elif command -v dnf >/dev/null 2>&1; then
        $pkg_prefix dnf install -y tmux && ok "tmux 安装完成" || record_warn "tmux 安装失败，请手动安装"
      elif command -v yum >/dev/null 2>&1; then
        $pkg_prefix yum install -y tmux && ok "tmux 安装完成" || record_warn "tmux 安装失败，请手动安装"
      else
        record_warn "未识别的 Linux 包管理器，请手动安装 tmux"
      fi
    fi
  fi

  # 10. Final summary
  printf "\n%b=== 安装流程结束 ===%b\n" "$C_GREEN$C_BOLD" "$C_RESET"
  if (( ${#_WARNINGS[@]} > 0 )); then
    warn "本次有以下 ${#_WARNINGS[@]} 项警告/未完成项（不影响其余配置）："
    local w
    for w in "${_WARNINGS[@]}"; do
      printf "  - %s\n" "$w"
    done
  else
    ok "全部已选步骤均无报错完成！"
  fi

  echo ""
  if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
    echo "1. 当前默认 Shell 不是 zsh（切勿在 bash 中执行 source ~/.zshrc），请按以下两步切换："
    echo "   - 立即进入 zsh 体验: exec zsh"
    echo "   - 永久设为默认登录 Shell: sudo chsh -s \"\$(which zsh)\" \"\$USER\""
  else
    echo "1. 执行以下任一命令使 Zsh 配置生效: source ~/.zshrc 或 exec zsh"
  fi
  echo "2. 速查表: 终端敲 hh | Vim 内敲 :hh (或 \\?)"
  if [[ "$OS_NAME" == "Darwin" ]]; then
    echo "3. [macOS] 批量安装常用软件 (iTerm2/字体/代理客户端): brew bundle --file=~/dotfiles/macos/Brewfile"
    echo "4. [macOS] iTerm2 偏好导入: Settings -> General -> Settings -> 指向 ~/dotfiles/macos/iterm2 (保存方式务必选 Manually，防多机冲突)"
  fi
  echo "提示: 如需在本机使用 Git 提交代码，请手动配置当前机器的身份信息 (git config --global user.name/email)。"
}

main "$@"
