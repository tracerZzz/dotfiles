# AGENTS.md — 仓库维护与 AI 协作约束

本文档定义 AI（`agy`、`codex`、`claude code` 等）在修改、维护或在新机器上部署本 `dotfiles` 仓库时**必须严格遵守的规则**。

---

## 1. 非侵入式配置原则（核心架构约束）

- **禁止覆盖宿主机默认配置文件**：
  - 永远不要用本仓库的文件直接覆盖或软链接替换宿主机的 `~/.zshrc` 或 `~/.vimrc`。
  - 宿主机原本的环境变量、代理、VPN/SSO、公司内部 CLI 等配置留在宿主机自己的 `~/.zshrc` / `~/.vimrc` 中。
  - 所有跨机器通用配置必须写在 `zsh/common.zsh` 和 `vim/common.vim` 中，宿主机仅通过末尾追加一行 `source` 引入：
    - Zsh：`[[ -f "$HOME/dotfiles/zsh/common.zsh" ]] && source "$HOME/dotfiles/zsh/common.zsh"`
    - Vim：`if filereadable(expand('~/dotfiles/vim/common.vim')) | source ~/dotfiles/vim/common.vim | endif`
- **加载幂等与容错**：
  - `zsh/common.zsh` 在宿主机 `oh-my-zsh.sh` 之后加载也必须正常工作，且不重复污染 `PATH`、不重复加载已激活的插件。
  - `vim/common.vim` 在未安装 `vim-plug` 或未安装插件的环境（如 SSH 服务器）中必须零报错启动。

---

## 2. 插件与速查表强制联动规则

- 每次在 Zsh 或 Vim 中**新增、卸载或修改插件 / 快捷键**时，AI **必须自动同步更新**对应速查表，无需用户再次提醒：
  - Zsh / iTerm2 变更 → 更新 `cheatsheets/shell.md`
  - Vim 变更 → 更新 `cheatsheets/vim.md`
- **速查表编写标准**：
  - Vim 速查表将「Vim 核心快捷键」放在最上方，插件快捷键按插件名分类列出。
  - 只保留高频核心快捷键，控制精炼易读；卸载插件时必须同步清理其对应条目。
  - 两端触发方式保持统一：Shell 中敲 `hh`，Vim 中敲 `:hh`（及 `\?`）。

---

## 3. 脱敏与隐私安全红线

每次 `git commit` / `git push` 之前，AI **必须执行以下检查**：

1. **禁止硬编码用户名或本机绝对路径**：
   - 全仓库严禁出现 `/Users/<用户名>` 或具体主机名；路径一律使用 `$HOME`、`~` 或 `$DOTFILES_DIR`。
2. **禁止提交任何敏感或公司专属信息**：
   - 严禁将 API Key、Token、密码、公司内网域名、代理地址、内部 CLI 配置写入本仓库。
   - 提交前必须检查 `git diff` 确认只包含通用个人偏好。
3. **iTerm2 `com.googlecode.iterm2.plist` 脱敏清单**：
   - 如需更新 `iterm2/com.googlecode.iterm2.plist`，必须先转为 XML 格式（`plutil -convert xml1`），并完成以下清理：
     - 将所有 Bookmark 中的 `Working Directory` 改为 `~`。
     - 删除以下前缀的本机运行态/隐私字段：`NoSync*`、`NSNav*`、`NSWindow Frame*`、`NSSplitView*`、`NSToolbar*`、`SU*`。
4. **公司电脑合规边界**：
   - 在公司电脑上应仅单向拉取（`git pull`）使用，避免在未经人工严格审查 `git diff` 的情况下将变更 `git push` 回本仓库。

---

## 4. 插件精简原则（AI 时代）

- **Zsh**：只保留零延迟交互体验刚需插件（如自动建议、语法高亮、目录跳转、`sudo`、`git`），避免堆砌大量低频 alias 插件拖慢启动速度。
- **Vim**：定位为「终端看代码 + 轻量编辑」，坚持零编译依赖、秒开原则；不引入重型 C++ 编译型补全引擎（如 YouCompleteMe）。
