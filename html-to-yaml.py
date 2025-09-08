#!/usr/bin/env python3
"""
Transform a Confluence-like HTML page tree into YAML.

Rules:
- Each <li> with an <a href="...">Text</a> becomes a node.
- Nodes preserve the order and nesting in the HTML <ul>/<li> structure.
- Each node has: title, path, children. If no children, children: none.
- Strip query strings (?...) from links.
- Output YAML is written next to the input with ".yaml" extension.
- Top-level key is "toc:".
"""

import sys
from html.parser import HTMLParser
from urllib.parse import urlsplit, urlunsplit
from pathlib import Path
from typing import List, Dict, Optional

class TOCParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack: List[Dict] = []
        self.root: List[Dict] = []
        self.current_anchor_for: Optional[Dict] = None
        self.anchor_text: str = ""

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag.lower() == "li":
            node = {"title": None, "path": None, "children": []}
            self.stack.append(node)
        elif tag.lower() == "a":
            href = attrs.get("href")
            if href and self.stack:
                node = self.stack[-1]
                if node["path"] is None:
                    parts = urlsplit(href)
                    href_clean = urlunsplit((parts.scheme, parts.netloc, parts.path, "", "")) or parts.path
                    node["path"] = href_clean.strip()
                    self.current_anchor_for = node
                    self.anchor_text = ""

    def handle_data(self, data):
        if self.current_anchor_for is not None:
            self.anchor_text += data

    def handle_endtag(self, tag):
        if tag.lower() == "a" and self.current_anchor_for is not None:
            title = self.anchor_text.strip()
            if title:
                self.current_anchor_for["title"] = title
            self.current_anchor_for = None
            self.anchor_text = ""
        elif tag.lower() == "li":
            node = self.stack.pop()
            if not node["children"]:
                node["children"] = None
            if self.stack:
                self.stack[-1]["children"].append(node)
            else:
                self.root.append(node)

def render_yaml(nodes: List[Dict]) -> str:
    lines: List[str] = []
    lines.append("toc:")
    def emit_node(n: Dict, indent: int):
        ind = "  " * indent
        lines.append(f'{ind}- title: "{n["title"]}"')
        lines.append(f'{ind}  path: "{n["path"]}"')
        if n["children"] is None:
            lines.append(f"{ind}  children: none")
        else:
            lines.append(f"{ind}  children:")
            for c in n["children"]:
                emit_node(c, indent + 2)
    for n in nodes:
        emit_node(n, 1)
    return "\n".join(lines) + "\n"

def html_to_yaml(html_text: str) -> List[Dict]:
    parser = TOCParser()
    parser.feed(html_text)
    def prune(n):
        if n["title"] is None or n["path"] is None:
            return None
        if n["children"] is None:
            return {"title": n["title"], "path": n["path"], "children": None}
        else:
            kids = []
            for c in n["children"]:
                pc = prune(c)
                if pc is not None:
                    kids.append(pc)
            return {"title": n["title"], "path": n["path"], "children": kids or None}
    pruned = []
    for n in parser.root:
        p = prune(n)
        if p is not None:
            pruned.append(p)
    return pruned

def main():
    if len(sys.argv) != 2:
        print("Usage: html_to_yaml.py <input.html>", file=sys.stderr)
        sys.exit(2)
    in_path = Path(sys.argv[1])
    if not in_path.exists():
        print(f"Input not found: {in_path}", file=sys.stderr)
        sys.exit(1)
    html = in_path.read_text(encoding="utf-8", errors="ignore")
    nodes = html_to_yaml(html)
    out_path = in_path.with_suffix(".yaml")
    out_path.write_text(render_yaml(nodes), encoding="utf-8")
    print(f"Wrote: {out_path}")

if __name__ == "__main__":
    main()
