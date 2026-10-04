#!/usr/bin/env python3
"""Upload the enemy rigs in game/assets/rigs/*.rbxm to Roblox as Model assets.

Reuses the wave 8 Open Cloud flow from upload_models.py (create asset, then poll the
operation), but sends .rbxm files instead of FBX. Prints one asset ID per rig and keeps
them in tools/.rig_upload_cache.json so an unchanged rig is never uploaded twice.

Usage (the key is read from ROBLOX_API_KEY or typed at a hidden prompt):
    python tools/upload_rigs.py --user-id <your Roblox user id>
"""

from __future__ import annotations

import argparse
import getpass
import json
import os
import time
from pathlib import Path
from typing import Sequence

from upload_models import ASSETS_URL, OPERATIONS_URL, load_cache, save_cache, sha256_file

ROOT = Path(__file__).resolve().parent.parent
RIG_DIR = ROOT / "game" / "assets" / "rigs"
CACHE = ROOT / "tools" / ".rig_upload_cache.json"
ROLES = ("Mite", "Runner", "Shooter", "Tank", "Flyer")


def upload_rig(session, api_key: str, path: Path, role: str, creator_kind: str, creator_id: int) -> int:
    headers = {"x-api-key": api_key}
    request_data = {
        "assetType": "Model",
        "displayName": f"SwarmBreak {role}",
        "description": f"SwarmBreak enemy rig {role}",
        "creationContext": {"creator": {creator_kind: str(creator_id)}},
    }
    with path.open("rb") as rig_file:
        response = session.post(
            ASSETS_URL,
            headers=headers,
            files={
                "request": (None, json.dumps(request_data), "application/json"),
                "fileContent": (path.name, rig_file, "model/x-rbxm"),
            },
            timeout=60,
        )
    response.raise_for_status()
    operation_path = response.json().get("path")
    if not operation_path:
        raise RuntimeError("upload response did not include an operation path")
    operation_url = f"{OPERATIONS_URL}/{operation_path.lstrip('/')}"
    for _ in range(300):
        status = session.get(operation_url, headers=headers, timeout=60).json()
        if status.get("done") is True:
            if "error" in status:
                raise RuntimeError(f"upload of {role} failed: {status['error']}")
            return int(status["response"]["assetId"])
        time.sleep(1)
    raise TimeoutError(f"upload of {role} did not finish")


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    creator = parser.add_mutually_exclusive_group(required=True)
    creator.add_argument("--user-id", type=int)
    creator.add_argument("--group-id", type=int)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)
    creator_kind = "userId" if args.user_id else "groupId"
    creator_id = args.user_id or args.group_id

    cache = load_cache(CACHE)
    todo = []
    for role in ROLES:
        path = RIG_DIR / f"{role}.rbxm"
        digest = sha256_file(path)
        cached = cache.get(role, {})
        if cached.get("sha256") == digest and cached.get("assetId"):
            print(f"{role}: {cached['assetId']} (unchanged)")
        else:
            todo.append((role, path, digest))
    if args.dry_run or not todo:
        for role, path, _ in todo:
            print(f"Would upload {role}: {path}")
        return 0

    api_key = os.environ.get("ROBLOX_API_KEY") or getpass.getpass("Roblox Open Cloud API key: ")
    if not api_key:
        raise SystemExit("an Open Cloud API key is required")
    import requests

    session = requests.Session()
    for role, path, digest in todo:
        asset_id = upload_rig(session, api_key, path, role, creator_kind, creator_id)
        cache[role] = {"assetId": asset_id, "sha256": digest}
        save_cache(CACHE, cache)
        print(f"{role}: {asset_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
