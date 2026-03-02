#!/bin/bash

# ================= 配置文件与初始化 =================
CONFIG_FILE="$HOME/.git-auto-report.conf"

# 默认安全变量定义
DEFAULT_WORK_DIR="$HOME/Work"
DEFAULT_GROUP_BY="date"
DEFAULT_ALIGN_MODE="inline" # 将默认对齐模式改为 inline

# 如果配置文件不存在，或者用户传入了 --init 参数，则进入交互式配置
if [ ! -f "$CONFIG_FILE" ] || [ "$1" == "--init" ]; then
    echo "=========================================="
    echo -e "👋 欢迎使用 Git Auto Report"
    echo -e "首次运行或重新配置，请设置您的偏好参数："
    echo "=========================================="
    
    read -p "📁 1. 请输入默认扫描的父级工作目录 (例如 ~/Developer/Work): " input_dir
    read -p "📊 2. 默认报告分组方式 (输入 date 或 repo) [默认 date]: " input_group
    read -p "🎨 3. 简洁模式下的默认对齐方式 (输入 inline 或 list) [默认 inline]: " input_align
    
    # 处理空输入
    input_dir="${input_dir:-$DEFAULT_WORK_DIR}"
    input_group="${input_group:-$DEFAULT_GROUP_BY}"
    input_align="${input_align:-$DEFAULT_ALIGN_MODE}"
    
    # 写入配置文件
    echo "# Git Auto Report 配置文件" > "$CONFIG_FILE"
    echo "WORK_DIR=\"$input_dir\"" >> "$CONFIG_FILE"
    echo "GROUP_BY=\"$input_group\"" >> "$CONFIG_FILE"
    echo "ALIGN_MODE=\"$input_align\"" >> "$CONFIG_FILE"
    
    echo -e "\n✅ 配置已保存至 $CONFIG_FILE。"
    echo -e "💡 提示：您可以随时修改该文件，或运行 './report.sh --init' 重新设置。\n"
    
    if [ "$1" == "--init" ]; then exit 0; fi
fi

# 加载用户配置
source "$CONFIG_FILE"

# 兼容旧版本配置文件：如果配置中没有 ALIGN_MODE，则使用默认值
ALIGN_MODE="${ALIGN_MODE:-$DEFAULT_ALIGN_MODE}"

# ================= 动态参数配置 =================
AFTER_DATE="midnight"
BEFORE_DATE="now"
SHOW_BRANCH=false
SORT_ASC=false     
CONCISE_MODE=false 
INDENT_SPACES=4    # 默认缩进空格数
TEAM_MODE=false    
SAVE_TO_FILE=false 

CUSTOM_USER=$(git config --global user.name 2>/dev/null)
CUSTOM_EMAIL=$(git config --global user.email 2>/dev/null)
TODAY=$(date +%Y-%m-%d)
OUTPUT_FILE=""

# --- 参数解析 ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --user) CUSTOM_USER="$2"; shift ;;
        --email) CUSTOM_EMAIL="$2"; shift ;;
        --dir) WORK_DIR="$2"; shift ;;
        --after) AFTER_DATE="$2"; shift ;;
        --before) BEFORE_DATE="$2"; shift ;;
        --by-repo) GROUP_BY="repo" ;;
        --asc) SORT_ASC=true ;;
        --concise) CONCISE_MODE=true ;;
        --align) ALIGN_MODE="$2"; shift ;;
        --indent) INDENT_SPACES="$2"; shift ;;
        --team) TEAM_MODE=true ;;
        --save) SAVE_TO_FILE=true; OUTPUT_FILE="WorkReport_${TODAY}.md" ;;
        --out|-o) SAVE_TO_FILE=true; OUTPUT_FILE="$2"; shift ;;
        day) AFTER_DATE="midnight"; BEFORE_DATE="now" ;;
        week) AFTER_DATE="1 week ago"; BEFORE_DATE="now" ;;
        month) AFTER_DATE="1 month ago"; BEFORE_DATE="now" ;;
        --branch) SHOW_BRANCH=true ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
    shift
done

# 处理波浪号路径扩展
if [[ "$WORK_DIR" == ~* ]]; then WORK_DIR="${WORK_DIR/#\~/$HOME}"; fi

# 安全措施：创建临时文件并设置 Trap，确保脚本意外退出时清理干净
TEMP_LOG_FILE=$(mktemp)
SORTED_FILE=$(mktemp)
trap 'rm -f "$TEMP_LOG_FILE" "$SORTED_FILE"' EXIT INT TERM

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'
DELIM="###"

echo "=========================================="
echo -e "正在生成汇报..."
echo -e "工作区: ${BLUE}$WORK_DIR${NC}"
echo -e "外观: $(if [ "$CONCISE_MODE" = true ]; then echo "${YELLOW}简洁模式 (${ALIGN_MODE} 对齐, 缩进 ${INDENT_SPACES} 字符)${NC}"; else echo "${GREEN}标准 Markdown${NC}"; fi)"
echo "=========================================="
echo ""

# === 核心日志收集与排版逻辑 ===
find "$WORK_DIR" -type d \( -path "*/node_modules" -o -path "*/.next" -o -path "*/dist" \) -prune -o -name ".git" -type d -print 2>/dev/null | while IFS= read -r gitdir; do
    repo_root=$(dirname "$gitdir")
    cd "$repo_root" || continue
    repo_name=$(basename "$repo_root")

    CMD=(git log)
    if [ -n "$CUSTOM_USER" ]; then CMD+=(--author="$CUSTOM_USER"); fi
    if [ -n "$CUSTOM_EMAIL" ]; then CMD+=(--author="$CUSTOM_EMAIL"); fi
    CMD+=(--after="$AFTER_DATE" --before="$BEFORE_DATE" --no-merges)

    logs=$( "${CMD[@]}" --date=format:'%Y-%m-%d' --pretty=format:"%ai${DELIM}%ad${DELIM}%s${DELIM}%d" 2>/dev/null )
    if [ -n "$logs" ]; then
        echo "$logs" | sed "s/$/${DELIM}$repo_name/" >> "$TEMP_LOG_FILE"
    fi
    cd - > /dev/null
done

if [ ! -s "$TEMP_LOG_FILE" ]; then
    echo "未找到符合条件的提交记录。"
    rm "$TEMP_LOG_FILE" "$SORTED_FILE"
    exit 0
fi

# === 核心排序逻辑 ===
if [ "$GROUP_BY" = "date" ]; then
    if [ "$SORT_ASC" = true ]; then
        awk -F'###' '{print $2 "|" $5 "|" $1 "|" $0}' "$TEMP_LOG_FILE" | sort -t'|' -k1,1 -k2,2 -k3,3 | cut -d'|' -f4- > "$SORTED_FILE"
    else
        awk -F'###' '{print $2 "|" $5 "|" $1 "|" $0}' "$TEMP_LOG_FILE" | sort -t'|' -k1,1r -k2,2 -k3,3r | cut -d'|' -f4- > "$SORTED_FILE"
    fi
else
    if [ "$SORT_ASC" = true ]; then
        awk -F'###' '{print $5 "|" $2 "|" $1 "|" $0}' "$TEMP_LOG_FILE" | sort -t'|' -k1,1 -k2,2 -k3,3 | cut -d'|' -f4- > "$SORTED_FILE"
    else
        awk -F'###' '{print $5 "|" $2 "|" $1 "|" $0}' "$TEMP_LOG_FILE" | sort -t'|' -k1,1 -k2,2r -k3,3r | cut -d'|' -f4- > "$SORTED_FILE"
    fi
fi

# === 使用 AWK 进行规范化分组、提取和排版 ===
FORMATTED_LOGS=$(awk -F'###' -v group_by="$GROUP_BY" -v show_branch="$SHOW_BRANCH" -v concise_mode="$CONCISE_MODE" -v align_mode="$ALIGN_MODE" -v indent_spaces="$INDENT_SPACES" '
# 去除字符串首尾的空格和特殊空白符
function trim(s) {
    sub(/^[ \t\r\n\v\f]+/, "", s);
    sub(/[ \t\r\n\v\f]+$/, "", s);
    gsub(/[ \t]+/, " ", s);
    return s;
}

BEGIN { last_date = ""; last_repo = ""; type_idx = 1; }
{
    iso_time = $1; date_str = $2; msg = $3; branch = $4; repo = $5;

    type = "other";
    clean_msg = msg;
    if (match(msg, /^[a-zA-Z]+(\([^)]+\))?:\s*/)) {
        prefix_len = RLENGTH;
        prefix = substr(msg, 1, prefix_len);
        clean_msg = substr(msg, prefix_len + 1);
        
        split(prefix, parts, ":");
        type_part = parts[1];
        sub(/\(.*$/, "", type_part); 
        type = tolower(type_part);
    }

    branch_str = (show_branch == "true" && length(branch) > 2) ? " `" branch "`" : "";
    line = clean_msg branch_str;

    if (group_by == "date") {
        if (date_str != last_date) {
            if (last_date != "") print_types();
            printf "### 📅 %s\n\n", date_str;
            printf "【📦 %s】\n", repo;
            last_date = date_str; last_repo = repo;
            reset_types();
        } else if (repo != last_repo) {
            print_types();
            printf "【📦 %s】\n", repo;
            last_repo = repo;
            reset_types();
        }
    } else {
        if (repo != last_repo) {
            if (last_repo != "") print_types();
            printf "## 📦 项目: %s\n\n", repo;
            printf "### 📅 %s\n\n", date_str;
            last_repo = repo; last_date = date_str;
            reset_types();
        } else if (date_str != last_date) {
            print_types();
            printf "### 📅 %s\n\n", date_str;
            last_date = date_str;
            reset_types();
        }
    }

    if (!(type in type_logs)) {
        group_types[type_idx++] = type;
        type_logs[type] = "";
    }
    type_logs[type] = type_logs[type] line "\n";
}
END { if (last_date != "" || last_repo != "") print_types(); }

function reset_types() {
    for(k in group_types) delete group_types[k];
    for(k in type_logs) delete type_logs[k];
    type_idx = 1;
}

function print_types() {
    if (type_idx == 1) return;

    priority["feat"] = 1; priority["fix"] = 2; priority["refactor"] = 3; priority["perf"] = 4;
    priority["chore"] = 5; priority["docs"] = 6; priority["style"] = 7; priority["test"] = 8;
    priority["build"] = 9; priority["ci"] = 10; priority["other"] = 11;

    n = type_idx - 1;
    for (i = 1; i <= n; i++) {
        for (j = 1; j < n; j++) {
            p1 = (group_types[j] in priority) ? priority[group_types[j]] : 12;
            p2 = (group_types[j+1] in priority) ? priority[group_types[j+1]] : 12;
            if (p1 > p2) { tmp = group_types[j]; group_types[j] = group_types[j+1]; group_types[j+1] = tmp; }
        }
    }

    # 预生成缩进空格字符串
    pad = "";
    for (p = 0; p < indent_spaces; p++) {
        pad = pad " ";
    }

    for (i = 1; i <= n; i++) {
        t = group_types[i];
        n_msgs = split(type_logs[t], msgs, "\n");
        
        if (t == "feat") { label = "新功能"; cap_type = "✨ Feat (新功能)"; }
        else if (t == "fix") { label = "修复"; cap_type = "🐛 Fix (修复)"; }
        else if (t == "refactor") { label = "重构"; cap_type = "♻️ Refactor (重构)"; }
        else if (t == "chore") { label = "杂项"; cap_type = "🎫 Chore (杂项)"; }
        else if (t == "docs") { label = "文档"; cap_type = "📝 Docs (文档)"; }
        else if (t == "perf") { label = "性能"; cap_type = "⚡️ Perf (性能)"; }
        else { label = "其它"; cap_type = "🔧 " toupper(substr(t, 1, 1)) substr(t, 2); }

        is_first = 1;

        for (m = 1; m < n_msgs; m++) {
            clean_msg_line = trim(msgs[m]);
            if (length(clean_msg_line) == 0) continue;

            if (concise_mode == "true") {
                if (align_mode == "inline") {
                    # Inline 模式：标签独占一行，后续内容统一缩进
                    if (is_first) { printf "%s:\n", label; is_first = 0; }
                    printf "%s%s\n", pad, clean_msg_line;
                } else {
                    # List 模式：标准的 Markdown 列表
                    if (is_first) { printf "- **%s**:\n", label; is_first = 0; }
                    printf "  - %s\n", clean_msg_line;
                }
            } else {
                # 标准模式
                if (is_first) { printf "**%s**\n", cap_type; is_first = 0; }
                printf "- %s\n", clean_msg_line;
            }
        }
    }
    printf "\n";
}
' "$SORTED_FILE")

# === 组装完整文本 ===
FULL_REPORT="# 工作汇报 ($AFTER_DATE 至 $BEFORE_DATE)
Generated by Git Auto Report

$FORMATTED_LOGS"

echo "$FULL_REPORT"

echo "=========================================="
if [ "$SAVE_TO_FILE" = true ]; then
    echo "$FULL_REPORT" > "$OUTPUT_FILE"
    echo -e "✅ 完成！结果已保存至 ${GREEN}$OUTPUT_FILE${NC}"
else
    echo -e "✅ 完成！(💡 若需导出文件，可追加 ${YELLOW}--save${NC})"
fi