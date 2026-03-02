# 📊 Git Auto Report (工作汇报自动生成器)

一个轻量级、高度可定制的命令行工具。通过自动扫描本地指定目录下的所有 Git 仓库，提取你的 Commit 历史，一键生成结构清晰、排版优雅的 Markdown 工作汇报（支持按天或按项目分组）。

无论是撰写每日晨报、周报，还是查阅团队本月的研发产出，它都能帮你节省大量回忆和排版的时间。

## ✨ 特性

- 🚀 **一键汇总**：递归扫描多个独立项目，跨仓库收集提交记录。
- 🎨 **智能排版**：自动识别 `feat/fix/refactor` 等 Conventional Commits 规范，支持标准 Markdown 与简洁纯文本双模式。
- ⚙️ **交互式配置**：首次运行向导，配置持久化保存，避免每次输入重复参数。
- 💻 **跨平台支持**：完美兼容 macOS (原生支持 Intel 及 Apple Silicon 芯片)、Linux 以及 Windows（借助 Git Bash）。
- 🔒 **安全可靠**：无侵入式读取，采用严格的临时文件销毁机制（Trap），不残留敏感信息。

## 📥 安装指南

建议将此工具放置在专门存放自用脚本的目录中，以便统一管理。

### 1. 克隆仓库
```bash
git clone https://github.com/Dyolem/git-auto-report.git ~/Developer/Tools/git-auto-report
```

### 2. 赋予执行权限 (Mac/Linux)
```bash
chmod +x ~/Developer/Tools/git-auto-report/report.sh
```

### 3. 环境配置与别名绑定

#### 🍎 macOS / 🐧 Linux 
打开你的终端配置文件（例如 `~/.zshrc` 或 `~/.bashrc`），添加以下快捷别名：
```bash
alias git-report="~/Developer/Tools/git-auto-report/report.sh"
```
保存后，执行 `source ~/.zshrc` 使配置立即生效。

#### 🪟 Windows
1. 确保你的电脑上已经安装了 **Git for Windows**，并且 `bash.exe` 可以正常调用。
2. 将你克隆下来的仓库文件夹路径（包含 `report.cmd` 的那个目录）添加到系统的**全局环境变量 `Path`** 中。
3. 以后在 CMD 或 PowerShell 中，直接输入 `report` 即可运行。

## 🛠️ 首次初始化与配置修改

首次执行命令时，脚本会触发交互式向导，引导你设置**默认扫描的父目录**（例如 `~/Developer/Work`）。

如果你后续需要在不同电脑间同步，或者想要修改这些默认配置，可以通过以下两种方式：
1. **重新运行向导**：执行 `git-report --init` (Windows 下为 `report --init`)
2. **直接修改配置文件**：编辑系统根目录下自动生成的 `~/.git-auto-report.conf` 文件。

## 🚀 使用示例

默认情况下，脚本**仅在终端打印输出**，不会产生多余的文件。

### 1. 快捷时间生成 (最常用)
```bash
# 生成今天的日报 (从今日凌晨到现在)
git-report day

# 生成最近一周的周报
git-report week

# 生成最近一个月的汇报
git-report month
```

### 2. 导出为 Markdown 文件
如果需要保存为实体文件归档，请追加 `--save`（默认生成当天日期的文件，如 `WorkReport_2026-03-02.md`）或使用 `-o <文件名>` 自定义：
```bash
git-report day --save
git-report week -o MyWeeklyReport.md
```

### 3. 按项目维度生成周报
写周报时，通常希望以“项目”为维度进行聚合，而不是按天流水账，同时附带分支信息以便追溯：
```bash
git-report week --by-repo --branch
```

### 4. 极致简洁模式
如果你只是想快速复制纯文本发到企业聊天工具里，不需要 Markdown 的 Emoji 和标题语法：
```bash
git-report day --concise
```

### 5. Leader 视角：查阅团队整体产出
忽略当前你本地的 Git 全局用户限制，拉取目录下所有人的代码提交记录，并标注具体作者：
```bash
git-report month --team --save
```

## 📖 全参数清单

| 参数 | 说明 |
| :--- | :--- |
| `--init` | 触发交互式初始化配置 |
| `day`/`week`/`month` | 快捷时间段修饰符 |
| `--dir <路径>` | 临时覆盖配置文件中的工作目录 |
| `--after <时间>` | 自定义起始时间 (如 `2026-01-01` 或 `yesterday`) |
| `--before <时间>` | 自定义结束时间 |
| `--by-repo` | 将聚合维度改为“按项目 (Repo)”分组 |
| `--concise` | 开启纯文本简洁排版 (不使用 Markdown Emoji) |
| `--branch` | 在每条记录后展示所属分支标签 |
| `--asc` | 日志顺序由旧到新排布 (默认由新到旧) |
| `--save` | 将终端输出结果保存为本地 Markdown 文件 |
| `-o`, `--out <文件>` | 将结果保存为指定的本地文件 |
| `--user <名字>` | 只提取特定作者的记录 |
| `--email <邮箱>`| 只提取特定邮箱的记录 |
| `--team` | 团队模式：拉取所有人的记录并标出作者名 |

## 🤝 贡献与反馈
欢迎提交 Issue 和 Pull Request，分享你觉得能提升大家工作效率的新功能！

## 📄 License
[MIT License](LICENSE)