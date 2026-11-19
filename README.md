# dotfiles — macOS & Linux 通用终端、Vim 环境配置

本仓库采用**「非侵入式一行引用 + 跨平台自动识别」**设计：
- **不覆盖宿主机原有的 `~/.zshrc` 和 `~/.vimrc`**，在个人 Mac、公司电脑或 Linux 服务器上都只需追加一行 `source`。
- **自动区分 macOS 与 Linux**：Linux 不安装 Homebrew、不安装 iTerm2；无插件环境（如临时服务器）也能零报错直接使用基础 Vim。

> 维护与脱敏规范、AI 自动操作约束请见 [AGENTS.md](./AGENTS.md)。

---

## 目录结构

```text
dotfiles/
├── README.md                  # 本说明、前置依赖与 macOS / Linux 接入指南
├── AGENTS.md                  # 写给 AI 的约束、脱敏与维护规范
├── zsh/
│   ├── common.zsh             # 跨平台通用 Zsh 配置（自动区分 macOS / Linux）
│   └── p10k.zsh               # Powerlevel10k 提示符样式
├── vim/
│   └── common.vim             # 跨平台轻量 Vim 配置（5 插件 + 透明配色 + :hh 速查）
├── macos/
│   └── iterm2/                # 仅 macOS：iTerm2 脱敏偏好与 One Half Dark 配色
├── cheatsheets/
│   ├── shell.md               # Shell & iTerm2 速查表（终端敲 hh）
│   └── vim.md                 # Vim 速查表（Vim 中敲 :hh 或 \?）
└── scripts/
    └── vh.py                  # 零依赖终端/Vim 速查美化渲染脚本
```

---

## 前置依赖清单（按顺序准备）

| 阶段 | 依赖项 | macOS | Linux（Ubuntu / CentOS） | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **0. 拉取仓库前** | `git` + GitHub 鉴权 | Xcode CLT 自带 `git` | `apt/yum install git` | 私有仓库需先配 SSH Key、HTTPS Token 或 `gh auth login`（账号与私钥不进仓库） |
| **1. 包管理器** | 系统包管理 | **安装 Homebrew** | 系统自带 `apt` / `dnf` / `yum` | **Linux 无需安装 Homebrew** |
| **2. 核心运行时** | `zsh`、`oh-my-zsh`、`curl`、`python3` | 自带 `zsh/curl/python3`，装 Oh My Zsh | 安装 `zsh`、`curl`、`python3` + Oh My Zsh | `python3` 用于 `hh` / `:hh` 速查表渲染 |
| **3. 可选增强** | `autojump`、`ripgrep`、`vim-plug` | `brew install`（或免 `sudo` 手动装） | `apt/yum install`（或免 `sudo` 手动装） | 未安装时自动优雅降级，不报错 |
| **4. 仅 macOS** | `iTerm2`、`MesloLGS NF` 字体 | `brew install --cask` | **不需要** | SSH 连 Linux 时由本地 Mac 的 iTerm2 负责显示 |

### 步骤 0：新机器 Git 基础初始化（按当前机器身份填写）
```zsh
git config --global user.name "<你的名字>"
git config --global user.email "<对应机器的邮箱>"
```
完成 GitHub SSH Key 配置（或 `gh auth login`）后克隆本仓库：
```zsh
git clone git@github.com:tracerZzz/dotfiles.git ~/dotfiles
# 无 SSH Key 时可用 HTTPS：
# git clone https://github.com/tracerZzz/dotfiles.git ~/dotfiles
```

---

## 接入路径 A：macOS 完整接入

### 1. 安装基础软件（Homebrew、iTerm2、字体、Oh My Zsh、autojump）
```zsh
# 安装 Homebrew（如未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 iTerm2 与 Nerd Font 字体
brew install --cask iterm2 font-meslo-lg-nerd-font

# 安装 autojump（若无 /usr/local 写权限，可改用 wting/autojump 的 python3 install.py 装到 ~/.autojump）
brew install autojump
```
*(如未安装 Oh My Zsh，按官方命令安装即可。)*

### 2. 安装 Powerlevel10k 与 Zsh 第三方插件
```zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
```

### 3. 一行引用 Zsh 与 Vim 通用配置
```zsh
# Zsh（仅追加到 ~/.zshrc 末尾，不破坏原有配置）
echo '[[ -f "$HOME/dotfiles/zsh/common.zsh" ]] && source "$HOME/dotfiles/zsh/common.zsh"' >> ~/.zshrc
source ~/.zshrc

# Vim（安装 vim-plug + 追加一行引用 + 安装 5 个轻量插件）
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
echo "if filereadable(expand('~/dotfiles/vim/common.vim')) | source ~/dotfiles/vim/common.vim | endif" >> ~/.vimrc
vim +PlugInstall +qall
```

### 4. 导入 iTerm2 偏好（配色 + 字体 + 毛玻璃透明）
- 打开 iTerm2 → `Settings (⌘,)` → `General` → `Settings`（或 `Preferences`）
- 勾选 **`Load settings from a custom folder or URL`**，指向 **`~/dotfiles/macos/iterm2`**，保存方式选 **`Manually`**，重启 iTerm2 即生效。

---

## 接入路径 B：Linux / 远程服务器精简接入

*(无需 Homebrew、无需 iTerm2、无需装字体)*

### 1. 安装基础依赖（以 Ubuntu/Debian 为例，CentOS/RHEL 替换为 `yum`/`dnf`）
```bash
sudo apt update && sudo apt install -y git zsh curl python3 autojump
chsh -s "$(which zsh)"
# 安装 Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 2. 安装 Powerlevel10k 与 Zsh 插件 + 一行引用
```zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

echo '[[ -f "$HOME/dotfiles/zsh/common.zsh" ]] && source "$HOME/dotfiles/zsh/common.zsh"' >> ~/.zshrc
source ~/.zshrc
```

### 3. 接入 Vim
- **完整版（开发机）**：同 macOS 第 3 步安装 `vim-plug` + 一行引用 + `vim +PlugInstall +qall`。
- **极简免插件版（临时/生产服务器）**：直接把 `vim/common.vim` 复制为 `~/.vimrc` 即可零报错使用全部原生基础体验。

---

## 可选模块：安装 Go 环境（仅需 Go 开发的机器）

`zsh/common.zsh` 已自动将 `/usr/local/go/bin`（Linux）和 `$HOME/go/bin` 加入 `PATH`（检测到目录存在即生效）。

- **macOS**：
  ```zsh
  brew install go
  ```
- **Linux（官方二进制包，推荐）**：
  前往 [go.dev/dl](https://go.dev/dl/) 获取最新版本号后解压至 `/usr/local/go`：
  ```bash
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go<版本号>.linux-amd64.tar.gz
  ```
- **多版本管理（可选）**：如需切换多个 Go 版本，可按个人习惯使用 `gvm` / `g`（`voidint/g`） / `goenv` / `asdf`。
- **注意**：公司或个人专属的 `GOPROXY`、`GOPRIVATE` 请写在宿主机自己的 `~/.zshrc` 中，不要提交到本仓库。

---

## 日常使用与同步

- **Shell 速查**：终端敲 **`hh`**
- **Vim 速查**：Vim 内敲 **`:hh`**（或 `\?`），按 `q` 关闭
- **拉取最新配置**：`git -C ~/dotfiles pull`
