#!/usr/bin/env python3
"""Extract multipart RAR archives as one archive on macOS.

Usage:
  python3 rar_parts_extract.py /path/to/archive.part1.rar
  python3 rar_parts_extract.py /path/to/archive.part1.rar --output /path/to/out
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path


PART_RE = re.compile(r"^(?P<base>.+)\.part(?P<num>\d+)\.rar$", re.I)


def find_volumes(first: Path) -> list[Path]:
    match = PART_RE.match(first.name)
    if not match:
        raise ValueError("Choose the first volume, whose name ends in .part1.rar")
    volumes = []
    n = 1
    while True:
        candidate = first.with_name(f"{match.group('base')}.part{n}.rar")
        if not candidate.exists():
            break
        volumes.append(candidate)
        n += 1
    if not volumes or volumes[0] != first:
        raise FileNotFoundError("The selected archive must be the .part1.rar volume")
    return volumes


def extractor() -> tuple[str, list[str]]:
    # 7zz is preferred; unar is also excellent for RAR5.
    for name, args in (("7zz", ["x"]), ("7z", ["x"]), ("unar", []), ("unrar", ["x"])):
        path = shutil.which(name)
        if path:
            return path, args
    raise RuntimeError(
        "No RAR extractor found. Install one with: brew install unar"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract multipart RAR volumes together")
    parser.add_argument("archive", type=Path, help="the .part1.rar file")
    parser.add_argument("--output", type=Path, help="destination folder (default: beside archive)")
    args = parser.parse_args()
    first = args.archive.expanduser().resolve()
    if not first.is_file():
        parser.error(f"File not found: {first}")
    try:
        volumes = find_volumes(first)
        program, program_args = extractor()
    except (ValueError, FileNotFoundError, RuntimeError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2

    destination = (args.output or first.parent / first.name.removesuffix(".part1.rar")).expanduser().resolve()
    destination.mkdir(parents=True, exist_ok=True)
    print(f"Found {len(volumes)} volume(s): part1 through part{len(volumes)}")
    print(f"Extracting into: {destination}")
    if Path(program).name.lower() == "unar":
        command = [program, "-output-directory", str(destination), str(first)]
    else:
        command = [program, *program_args, str(first), f"-o{destination}", "-y"]
    completed = subprocess.run(command)
    if completed.returncode == 0:
        print("Done. All volumes were extracted as one archive.")
    else:
        print("Extraction failed. Check that every volume is from the same download.", file=sys.stderr)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
