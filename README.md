# dotfiles — macOS & Linux 通用终端、Vim 环境配置

本仓库采用**「非侵入式一行引用 + 跨平台自动识别」**设计：
- **不覆盖宿主机原有的 `~/.zshrc` 和 `~/.vimrc`**，在个人 Mac、公司电脑或 Linux VPS 上都只需追加一行 `source`。
- **自动区分 macOS 与 Linux**：Linux 不安装 Homebrew、不安装 iTerm2；无插件环境也能零报错直接使用基础 Vim。
- **不强制在每台机器登录 GitHub**：外网 Linux VPS 可直接从本地 Mac `rsync` 同步，避免私钥或 Token 泄漏。

> 维护与脱敏规范、AI 自动操作约束请见 [AGENTS.md](./AGENTS.md)。

---

## 快速一键安装（macOS & Linux / 外网 VPS 通用，无需登录 GitHub）

> 仓库已设为公开（Public）并严格脱敏，**任何新电脑或外网 VPS 都无需配置 SSH Key / 登录 GitHub**，直接运行交互式安装脚本即可（不会覆盖原有 `~/.zshrc` / `~/.vimrc`，所有可选项都会逐项询问 `y/n`）：

```bash
curl -fsSL https://raw.githubusercontent.com/tracerZzz/dotfiles/main/install.sh | bash
```

也可以先查看脚本内容再执行：
```bash
git clone https://github.com/tracerZzz/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
```

---

## 目录结构

```text
dotfiles/
├── install.sh                 # 交互式非侵入安装脚本（支持 curl | bash 与本地运行）
├── README.md                  # 本说明、依赖分层与手动接入指南
├── AGENTS.md                  # 写给 AI 的约束、前置检查与脱敏规范
├── zsh/
│   ├── common.zsh             # 跨平台通用 Zsh 配置（自动区分 macOS/Linux，含 goenv 自动集成）
│   └── p10k.zsh               # Powerlevel10k 提示符样式
├── vim/
│   └── common.vim             # 跨平台轻量 Vim 配置（5 插件 + 透明配色 + :hh 速查）
├── macos/
│   ├── Brewfile               # 仅 macOS：常用软件清单（含按系统版本自动选 clash-verge-rev / sfm）
│   └── iterm2/                # 仅 macOS：iTerm2 脱敏偏好与 One Half Dark 配色
├── cheatsheets/
│   ├── shell.md               # Shell & iTerm2 速查表（终端敲 hh）
│   └── vim.md                 # Vim 速查表（Vim 中敲 :hh 或 \?）
└── scripts/
    └── vh.py                  # 零依赖终端/Vim 速查美化渲染脚本
```

---

## 依赖分层（必备前置 vs 可选按需）

| 类别 | 依赖项 | macOS | Linux / VPS | 是否必备 |
| :--- | :--- | :--- | :--- | :--- |
| **必备前置** | `zsh`、`curl`、`python3`、`oh-my-zsh` | 前三项系统自带，需装 Oh My Zsh | `apt/yum` 安装 + Oh My Zsh | **必备**（`python3` 用于 `hh` / `:hh` 渲染） |
| **必备前置（仅 macOS）** | `Homebrew` | 需安装 | **不需要** | macOS 必备 / Linux 跳过 |
| **按需前置** | `git` 命令行（无需登录账号） | Xcode CLT 自带 | `apt/yum install git` | 仅克隆公开插件时需要，**无需登录 GitHub** |
| **可选（非必备）** | **GitHub 登录鉴权**（SSH Key / `gh`） | 仅常用开发机按需配置 | **外网 VPS 强烈建议不登录！** | 可选（不登录时用下方 `rsync` 同步） |
| **可选（非必备）** | `autojump`、`ripgrep`、`vim-plug`、`tmux` | 按需安装 | 按需安装（`tmux` 强烈推荐用于远程 SSH 保活） | 可选（未装时自动优雅降级，不报错） |
| **可选（仅 macOS）** | `iTerm2`、`MesloLGS NF` 字体 | `brew install --cask` | **不需要** | 仅 macOS 可选 |
| **可选（语言模块）** | `goenv` + Go | 按需安装 | 按需安装 | 仅需 Go 开发的机器安装 |

---

## 获取本仓库到目标机器（两种方式任选）

### 方式 1：常用个人/开发机（配置 GitHub 鉴权后 clone）
```zsh
# 如需在本机提交代码，先按当前机器身份配置 Git（不要写入 dotfiles）
git config --global user.name "<你的名字>"
git config --global user.email "<对应机器的邮箱>"

# 配置 SSH Key（或 gh auth login）后克隆
git clone git@github.com:tracerZzz/dotfiles.git ~/dotfiles
```

### 方式 2：外网 Linux VPS / 不想登录 GitHub 的机器（推荐，零凭证泄漏）
在**本地 Mac** 上直接同步配置目录到目标服务器（自动排除 `.git` 目录，不留任何账号信息）：
```zsh
rsync -avz --exclude='.git' ~/dotfiles/ <user>@<vps-ip>:~/dotfiles/
```

---

## 接入路径 A：macOS 完整接入

### 1. 安装必备前置与可选软件
```zsh
# 必备：Homebrew（如未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 可选：iTerm2 与 Nerd Font 字体
brew install --cask iterm2 font-meslo-lg-nerd-font

# 可选：autojump（若无系统目录写权限，可用 wting/autojump 的 python3 install.py 装到 ~/.autojump）
brew install autojump
```
*(如未安装 Oh My Zsh，按官方命令安装即可。)*

### 2. 安装 Powerlevel10k 与 Zsh 第三方插件（公开仓库，无需登录 GitHub）
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

# Vim（可选：安装 vim-plug + 追加一行引用 + 安装 5 个轻量插件）
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
echo "if filereadable(expand('~/dotfiles/vim/common.vim')) | source ~/dotfiles/vim/common.vim | endif" >> ~/.vimrc
vim +PlugInstall +qall
```

### 4. 导入 iTerm2 偏好（配色 + 字体 + 毛玻璃透明）
- 打开 iTerm2 → `Settings (⌘,)` → `General` → `Settings`（或 `Preferences`）
- 勾选 **`Load settings from a custom folder or URL`**，指向 **`~/dotfiles/macos/iterm2`**，保存方式选 **`Manually`**，重启 iTerm2 即生效。

### 5. 可选：按清单批量安装常用 macOS 软件（`Brewfile`）
`macos/Brewfile` 独立于 `install.sh`，按需手动执行，会自动根据系统版本选择对应软件（macOS 12 装 `clash-verge-rev`，macOS 13+ 装 `sfm`）：
```zsh
brew bundle --file=~/dotfiles/macos/Brewfile
```

---

## 接入路径 B：Linux / 外网 VPS 精简接入

*(无需 Homebrew、无需 iTerm2、无需装字体、无需登录 GitHub)*

### 1. 安装必备基础环境（以 Ubuntu/Debian 为例，CentOS/RHEL 替换为 `yum`/`dnf`）
```bash
sudo apt update && sudo apt install -y git zsh curl python3
# 可选：sudo apt install -y autojump ripgrep
chsh -s "$(which zsh)"
# 安装 Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 2. 安装 Zsh 主题与插件 + 一行引用
```zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

echo '[[ -f "$HOME/dotfiles/zsh/common.zsh" ]] && source "$HOME/dotfiles/zsh/common.zsh"' >> ~/.zshrc
source ~/.zshrc
```

### 3. 接入 Vim（二选一）
- **插件版（常用开发机）**：同 macOS 第 3 步安装 `vim-plug` + 追加一行引用 + `vim +PlugInstall +qall`。
- **零插件极简版（外网 VPS / 临时服务器）**：只需追加一行引用（不装 `vim-plug`），即可零报错使用全部原生基础编辑体验。

---

## 可选模块：Go 环境（使用 `goenv` 管理版本）

`zsh/common.zsh` 已内置 `goenv` 自动初始化（检测到 `~/.goenv` 或 `goenv` 命令时自动生效，未安装时零开销），采用 **跨版本共享 `GOPATH=$HOME/go`**（`GOENV_DISABLE_GOPATH=1`），避免切换 Go 版本时重复下载依赖与工具。

### 1. 安装 `goenv`（macOS & Linux 统一路径）
```zsh
git clone --depth=1 https://github.com/go-nv/goenv.git ~/.goenv
```

### 2. 刷新 Shell 并安装指定 Go 版本
```zsh
source ~/.zshrc
goenv install -l             # 查看可安装的 Go 版本列表
goenv install <版本号>        # 例如：goenv install 1.24.0
goenv global <版本号>         # 设为全局默认版本
go version                   # 验证
```
- **国内网络可选设置代理**（保存在本机 `~/.config/go/env`，不污染仓库）：
  ```zsh
  go env -w GOPROXY=https://goproxy.cn,direct
  ```
- **注意**：公司专属的 `GOPRIVATE` / 私有 `GOPROXY` 请仅配置在宿主机本地，**严禁提交到本 Public 仓库**。

---

## 日常使用与后续升级配置

### 1. 日常速查
- **Shell 速查**：终端敲 **`hh`**
- **Vim 速查**：Vim 内敲 **`:hh`**（或 `\?`），按 `q` 关闭

### 2. 在任意机器拉取最新配置（零冲突）
```zsh
git -C ~/dotfiles pull
source ~/.zshrc
```
*(如果 iTerm2 按建议设为 `Manually` 保存，`git pull` 永远不会产生 plist 冲突；拉取完重启 iTerm2 即生效。)*

### 3. 升级已安装的第三方组件（按需执行）
- **Oh My Zsh**：`omz update`
- **Powerlevel10k 与 Zsh 插件**：
  ```zsh
  git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" pull
  git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" pull
  git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" pull
  ```
- **Vim 插件**：在 Vim 中运行 `:PlugUpdate`
- **`goenv`**：`git -C ~/.goenv pull`

### 4. 修改个人偏好并同步回仓库（仅限个人主力机）
- **改 Zsh / Vim / 速查表**：直接改 `~/dotfiles` 下的对应文件 → 跑 `git -C ~/dotfiles diff` 确认无硬编码用户名或敏感信息 → `git add -A && git commit && git push`（推送后 GitHub Actions 会自动在 Debian / Ubuntu / macOS 上回归测试）。
- **改 iTerm2 配色/透明度**：在主力 Mac 的 iTerm2 设置中手动点一次 `Save Now`，再按 [AGENTS.md](./AGENTS.md) 中的脱敏清单清理 `NoSync*` 等脏字段后提交推送。
