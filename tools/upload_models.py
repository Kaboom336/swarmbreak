#!/usr/bin/env python3
"""Upload the model manifest to Roblox and generate ModelAssets.luau.

The network-facing client accepts an injected HTTP session so all request behavior
can be tested without contacting Roblox.
"""

from __future__ import annotations

import argparse
import getpass
import hashlib
import json
import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence


ASSETS_URL = "https://apis.roblox.com/assets/v1/assets"
OPERATIONS_URL = "https://apis.roblox.com/assets/v1"
MODEL_GROUPS = ("arena", "enemies", "weapons")
ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MANIFEST = ROOT / "assets" / "models" / "manifest.json"
DEFAULT_CACHE = ROOT / "tools" / ".upload_cache.json"
DEFAULT_OUTPUT = ROOT / "game" / "src" / "ReplicatedStorage" / "Shared" / "ModelAssets.luau"


@dataclass(frozen=True)
class ModelEntry:
    key: str
    display_name: str
    fbx_path: Path


def parse_manifest(data: object, model_directory: Path) -> list[ModelEntry]:
    """Validate manifest data and return its uploadable entries in key order."""
    if not isinstance(data, dict):
        raise ValueError("manifest must be a JSON object")

    entries: list[ModelEntry] = []
    for key in sorted(data):
        details = data[key]
        if not isinstance(key, str) or not isinstance(details, dict):
            raise ValueError("manifest entries must map string keys to objects")

        pieces = key.split("/")
        if len(pieces) != 2 or pieces[0] not in MODEL_GROUPS or not pieces[1]:
            raise ValueError(f"unsupported model key: {key!r}")
        if details.get("name") != key:
            raise ValueError(f"manifest entry {key!r} has a mismatched name")

        display_name = details.get("display", pieces[1])
        if not isinstance(display_name, str) or not display_name.strip():
            raise ValueError(f"manifest entry {key!r} has an invalid display name")

        fbx_path = model_directory / pieces[0] / f"{pieces[1]}.fbx"
        if not fbx_path.is_file():
            raise ValueError(f"FBX file is missing for {key!r}: {fbx_path}")
        entries.append(ModelEntry(key, display_name, fbx_path))

    return entries


def load_manifest(path: Path) -> list[ModelEntry]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"could not read model manifest {path}: {error}") from error
    return parse_manifest(data, path.parent)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_cache(path: Path) -> dict[str, dict[str, object]]:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"could not read upload cache {path}: {error}") from error
    if not isinstance(data, dict):
        raise ValueError("upload cache must be a JSON object")
    return {key: value for key, value in data.items() if isinstance(key, str) and isinstance(value, dict)}


def _is_asset_id(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def cache_matches(cache: Mapping[str, Mapping[str, object]], key: str, digest: str) -> bool:
    cached = cache.get(key)
    if cached is None:
        return False
    asset_id = cached.get("assetId")
    return cached.get("sha256") == digest and _is_asset_id(asset_id)


def plan_uploads(
    entries: Sequence[ModelEntry], cache: Mapping[str, Mapping[str, object]]
) -> tuple[list[ModelEntry], dict[str, str]]:
    digests = {entry.key: sha256_file(entry.fbx_path) for entry in entries}
    uploads = [entry for entry in entries if not cache_matches(cache, entry.key, digests[entry.key])]
    return uploads, digests


def asset_ids_from_cache(
    entries: Sequence[ModelEntry], cache: Mapping[str, Mapping[str, object]]
) -> dict[str, int]:
    asset_ids: dict[str, int] = {}
    for entry in entries:
        cached = cache.get(entry.key, {})
        asset_id = cached.get("assetId")
        if _is_asset_id(asset_id):
            assert isinstance(asset_id, int)
            asset_ids[entry.key] = asset_id
    return asset_ids


def _luau_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def render_luau(asset_ids: Mapping[str, int]) -> str:
    """Render a deterministic, StyLua-compatible strict Luau asset map."""
    if not asset_ids:
        return "--!strict\n\nreturn {}\n"

    lines = ["--!strict", "", "return {"]
    for key in sorted(asset_ids):
        asset_id = asset_ids[key]
        if not isinstance(asset_id, int) or isinstance(asset_id, bool) or asset_id <= 0:
            raise ValueError(f"invalid asset ID for {key!r}")
        lines.append(f"\t[{_luau_string(key)}] = {asset_id},")
    lines.append("}")
    return "\n".join(lines) + "\n"


def write_luau(path: Path, asset_ids: Mapping[str, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render_luau(asset_ids), encoding="utf-8", newline="\n")


def save_cache(path: Path, cache: Mapping[str, Mapping[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(cache, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(temporary, path)


class OpenCloudClient:
    def __init__(
        self,
        api_key: str,
        session: Any,
        *,
        sleep: Callable[[float], None] = time.sleep,
        poll_interval: float = 1.0,
        max_polls: int = 300,
    ) -> None:
        self._api_key = api_key
        self._session = session
        self._sleep = sleep
        self._poll_interval = poll_interval
        self._max_polls = max_polls

    def upload(self, entry: ModelEntry, creator_kind: str, creator_id: int) -> int:
        creator = {creator_kind: str(creator_id)}
        request_data = {
            "assetType": "Model",
            "displayName": entry.display_name,
            "description": f"SwarmBreak model {entry.key}",
            "creationContext": {"creator": creator},
        }
        headers = {"x-api-key": self._api_key}
        with entry.fbx_path.open("rb") as model_file:
            response = self._session.post(
                ASSETS_URL,
                headers=headers,
                files={
                    "request": (None, json.dumps(request_data), "application/json"),
                    "fileContent": (entry.fbx_path.name, model_file, "model/fbx"),
                },
                timeout=60,
            )
        response.raise_for_status()
        operation = response.json()
        operation_path = operation.get("path") if isinstance(operation, dict) else None
        if not isinstance(operation_path, str) or not operation_path:
            raise RuntimeError("asset upload response did not include an operation path")

        operation_url = f"{OPERATIONS_URL}/{operation_path.lstrip('/')}"
        for poll_number in range(self._max_polls):
            if poll_number > 0:
                self._sleep(self._poll_interval)
            poll_response = self._session.get(operation_url, headers=headers, timeout=60)
            poll_response.raise_for_status()
            status = poll_response.json()
            if not isinstance(status, dict):
                raise RuntimeError("operation response was not a JSON object")
            if status.get("done") is not True:
                continue
            if "error" in status:
                raise RuntimeError(f"asset upload failed: {status['error']}")
            result = status.get("response")
            asset_id = result.get("assetId") if isinstance(result, dict) else None
            try:
                parsed_asset_id = int(asset_id)
            except (TypeError, ValueError) as error:
                raise RuntimeError("completed upload did not include an asset ID") from error
            if parsed_asset_id <= 0:
                raise RuntimeError("completed upload returned an invalid asset ID")
            return parsed_asset_id

        raise TimeoutError(f"asset upload did not finish after {self._max_polls} polls")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    creator = parser.add_mutually_exclusive_group(required=True)
    creator.add_argument("--user-id", type=int, help="Roblox user ID that will own the assets")
    creator.add_argument("--group-id", type=int, help="Roblox group ID that will own the assets")
    parser.add_argument("--dry-run", action="store_true", help="list uploads without using the network")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST, help=argparse.SUPPRESS)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE, help=argparse.SUPPRESS)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help=argparse.SUPPRESS)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    creator_id = args.user_id if args.user_id is not None else args.group_id
    if creator_id is None or creator_id <= 0:
        raise SystemExit("creator ID must be a positive integer")
    creator_kind = "userId" if args.user_id is not None else "groupId"

    entries = load_manifest(args.manifest)
    cache = load_cache(args.cache)
    uploads, digests = plan_uploads(entries, cache)

    if args.dry_run:
        for entry in uploads:
            print(f"Would upload {entry.key}: {entry.fbx_path}")
        print(f"{len(uploads)} model(s) would upload; {len(entries) - len(uploads)} unchanged")
        return 0

    api_key = os.environ.get("ROBLOX_API_KEY") or getpass.getpass("Roblox Open Cloud API key: ")
    if not api_key:
        raise SystemExit("ROBLOX_API_KEY is required")

    try:
        import requests
    except ImportError as error:
        raise SystemExit("the requests package is required for uploads") from error

    client = OpenCloudClient(api_key, requests.Session())
    for entry in uploads:
        print(f"Uploading {entry.key}...")
        asset_id = client.upload(entry, creator_kind, creator_id)
        cache[entry.key] = {"assetId": asset_id, "sha256": digests[entry.key]}
        save_cache(args.cache, cache)

    write_luau(args.output, asset_ids_from_cache(entries, cache))
    print(f"Wrote {args.output} with {len(entries)} model asset ID(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
