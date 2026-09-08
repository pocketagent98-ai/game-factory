#!/usr/bin/env python3
"""Godot Version Detector — Finds latest stable and handles upgrades.

For new games: scans Godot releases, pins latest stable.
For updates: reads original project.godot, detects version, checks safe upgrade path.
"""
import json
import os
import re
import requests
import argparse
from datetime import datetime


class GodotVersionDetector:
    """Detects and manages Godot engine versions."""
    
    GITHUB_API = "https://api.github.com/repos/godotengine/godot/releases"
    
    SAFE_UPGRADES = {
        "4.5": "4.7.2", "4.5.1": "4.7.2", "4.6": "4.7.2",
        "4.6.1": "4.7.2", "4.7": "4.7.2", "4.7.1": "4.7.2",
        "3.6": "3.6.3", "3.6.1": "3.6.3", "3.6.2": "3.6.3",
    }
    
    DANGEROUS_UPGRADES = [("3.", "4.")]

    def get_latest_stable(self):
        """Get the latest stable Godot version from GitHub releases."""
        try:
            resp = requests.get(f"{self.GITHUB_API}?per_page=20", timeout=30)
            resp.raise_for_status()
            releases = resp.json()
            
            for release in releases:
                tag = release.get("tag_name", "")
                if release.get("prerelease"):
                    continue
                if any(x in tag for x in ["-dev", "-rc", "-beta", "-alpha", "-pre"]):
                    continue
                version = tag.lstrip("v")
                print(f"[GODOT] Latest stable: {version}")
                return version
            
            print("[GODOT] Could not find stable release, using 4.7.2")
            return "4.7.2"
        except Exception as e:
            print(f"[GODOT] Error fetching releases: {e}, using 4.7.2")
            return "4.7.2"

    def detect_from_project(self, project_godot_path):
        """Detect Godot version from an existing project.godot file."""
        if not os.path.exists(project_godot_path):
            print(f"[GODOT] project.godot not found at {project_godot_path}")
            return None
        with open(project_godot_path, 'r') as f:
            content = f.read()
        match = re.search(r'config_version=(\d+)', content)
        if match:
            config_ver = int(match.group(1))
            if config_ver >= 5:
                return "4.x"
            elif config_ver >= 4:
                return "3.x"
        return "unknown"

    def check_upgrade_safety(self, old_version, new_version):
        """Check if upgrading from old_version to new_version is safe."""
        for old_prefix, new_prefix in self.DANGEROUS_UPGRADES:
            if old_version.startswith(old_prefix) and new_version.startswith(new_prefix):
                return {"safe": False,
                    "reason": f"Major version jump from {old_version} to {new_version} is dangerous.",
                    "recommendation": f"Stay on {old_version} or use {self.SAFE_UPGRADES.get(old_version, old_version)}"}
        
        old_major = old_version.split(".")[0]
        new_major = new_version.split(".")[0]
        if old_major == new_major:
            return {"safe": True, "reason": f"Minor upgrade within {old_major}.x is safe.",
                    "recommendation": f"Upgrade to {new_version}"}
        return {"safe": False, "reason": "Unknown upgrade path.",
                "recommendation": "Test thoroughly before upgrading."}

    def get_download_url(self, version, platform="linux"):
        platform_map = {"linux": "linux.x86_64", "windows": "win64.exe", "macos": "macos.universal"}
        suffix = platform_map.get(platform, "linux.x86_64")
        return f"https://github.com/godotengine/godot/releases/download/{version}-stable/Godot_v{version}-stable_{suffix}.zip"


def main():
    parser = argparse.ArgumentParser(description="Godot Version Detector")
    parser.add_argument("--bible", help="Path to game bible YAML")
    parser.add_argument("--check-upgrade", nargs=2, metavar=("OLD", "NEW"))
    args = parser.parse_args()
    
    detector = GodotVersionDetector()
    if args.check_upgrade:
        old, new = args.check_upgrade
        result = detector.check_upgrade_safety(old, new)
        print(json.dumps(result, indent=2))
    else:
        version = detector.get_latest_stable()
        print(f"Latest stable Godot version: {version}")
        print(f"Download URL: {detector.get_download_url(version)}")


if __name__ == "__main__":
    main()
