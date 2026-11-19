# macOS 终端 & iTerm2 环境配置（Dotfiles）

这份仓库保存了我的 macOS 终端（Zsh + Oh My Zsh + Powerlevel10k + iTerm2）通用配置，**已去除所有硬编码用户名与本机运行态数据**，可直接用于个人新 Mac 或公司电脑。

**换新电脑时，clone 本仓库到 `~/dotfiles`，然后让 AI 按本文档顺序执行即可一键复原。**

---

## 一、个人偏好摘要（写给 AI 看）

- **终端软件**：iTerm2
- **配色方案**：`One Half Dark`（已备份在 `iterm2/One Half Dark.itermcolors` 和 `iterm2/com.googlecode.iterm2.plist`）
- **窗口外观**：毛玻璃半透明背景（Transparency + Blur，已保存在 `com.googlecode.iterm2.plist`）
- **字体**：`MesloLGS NF`（Powerlevel10k 推荐 Nerd Font）
- **Shell 框架**：Oh My Zsh
- **Zsh 主题**：`powerlevel10k/powerlevel10k`（样式配置已保存在 `.p10k.zsh`）
- **Zsh 插件原则**：AI 时代极简高效率配置，只保留零延迟交互刚需插件，不装冗余 alias 插件：
  - `git`（Oh My Zsh 内置）
  - `autojump`（快速目录跳转）
  - `sudo`（Oh My Zsh 内置，连按两次 `Esc` 自动加 `sudo`）
  - `zsh-autosuggestions`（灰色历史命令补全，按 `→` 上屏）
  - `zsh-syntax-highlighting`（实时命令语法高亮，须放插件列表最后）

---

## 二、公司电脑 / 跨机器恢复时的安全须知（必看）

1. **绝不直接覆盖原有 `~/.zshrc`**：
   - 公司电脑的 `~/.zshrc` 通常包含内网代理、VPN/SSO 脚本、nvm/pyenv/Java/Go 路径或内部 CLI 配置。
   - **恢复前必须先备份**：`cp ~/.zshrc ~/.zshrc.bak`，并将公司专属配置迁移到 **`~/.zshrc.local`**（`.zshrc` 末尾已自动加载 `~/.zshrc.local`，且该文件永不纳入 Git）。
2. **公司电脑用 `cp` 而不是软链接 `ln -sf`**：
   - 防止公司脚本自动往 `~/.zshrc` 写入内部 Token / 内网地址后被意外提交到个人仓库（安全合规风险）。
   - **不要在公司电脑直接 `git push` 回本仓库**，如确需同步通用配置，请先检查 `git diff` 确认无任何公司信息。
3. **芯片架构自动兼容**：
   - `.zshrc` 已内置 Apple Silicon（`/opt/homebrew`）与 Intel（`/usr/local`）的 Homebrew 路径兼容。
4. **公司网络 / 权限受限时**：
   - 未配 SSH Key 时可用 HTTPS 克隆：`git clone https://github.com/tracerZzz/dotfiles.git ~/dotfiles`
   - 若无 `sudo` 权限或 `/usr/local` 不可写，`autojump` 可直接从 `https://github.com/wting/autojump.git` 运行 `python3 install.py` 安装到 `$HOME/.autojump`（Oh My Zsh 插件原生支持）。

---

## 三、新电脑一键恢复步骤

### 1. 安装基础工具
- 安装 Homebrew（如未安装）
- 安装 iTerm2：`brew install --cask iterm2`
- 安装 Oh My Zsh（如未安装）
- 安装 `autojump`：
  - 优先：`brew install autojump`
  - 无写权限或需源码编译时：克隆 `https://github.com/wting/autojump.git` 运行 `python3 install.py` 安装到 `~/.autojump`

### 2. 安装 Powerlevel10k 主题与第三方插件
```zsh
# Powerlevel10k 主题
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

# zsh-syntax-highlighting
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
```

### 3. 安装字体（MesloLGS NF）
```zsh
brew install --cask font-meslo-lg-nerd-font
```
（或在 iTerm2 首次启动 Powerlevel10k 时按向导提示自动安装 `MesloLGS NF`。）

### 4. 恢复 Zsh 配置文件
```zsh
# 1) 先备份原有配置（重要！）
[[ -f ~/.zshrc ]] && cp ~/.zshrc ~/.zshrc.bak

# 2) 复制配置（公司电脑推荐 cp；个人电脑也可用 ln -sf）
cp ~/dotfiles/.zshrc ~/.zshrc
cp ~/dotfiles/.p10k.zsh ~/.p10k.zsh

# 3) 如有公司/本机专属配置，从 ~/.zshrc.bak 提取到 ~/.zshrc.local
```

### 5. 恢复 iTerm2 完整偏好（配色 + 字体 + 透明磨砂）
方式 A（推荐，图形界面导入）：
1. 打开 iTerm2 → `Settings (⌘,)` → `General` → `Settings`（或 `Preferences`）
2. 勾选 **`Load settings from a custom folder or URL`**，选择 `~/dotfiles/iterm2`
3. 重启 iTerm2 即可生效（个人电脑可将保存方式设为 `Automatically`；公司电脑建议设为 `Manually` 避免自动写回本机信息）

方式 B（命令行导入）：
```zsh
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/dotfiles/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
```

---

## 四、平时更新备份（仅限个人电脑）
```zsh
cp ~/.p10k.zsh ~/dotfiles/.p10k.zsh
# 如需同步 .zshrc，请检查确认无硬编码用户名或密钥
cd ~/dotfiles && git diff && git add -A && git commit -m "Update dotfiles" && git push
```
