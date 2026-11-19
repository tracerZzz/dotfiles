# dotfiles — macOS 终端、Vim & iTerm2 通用环境配置

本仓库采用**「非侵入式引用」**设计：**不修改、不覆盖宿主机原有的 `~/.zshrc` 和 `~/.vimrc`**，只需在任意电脑（个人 Mac 或公司电脑）的默认配置末尾追加一行 `source`，即可同步整套环境；后续在任意地方 `git pull` 即可一键更新。

> 维护与脱敏规范、AI 自动操作约束请见 [AGENTS.md](./AGENTS.md)。

---

## 目录结构

```text
dotfiles/
├── README.md                  # 本说明与新机器恢复步骤
├── AGENTS.md                  # 写给 AI 的约束、脱敏与维护规范
├── zsh/
│   ├── common.zsh             # 通用 Zsh 配置（主题、插件、hh 速查、Homebrew 兼容）
│   └── p10k.zsh               # Powerlevel10k 提示符样式
├── vim/
│   └── common.vim             # 通用轻量 Vim 配置（5 个插件 + 透明配色 + :hh 速查）
├── iterm2/
│   ├── com.googlecode.iterm2.plist   # 脱敏后的 iTerm2 完整偏好
│   └── One Half Dark.itermcolors     # 配色方案备份
├── cheatsheets/
│   ├── shell.md               # Shell & iTerm2 速查表（终端敲 hh）
│   └── vim.md                 # Vim 速查表（Vim 中敲 :hh 或 \?）
└── scripts/
    └── vh.py                  # 零依赖终端/Vim 速查美化渲染脚本
```

---

## 环境偏好摘要

- **终端**：iTerm2 + `One Half Dark` 配色 + 毛玻璃半透明背景 + `MesloLGS NF` 字体
- **Shell**：Oh My Zsh + `Powerlevel10k` + 极简 5 插件（`git`、`autojump`、`sudo`、`zsh-autosuggestions`、`zsh-syntax-highlighting`）
- **Vim**：轻量 5 插件（`preservim/nerdtree`、`sonph/onehalf`、`tpope/vim-commentary`、`vim-airline/vim-airline`、`junegunn/fzf` + `fzf.vim`）+ 透明背景；无插件环境（如 SSH 服务器）也能零报错直接使用
- **统一速查**：
  - Shell 终端里敲 **`hh`** → 查看 Zsh / 插件 / iTerm2 快捷键
  - Vim 编辑器里敲 **`:hh`**（或 `\?`）→ 侧边弹出 Vim 核心 & 插件快捷键（按 `q` 关闭）

---

## 新电脑一键接入（个人 / 公司电脑完全通用）

### 1. 克隆仓库
```zsh
# SSH（推荐）
git clone git@github.com:tracerZzz/dotfiles.git ~/dotfiles

# 或 HTTPS（无 SSH Key 时）
git clone https://github.com/tracerZzz/dotfiles.git ~/dotfiles
```

### 2. 安装基础依赖（如尚未安装）
- 安装 Homebrew、iTerm2（`brew install --cask iterm2`）、Oh My Zsh
- 安装字体：`brew install --cask font-meslo-lg-nerd-font`（或在 iTerm2 首次启动 Powerlevel10k 时按向导自动安装）
- 安装 `autojump`：
  - 优先：`brew install autojump`
  - 无系统目录写权限时：克隆 `https://github.com/wting/autojump.git` 运行 `python3 install.py` 安装到 `~/.autojump`

### 3. 安装 Powerlevel10k 与 Zsh 第三方插件
```zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
```

### 4. 一行引用通用 Zsh 配置（不改动原有 `~/.zshrc`）
执行下面命令，仅在原有 `~/.zshrc` 末尾追加一行引用：
```zsh
echo '[[ -f "$HOME/dotfiles/zsh/common.zsh" ]] && source "$HOME/dotfiles/zsh/common.zsh"' >> ~/.zshrc
source ~/.zshrc
```

### 5. 一行引用通用 Vim 配置 & 安装插件（不改动原有 `~/.vimrc`）
```zsh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
echo "if filereadable(expand('~/dotfiles/vim/common.vim')) | source ~/dotfiles/vim/common.vim | endif" >> ~/.vimrc
vim +PlugInstall +qall
```
> 如需在 Vim 中使用 `\f`（`:Rg`）全局搜文件内容，可额外安装 `brew install ripgrep`。

### 6. 导入 iTerm2 配色与外观偏好
- 打开 iTerm2 → `Settings (⌘,)` → `General` → `Settings`（或 `Preferences`）
- 勾选 **`Load settings from a custom folder or URL`**，选择 `~/dotfiles/iterm2`，保存方式选 **`Manually`**（避免自动写回本机脏数据），重启 iTerm2 即可生效。

---

## 日常更新配置

在任意电脑上拉取最新通用配置，重启终端或 `source ~/.zshrc` 即生效：
```zsh
git -C ~/dotfiles pull
```
