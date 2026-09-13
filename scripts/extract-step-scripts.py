#!/usr/bin/env python3
"""Extract each `run:` block of a GitHub workflow into standalone .sh files.

Used by the script-validation harness so every step can be syntax-checked
(and selected steps executed) with the same shell CI uses (dash on trixie).
"""
import os
import sys

import yaml

wf_path, out_dir = sys.argv[1], sys.argv[2]
os.makedirs(out_dir, exist_ok=True)
wf = yaml.safe_load(open(wf_path))
count = 0
for job in wf["jobs"].values():
    for step in job.get("steps", []):
        if "run" in step:
            count += 1
            slug = "".join(c if c.isalnum() else "-" for c in step.get("name", f"step{count}"))[:50]
            with open(os.path.join(out_dir, f"{count:02d}-{slug}.sh"), "w") as f:
                f.write(step["run"])
print(f"wrote {count} scripts to {out_dir}")
