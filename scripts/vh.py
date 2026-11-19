#!/usr/bin/env python3
"""Pretty terminal/Vim renderer for Markdown cheatsheets (zero external dependencies)."""

import os
import re
import sys
import unicodedata

# ANSI colors (tuned for One Half Dark / dark terminals)
ANSI = {
    "RESET": "\033[0m",
    "BOLD": "\033[1m",
    "DIM": "\033[2m",
    "CYAN": "\033[36m",
    "BLUE": "\033[34m",
    "YELLOW": "\033[33m",
    "GREEN": "\033[32m",
    "MAGENTA": "\033[35m",
    "WHITE": "\033[97m",
    "GRAY": "\033[90m",
}


def display_width(text: str) -> int:
    """Calculate terminal display width, accounting for ANSI codes and CJK chars."""
    clean = re.sub(r"\033\[[0-9;]*m", "", text)
    width = 0
    for ch in clean:
        if unicodedata.east_asian_width(ch) in ("F", "W"):
            width += 2
        else:
            width += 1
    return width


def pad_right(text: str, target_width: int) -> str:
    return text + " " * max(0, target_width - display_width(text))


def style_inline(text: str, colors: dict, is_key_col: bool = False) -> str:
    def repl_code(m):
        c = (colors["BOLD"] + colors["GREEN"]) if is_key_col else colors["CYAN"]
        return f"{c}{m.group(1)}{colors['RESET']}"

    text = re.sub(r"`([^`]+)`", repl_code, text)
    text = re.sub(r"\*\*([^*]+)\*\*", f"{colors['BOLD']}{colors['WHITE']}\\1{colors['RESET']}", text)
    return text


def render_table(rows: list, colors: dict) -> list:
    if len(rows) < 2:
        return []
    header = rows[0]
    body = [r for r in rows[1:] if not all(re.fullmatch(r"[:\- ]+", c) for c in r)]

    num_cols = len(header)
    styled_header = [f"{colors['BOLD']}{colors['YELLOW']}{c}{colors['RESET']}" for c in header]
    styled_body = []
    for r in body:
        r = (r + [""] * num_cols)[:num_cols]
        styled_row = []
        for idx, cell in enumerate(r):
            is_key = idx == 0
            styled_row.append(style_inline(cell, colors, is_key_col=is_key))
        styled_body.append(styled_row)

    col_widths = [display_width(styled_header[i]) for i in range(num_cols)]
    for r in styled_body:
        for i in range(num_cols):
            col_widths[i] = max(col_widths[i], display_width(r[i]))

    out = []
    h_line = "  ".join(pad_right(styled_header[i], col_widths[i]) for i in range(num_cols))
    sep = colors["GRAY"] + "  ".join("─" * col_widths[i] for i in range(num_cols)) + colors["RESET"]
    out.append(f"  {h_line}")
    out.append(f"  {sep}")
    for r in styled_body:
        line = "  ".join(pad_right(r[i], col_widths[i]) for i in range(num_cols))
        out.append(f"  {line}")
    return out


def render_markdown(path: str, plain: bool = False) -> str:
    colors = {k: "" for k in ANSI} if plain else ANSI

    with open(path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    out = [""]
    table_buf = []

    def flush_table():
        nonlocal table_buf
        if table_buf:
            out.extend(render_table(table_buf, colors))
            out.append("")
            table_buf = []

    for raw in lines:
        line = raw.strip()
        if line.startswith("|") and line.endswith("|"):
            inner = line[1:-1]
            cells = [c.strip().replace(r"\|", "|") for c in re.split(r"(?<!\\)\|", inner)]
            table_buf.append(cells)
            continue
        flush_table()

        if not line or line == "---":
            continue
        elif line.startswith("# "):
            title = style_inline(line[2:], colors)
            out.append(f"{colors['BOLD']}{colors['MAGENTA']}◆ {title}{colors['RESET']}")
            out.append(f"{colors['GRAY']}{'═' * 56}{colors['RESET']}")
        elif line.startswith("## "):
            out.append("")
            out.append(f"{colors['BOLD']}{colors['BLUE']}▸ {line[3:]}{colors['RESET']}")
        elif line.startswith("### "):
            out.append(f"  {colors['BOLD']}{colors['CYAN']}{line[4:]}{colors['RESET']}")
        elif line.startswith("> "):
            out.append(f"  {colors['DIM']}{style_inline(line[2:], colors)}{colors['RESET']}")
        elif line.startswith("- "):
            out.append(f"  • {style_inline(line[2:], colors)}")
        else:
            out.append(f"  {style_inline(line, colors)}")

    flush_table()
    return "\n".join(out) + "\n"


def main():
    args = sys.argv[1:]
    plain = False
    if "--plain" in args:
        plain = True
        args.remove("--plain")

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    default_path = os.path.join(base_dir, "cheatsheets", "shell.md")
    path = args[0] if args else default_path
    if not os.path.exists(path):
        print(f"Cheatsheet not found: {path}", file=sys.stderr)
        sys.exit(1)
    sys.stdout.write(render_markdown(path, plain=plain))


if __name__ == "__main__":
    main()
