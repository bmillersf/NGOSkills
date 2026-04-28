#!/usr/bin/env python3
"""
Nonprofit Skill Router — Cursor Hook
Reads prompt from stdin JSON, matches against keyword index,
returns agent_message with skill routing guidance.
"""

import json
import re
import sys
from pathlib import Path


def main():
    repo_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent.parent
    index_file = repo_root / "content" / "keyword-index.json"

    try:
        raw = sys.stdin.read()
        data = json.loads(raw) if raw.strip() else {}
    except (json.JSONDecodeError, OSError):
        data = {}

    prompt = data.get("prompt", data.get("input", ""))
    if not prompt or not index_file.exists():
        print(json.dumps({"permission": "allow"}))
        return

    prompt_lower = prompt.lower()

    try:
        index = json.loads(index_file.read_text())
    except (json.JSONDecodeError, OSError):
        print(json.dumps({"permission": "allow"}))
        return

    matches: dict[str, list[str]] = {}
    for skill_name, skill_data in index.get("skills", {}).items():
        matched_kws = []
        for kw in skill_data.get("keywords", []):
            kw_lower = kw.lower()
            if len(kw_lower) <= 3:
                if re.search(r"\b" + re.escape(kw_lower) + r"\b", prompt_lower):
                    matched_kws.append(kw)
            elif kw_lower in prompt_lower:
                matched_kws.append(kw)
        if matched_kws:
            matches[skill_name] = matched_kws

    if not matches:
        print(json.dumps({"permission": "allow"}))
        return

    priority = [
        "sf-nonprofit-cloud",
        "sf-nonprofit-npsp",
        "sf-nonprofit-fundraising",
        "sf-nonprofit-grants",
        "sf-nonprofit-program-case",
        "sf-nonprofit-experience-cloud",
        "sf-nonprofit-experience-cloud-ux",
    ]
    sorted_matches = sorted(
        matches.items(),
        key=lambda x: (priority.index(x[0]) if x[0] in priority else 99, -len(x[1])),
    )

    lines = ["Nonprofit skill auto-routing detected the following relevant skills:"]
    for skill, kws in sorted_matches:
        preview = ", ".join(kws[:5])
        suffix = "..." if len(kws) > 5 else ""
        lines.append(f"  - {skill} (matched: {preview}{suffix})")

    npsp_kws: set[str] = set()
    npc_kws: set[str] = set()
    for skill, kws in matches.items():
        if "npsp" in skill:
            npsp_kws.update(kws)
        elif skill != "sf-nonprofit-cloud":
            npc_kws.update(kws)

    if npsp_kws and npc_kws:
        lines.append("")
        lines.append(
            "WARNING: Both NPSP and NPC keywords detected. "
            "Determine the org platform before proceeding. "
            "Apply sf-nonprofit-cloud first to route correctly."
        )
    elif npsp_kws:
        lines.append("")
        lines.append("Platform: NPSP detected. Apply sf-nonprofit-npsp skill.")
    elif npc_kws:
        lines.append("")
        lines.append("Platform: Nonprofit Cloud (NPC) detected. Apply the matched NPC skill(s).")

    print(json.dumps({
        "permission": "allow",
        "agent_message": "\n".join(lines),
    }))


if __name__ == "__main__":
    main()
