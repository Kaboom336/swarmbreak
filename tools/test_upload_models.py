#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock

import upload_models


class ManifestTests(unittest.TestCase):
    def test_parses_supported_entries_in_sorted_order(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            model_directory = Path(directory)
            for relative_path in ("weapons/Starter.fbx", "enemies/Walker.fbx"):
                path = model_directory / relative_path
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"model")

            entries = upload_models.parse_manifest(
                {
                    "weapons/Starter": {
                        "name": "weapons/Starter",
                        "display": "Starter Pistol",
                    },
                    "enemies/Walker": {"name": "enemies/Walker"},
                },
                model_directory,
            )

            self.assertEqual([entry.key for entry in entries], ["enemies/Walker", "weapons/Starter"])
            self.assertEqual(entries[0].display_name, "Walker")
            self.assertEqual(entries[1].display_name, "Starter Pistol")

    def test_rejects_unknown_groups(self) -> None:
        with self.assertRaisesRegex(ValueError, "unsupported model key"):
            upload_models.parse_manifest(
                {"pets/Friendly": {"name": "pets/Friendly"}}, Path("models")
            )


class CacheTests(unittest.TestCase):
    def test_skips_unchanged_file_with_an_asset_id(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            model_path = Path(directory) / "Walker.fbx"
            contents = b"an fbx model"
            model_path.write_bytes(contents)
            entry = upload_models.ModelEntry("enemies/Walker", "Walker", model_path)
            digest = hashlib.sha256(contents).hexdigest()

            uploads, digests = upload_models.plan_uploads(
                [entry], {entry.key: {"sha256": digest, "assetId": 123}}
            )

            self.assertEqual(uploads, [])
            self.assertEqual(digests, {entry.key: digest})

    def test_uploads_when_cached_asset_id_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            model_path = Path(directory) / "Walker.fbx"
            model_path.write_bytes(b"an fbx model")
            entry = upload_models.ModelEntry("enemies/Walker", "Walker", model_path)
            digest = upload_models.sha256_file(model_path)

            uploads, _ = upload_models.plan_uploads([entry], {entry.key: {"sha256": digest}})

            self.assertEqual(uploads, [entry])


class LuauWriterTests(unittest.TestCase):
    def test_writes_sorted_strict_luau(self) -> None:
        rendered = upload_models.render_luau(
            {"weapons/Starter": 456, "enemies/Walker": 123}
        )

        self.assertEqual(
            rendered,
            "--!strict\n\nreturn {\n"
            '\t["enemies/Walker"] = 123,\n'
            '\t["weapons/Starter"] = 456,\n'
            "}\n",
        )

    def test_writes_empty_map(self) -> None:
        self.assertEqual(upload_models.render_luau({}), "--!strict\n\nreturn {}\n")


class FakeResponse:
    def __init__(self, payload: object) -> None:
        self.payload = payload
        self.raise_for_status = Mock()

    def json(self) -> object:
        return self.payload


class OpenCloudClientTests(unittest.TestCase):
    def test_upload_posts_multipart_and_polls_with_mocked_http(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            model_path = Path(directory) / "Walker.fbx"
            model_path.write_bytes(b"model contents")
            session = Mock()
            session.post.return_value = FakeResponse({"path": "operations/upload-1"})
            session.get.side_effect = [
                FakeResponse({"done": False}),
                FakeResponse({"done": True, "response": {"assetId": "987654"}}),
            ]
            sleep = Mock()
            client = upload_models.OpenCloudClient(
                "secret-for-test", session, sleep=sleep, poll_interval=0
            )

            asset_id = client.upload(
                upload_models.ModelEntry("enemies/Walker", "Walker", model_path),
                "groupId",
                42,
            )

            self.assertEqual(asset_id, 987654)
            post = session.post.call_args
            self.assertEqual(post.args[0], upload_models.ASSETS_URL)
            self.assertEqual(post.kwargs["headers"], {"x-api-key": "secret-for-test"})
            request_part = post.kwargs["files"]["request"]
            request_data = json.loads(request_part[1])
            self.assertEqual(request_data["assetType"], "Model")
            self.assertEqual(request_data["creationContext"], {"creator": {"groupId": "42"}})
            self.assertEqual(post.kwargs["files"]["fileContent"][0], "Walker.fbx")
            self.assertEqual(session.get.call_count, 2)
            session.get.assert_called_with(
                "https://apis.roblox.com/assets/v1/operations/upload-1",
                headers={"x-api-key": "secret-for-test"},
                timeout=60,
            )

    def test_upload_surfaces_mocked_operation_error(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            model_path = Path(directory) / "Walker.fbx"
            model_path.write_bytes(b"model contents")
            session = Mock()
            session.post.return_value = FakeResponse({"path": "operations/upload-2"})
            session.get.return_value = FakeResponse(
                {"done": True, "error": {"message": "rejected"}}
            )
            client = upload_models.OpenCloudClient(
                "secret-for-test", session, sleep=lambda _: None, poll_interval=0
            )

            with self.assertRaisesRegex(RuntimeError, "asset upload failed"):
                client.upload(
                    upload_models.ModelEntry("enemies/Walker", "Walker", model_path),
                    "userId",
                    7,
                )


if __name__ == "__main__":
    unittest.main()
