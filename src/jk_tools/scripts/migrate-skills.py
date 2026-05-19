#!/usr/bin/env python3
"""One-shot migration script for plan 022-skills-layout-migration.

Moves source files into the categorized `skills/<category>/<slug>/SKILL.md` layout:

  agents/v2-commands/*.md  (minus 4 skip-list docs)  ->  skills/SDD/<stem>/SKILL.md
  other-skills/grill-me.md                            ->  skills/general/grill-me/SKILL.md
  other-skills/shopping-hunter.md                     ->  skills/personal/shopping-hunter/SKILL.md

For each output:
  - frontmatter is `name: <leaf-folder-name>` + the source `description:` preserved verbatim
  - body byte-identical to source (only the original frontmatter block is replaced)

Idempotency contract:
  - If dest SKILL.md already exists with byte-identical content -> skip silently, log [skip]
  - If dest exists with DIFFERENT content -> error and exit non-zero
  - --force overrides the "different" check and overwrites

Dependencies: stdlib + PyYAML (pip install pyyaml).
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("ERROR: PyYAML required. Run: pip install pyyaml\n")
    sys.exit(2)


REPO_ROOT = Path(__file__).resolve().parent.parent

V2_SOURCE_DIR = REPO_ROOT / "agents" / "v2-commands"
OTHER_SKILLS_DIR = REPO_ROOT / "other-skills"
SKILLS_DIR = REPO_ROOT / "skills"

# Files in agents/v2-commands/ that are NOT installable skills
SKIP_LIST = {"README.md", "GETTING-STARTED.md", "changes.md", "codebase.md"}

# Explicit other-skills mappings: (source filename, target category)
OTHER_SKILLS_MAP = [
    ("grill-me.md", "general"),
    ("shopping-hunter.md", "personal"),
]

FRONTMATTER_RE = re.compile(r"\A---\s*\n(.*?)\n---\s*\n", re.DOTALL)


def parse_source(text: str) -> tuple[dict, str]:
    """Return (frontmatter_dict, body) split at the first --- ... --- block.

    Body is everything after the closing `---\\n`. Byte-identical to source body.
    """
    m = FRONTMATTER_RE.match(text)
    if not m:
        raise ValueError("no YAML frontmatter found")
    fm = yaml.safe_load(m.group(1)) or {}
    if not isinstance(fm, dict):
        raise ValueError(f"frontmatter is not a mapping: {type(fm).__name__}")
    body = text[m.end():]
    return fm, body


def build_skill_md(slug: str, description: str, body: str) -> str:
    """Emit a SKILL.md with name + description frontmatter and untouched body."""
    fm = {"name": slug, "description": description}
    yaml_block = yaml.safe_dump(fm, sort_keys=False, allow_unicode=True,
                                default_flow_style=False, width=2**31).rstrip()
    return f"---\n{yaml_block}\n---\n{body}"


def plan_pairs() -> list[tuple[Path, Path, str]]:
    """Return list of (source_path, dest_path, slug) tuples."""
    pairs: list[tuple[Path, Path, str]] = []

    for src in sorted(V2_SOURCE_DIR.glob("*.md")):
        if src.name in SKIP_LIST:
            continue
        slug = src.stem
        dest = SKILLS_DIR / "SDD" / slug / "SKILL.md"
        pairs.append((src, dest, slug))

    for filename, category in OTHER_SKILLS_MAP:
        src = OTHER_SKILLS_DIR / filename
        slug = src.stem
        dest = SKILLS_DIR / category / slug / "SKILL.md"
        pairs.append((src, dest, slug))

    return pairs


def migrate_one(src: Path, dest: Path, slug: str, *, dry_run: bool,
                force: bool) -> str:
    """Migrate one source file. Returns log line."""
    text = src.read_text(encoding="utf-8")
    fm, body = parse_source(text)
    description = fm.get("description")
    if not description:
        raise ValueError(f"{src}: missing or empty `description:` in frontmatter")

    new_content = build_skill_md(slug, description, body)

    if dest.exists():
        existing = dest.read_text(encoding="utf-8")
        if existing == new_content:
            return f"[skip] {slug} (byte-identical)"
        if not force:
            raise SystemExit(
                f"ERROR: {dest} already exists with DIFFERENT content. "
                f"Use --force to overwrite."
            )
        action = "overwrite"
    else:
        action = "create"

    if dry_run:
        return f"[dry-run {action}] {src.relative_to(REPO_ROOT)} -> {dest.relative_to(REPO_ROOT)}"

    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(new_content, encoding="utf-8")
    return f"[{action}] {slug}"


def verify_body_bytediff(pairs: list[tuple[Path, Path, str]]) -> list[str]:
    """For each migrated pair, verify body bytes match source body bytes.

    Returns list of mismatches (empty if all OK).
    """
    mismatches: list[str] = []
    for src, dest, slug in pairs:
        if not dest.exists():
            mismatches.append(f"{slug}: dest missing ({dest})")
            continue
        _, src_body = parse_source(src.read_text(encoding="utf-8"))
        _, dest_body = parse_source(dest.read_text(encoding="utf-8"))
        if src_body != dest_body:
            mismatches.append(
                f"{slug}: body byte-diff (src={len(src_body)}B dest={len(dest_body)}B)"
            )
    return mismatches


def main() -> int:
    ap = argparse.ArgumentParser(description="Migrate v2-commands + other-skills to skills/")
    ap.add_argument("--dry-run", action="store_true", help="Print actions, write nothing")
    ap.add_argument("--force", action="store_true", help="Overwrite differing destinations")
    ap.add_argument("--verify", action="store_true",
                    help="After (or instead of) migration, verify body byte-diff")
    args = ap.parse_args()

    pairs = plan_pairs()
    print(f"Planned migrations: {len(pairs)}")

    for src, dest, slug in pairs:
        if not src.exists():
            print(f"ERROR: source missing: {src}", file=sys.stderr)
            return 1
        log = migrate_one(src, dest, slug, dry_run=args.dry_run, force=args.force)
        print(log)

    if args.verify or (not args.dry_run):
        mismatches = verify_body_bytediff(pairs)
        if mismatches:
            print("\nBYTE-DIFF MISMATCHES:", file=sys.stderr)
            for m in mismatches:
                print(f"  {m}", file=sys.stderr)
            return 1
        print(f"\nBody byte-diff verification: {len(pairs)}/{len(pairs)} OK")

    return 0


if __name__ == "__main__":
    sys.exit(main())
