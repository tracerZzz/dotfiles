# AGENTS.md — 仓库维护与 AI 协作约束

本文档定义 AI（`agy`、`codex`、`claude code` 等）在修改、维护或在新机器上部署本 `dotfiles` 仓库时**必须严格遵守的规则**。

---

## 1. 非侵入式配置原则（核心架构约束）

- **禁止覆盖宿主机默认配置文件**：
  - 永远不要用本仓库的文件直接覆盖或软链接替换宿主机的 `~/.zshrc` 或 `~/.vimrc`。
  - 宿主机原本的环境变量、代理、VPN/SSO、Git 身份、Go 私有代理（`GOPRIVATE`/`GOPROXY`）、公司内部 CLI 等配置留在宿主机自己的 `~/.zshrc` / `~/.vimrc` 中。
  - 所有跨机器通用配置必须写在 `zsh/common.zsh` 和 `vim/common.vim` 中，宿主机仅通过末尾追加一行 `source` 引入：
    - Zsh：`[[ -f "$HOME/dotfiles/zsh/common.zsh" ]] && source "$HOME/dotfiles/zsh/common.zsh"`
    - Vim：`if filereadable(expand('~/dotfiles/vim/common.vim')) | source ~/dotfiles/vim/common.vim | endif`
- **加载幂等与容错**：
  - `zsh/common.zsh` 在宿主机 `oh-my-zsh.sh` 之后加载也必须正常工作，且不重复污染 `PATH`、不重复加载已激活的插件。
  - `vim/common.vim` 在未安装 `vim-plug` 或未安装插件的环境（如 SSH 服务器）中必须零报错启动。

---

## 2. 跨平台与前置安装检查约束

- **自动区分系统**：`zsh/common.zsh` 必须通过 `uname -s` 区分 `Darwin` 与 `Linux`，严禁在 Linux 下强依赖 Homebrew、iTerm2 或 macOS 专属命令（如 `pbcopy`、`open`）。
- **平台资产隔离**：仅限 macOS 的配置文件必须放在 `macos/` 目录下（如 `macos/iterm2/`），不影响 Linux 接入。
- **Vim 跨平台保护**：系统剪贴板等特性必须加 `has('clipboard')` 等特性检测，兼容 Linux 精简版 Vim。
- **必备前置 vs 可选项处理规范（AI 部署时必须遵守）**：
  - **必备前置**（如 `zsh`、`curl`、`python3`、`oh-my-zsh`，以及 macOS 下的 `Homebrew`）：部署前先检查，若缺失则自动安装或明确提醒用户安装；涉及本机身份配置（如 `git config` 用户名/邮箱）时，只提醒用户手动输入，绝不硬编码或写入本仓库。
  - **非必备可选项**（如 **GitHub 登录鉴权**、`autojump`、`ripgrep`、`vim-plug`、iTerm2、`goenv` + Go）：部署前**必须先询问用户是否需要安装**，按需跳过，不要擅自全部安装。
  - **外网 Linux VPS 安全红线**：不要在公网/临时 VPS 上配置个人 GitHub SSH 私钥或登录 `gh`，优先提示用户从本地 Mac 通过 `rsync --exclude='.git'` 单向推送 `~/dotfiles`。

---

## 3. 插件与速查表强制联动规则

- 每次在 Zsh 或 Vim 中**新增、卸载或修改插件 / 快捷键**时，AI **必须自动同步更新**对应速查表，无需用户再次提醒：
  - Zsh / iTerm2 变更 → 更新 `cheatsheets/shell.md`（macOS 专属项须标注 `[macOS]`）
  - Vim 变更 → 更新 `cheatsheets/vim.md`
- **速查表编写标准**：
  - Vim 速查表将「Vim 核心快捷键」放在最上方，插件快捷键按插件名分类列出。
  - 只保留高频核心快捷键，控制精炼易读；卸载插件时必须同步清理其对应条目。
  - 两端触发方式保持统一：Shell 中敲 `hh`，Vim 中敲 `:hh`（及 `\?`）。

---

## 4. 脱敏与隐私安全红线（本仓库为 Public 公开仓库！）

> **最高优先级警告**：本仓库为 **GitHub Public 公开仓库**，任何人均可读取所有文件与完整 Git 历史。每次 `git commit` / `git push` 之前，AI **必须执行以下检查**：

1. **禁止硬编码用户名或本机绝对路径**：
   - 全仓库严禁出现 `/Users/<用户名>`、`/home/<用户名>` 或具体主机名；路径一律使用 `$HOME`、`~` 或 `$DOTFILES_DIR`。
2. **禁止提交任何敏感或公司专属信息**：
   - 严禁将 Git 私钥、API Key、Token、密码、`GOPRIVATE`、公司私有 `GOPROXY`、内网域名、内部 CLI 配置写入本仓库。
   - 提交前必须检查 `git diff` 确认只包含通用个人偏好。
3. **iTerm2 `com.googlecode.iterm2.plist` 脱敏清单**：
   - 如需更新 `macos/iterm2/com.googlecode.iterm2.plist`，必须先转为 XML 格式（`plutil -convert xml1`），并完成以下清理：
     - 将所有 Bookmark 中的 `Working Directory` 改为 `~`。
     - 删除以下前缀的本机运行态/隐私字段：`NoSync*`、`NSNav*`、`NSWindow Frame*`、`NSSplitView*`、`NSToolbar*`、`SU*`。
4. **公司电脑合规边界**：
   - 在公司电脑上应仅单向拉取（`git pull`）使用，避免在未经人工严格审查 `git diff` 的情况下将变更 `git push` 回本仓库。

---

## 5. 插件精简原则（AI 时代）

- **Zsh**：只保留零延迟交互体验刚需插件（如自动建议、语法高亮、目录跳转、`sudo`、`git`），避免堆砌大量低频 alias 插件拖慢启动速度。
- **Vim**：定位为「终端看代码 + 轻量编辑」，坚持零编译依赖、秒开原则；不引入重型 C++ 编译型补全引擎（如 YouCompleteMe）。
