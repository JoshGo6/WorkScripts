#!/usr/bin/env python3
"""
Convert a hierarchical JSON TOC into the established YAML format.

Rules:
- Map JSON "label" -> YAML "title".
- Always include keys: title, path, children.
- If a node has no children, set `children: none`.
- Preserve order and hierarchy exactly as the input JSON.
- If a node lacks "path", emit an empty string for path to satisfy the schema.
- Output file uses the same basename as input, with ".yaml".
- Top-level key is "toc:".
"""

import sys, json
from pathlib import Path
from typing import List, Dict, Any

def to_nodes(items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    def convert(node: Dict[str, Any]) -> Dict[str, Any]:
        title = node.get("label", "")
        path = node.get("path", "")
        kids = node.get("children", None)
        if kids and isinstance(kids, list) and len(kids) > 0:
            children = [convert(c) for c in kids]
        else:
            children = None
        return {"title": title, "path": path, "children": children}
    return [convert(n) for n in items]

def render_yaml(nodes: List[Dict[str, Any]]) -> str:
    lines: List[str] = []
    lines.append("toc:")
    def emit_node(n: Dict[str, Any], indent: int):
        ind = "  " * indent
        t = n["title"].replace('"', '\\"')
        p = (n["path"] or "").replace('"', '\\"')
        lines.append(f'{ind}- title: "{t}"')
        lines.append(f'{ind}  path: "{p}"')
        if n["children"] is None:
            lines.append(f"{ind}  children: none")
        else:
            lines.append(f"{ind}  children:")
            for c in n["children"]:
                emit_node(c, indent + 2)
    for n in nodes:
        emit_node(n, 1)
    return "\n".join(lines) + "\n"

def main():
    if len(sys.argv) != 2:
        print("Usage: json-toc-to-yaml.py <input.json>", file=sys.stderr)
        sys.exit(2)
    in_path = Path(sys.argv[1])
    if not in_path.exists():
        print(f"Input not found: {in_path}", file=sys.stderr)
        sys.exit(1)
    data = json.loads(in_path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        print("Top-level JSON must be a list of nodes.", file=sys.stderr)
        sys.exit(3)
    nodes = to_nodes(data)
    out_text = render_yaml(nodes)
    out_path = in_path.with_suffix(".yaml")
    out_path.write_text(out_text, encoding="utf-8")
    print(f"Wrote: {out_path}")

if __name__ == "__main__":
    main()
