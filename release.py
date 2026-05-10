# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "markdown",
#     "requests",
# ]
# ///

import argparse
import getpass
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
from pathlib import Path

import markdown
import requests


OWNER = "chigkim"
REPO = "VOCR"
ARCHIVES = Path("archives")
DOCS = Path("docs")
GENERATE_APPCAST = Path(
	"~/Library/Developer/Xcode/DerivedData/VOCR-gjsqmtcgzvvuvfcpuxtfgxerxtyc/"
	"SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast"
).expanduser()
TRANSIENT_GITHUB_STATUS_CODES = {403, 404, 409, 422, 429, 500, 502, 503, 504}


def run(cmd):
	print("$", " ".join(shlex.quote(str(part)) for part in cmd))
	subprocess.run(cmd, check=True)


def response_json(response):
	try:
		return response.json()
	except ValueError:
		return response.text


def github_headers(token, content_type="application/json"):
	return {
		"Authorization": f"token {token}",
		"Content-Type": content_type,
	}


def retry_delay(response, attempt):
	retry_after = response.headers.get("Retry-After")
	if retry_after:
		try:
			return max(1, int(retry_after))
		except ValueError:
			pass
	return min(2**attempt, 10)


def github_request(method, url, token, retries=0, retry_statuses=None, **kwargs):
	if retry_statuses is None:
		retry_statuses = set()

	for attempt in range(retries + 1):
		response = requests.request(method, url, headers=github_headers(token), **kwargs)
		if response.ok:
			return response

		if attempt < retries and response.status_code in retry_statuses:
			delay = retry_delay(response, attempt)
			print(
				f"GitHub API {method} {url} failed with {response.status_code}; "
				f"retrying in {delay}s..."
			)
			time.sleep(delay)
			continue

		sys.exit(
			f"GitHub API {method} {url} failed "
			f"({response.status_code} {response.reason}): {response_json(response)}"
		)

	raise RuntimeError("unreachable")


def normalize_tag(tag):
	if not tag:
		return None
	return tag if tag.startswith("v") else f"v{tag}"


def version_from_tag(tag):
	return tag[1:] if tag.startswith("v") else tag


def get_info(file, key):
	plist_xml = file.read_text()
	root = ET.fromstring(plist_xml)
	dict_element = root.find("dict")
	for i, child in enumerate(dict_element):
		if child.tag == "key" and child.text == key:
			return dict_element[i + 1].text
	return None


def find_app():
	apps = sorted(ARCHIVES.glob("*.app"))
	return apps[0] if apps else None


def tag_from_app(app_file):
	info = app_file / "Contents" / "Info.plist"
	short_version = get_info(info, "CFBundleShortVersionString")
	if not short_version:
		sys.exit(f"Error: CFBundleShortVersionString not found in {info}")
	return f"v{short_version}"


def tag_from_zip():
	pattern = re.compile(rf"^{re.escape(REPO)}_(v.+)\.zip$")
	for zip_file in sorted(ARCHIVES.glob("*.zip"), reverse=True):
		match = pattern.match(zip_file.name)
		if match:
			return match.group(1)
	return None


def tag_from_appcast():
	appcast = DOCS / "appcast.xml"
	if not appcast.exists():
		return None
	tree = ET.parse(appcast)
	first_item = tree.find("channel/item")
	if first_item is None:
		return None
	title = first_item.find("title")
	if title is None or not title.text:
		return None
	return normalize_tag(title.text)


def detect_tag(args, app_file=None):
	tag = normalize_tag(args.tag)
	if tag:
		return tag

	if app_file is not None:
		return tag_from_app(app_file)

	return tag_from_appcast() or tag_from_zip()


def read_changelog(args):
	if args.changelog:
		changelog = Path(args.changelog)
	else:
		changelogs = sorted(ARCHIVES.glob("*.md"))
		if not changelogs:
			sys.exit("Error: No changelog .md found in archives/")
		changelog = changelogs[0]

	if not changelog.exists():
		sys.exit(f"Error: Changelog not found: {changelog}")

	return changelog, changelog.read_text()


def get_token(args):
	if args.token:
		return args.token
	token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
	if token:
		return token
	return getpass.getpass("GitHub Token: ")


def release_name(tag):
	return f"{REPO} {tag}"


def is_beta(tag):
	return "beta" in tag


def docs_release_note_path(tag):
	return DOCS / f"{REPO}_{tag}.html"


def archives_release_note_path(tag):
	return ARCHIVES / f"{REPO}_{tag}.html"


def render_release_note(changelog, note):
	md = changelog.read_text()
	html = markdown.markdown(md, extensions=["extra", "codehilite", "toc"])
	note.write_text(html)
	return note


def get_release_by_tag(token, tag):
	url = f"https://api.github.com/repos/{OWNER}/{REPO}/releases/tags/{tag}"
	response = github_request(
		"GET",
		url,
		token,
		retries=3,
		retry_statuses=TRANSIENT_GITHUB_STATUS_CODES,
	)
	return response.json()


def create_github_release(token, tag, release_body):
	url = f"https://api.github.com/repos/{OWNER}/{REPO}/releases"
	data = {
		"tag_name": tag,
		"name": release_name(tag),
		"body": release_body,
		"draft": False,
		"prerelease": is_beta(tag),
	}
	print(json.dumps(data, indent="\t"))
	response = github_request("POST", url, token, json=data)
	print("Release created successfully!")
	return response.json()


def update_github_release(token, tag, release_body):
	release = get_release_by_tag(token, tag)
	url = f"https://api.github.com/repos/{OWNER}/{REPO}/releases/{release['id']}"
	data = {"body": release_body}
	github_request(
		"PATCH",
		url,
		token,
		json=data,
		retries=3,
		retry_statuses=TRANSIENT_GITHUB_STATUS_CODES,
	)
	print("GitHub release notes updated successfully!")
	return release


def upload_release_asset(token, release_info, zip_file):
	asset_name = zip_file.name
	upload_url = release_info["upload_url"].split("{")[0] + "?name=" + asset_name
	headers_asset = github_headers(token, "application/octet-stream")
	data_asset = zip_file.read_bytes()
	response = requests.post(upload_url, headers=headers_asset, data=data_asset)
	if not response.ok:
		sys.exit(f"Failed to upload asset: {response_json(response)}")
	print("Asset uploaded successfully!")
	return response.json()["browser_download_url"]


def merge_appcast(tag, download):
	sparkle_ns = "http://www.andymatuschak.org/xml-namespaces/sparkle"
	ET.register_namespace("sparkle", sparkle_ns)

	new_tree = ET.parse(ARCHIVES / "appcast.xml")
	for item in new_tree.iter("item"):
		title = item.find("title")
		if title is None:
			continue

		if title.text == version_from_tag(tag):
			enclosure = item.find("enclosure")
			if enclosure is not None:
				enclosure.set("url", download)

		if title.text and "beta" in title.text and item.find(f"{{{sparkle_ns}}}channel") is None:
			channel = ET.SubElement(item, f"{{{sparkle_ns}}}channel")
			channel.text = "beta"

	docs_appcast = DOCS / "appcast.xml"
	if docs_appcast.exists():
		existing_tree = ET.parse(docs_appcast)
		existing_channel = existing_tree.find("channel")

		for item in new_tree.find("channel").findall("item"):
			t = item.find("title")
			if t is None:
				continue
			for old_item in existing_channel.findall("item"):
				old_t = old_item.find("title")
				if old_t is not None and old_t.text == t.text:
					existing_channel.remove(old_item)

		for i, item in enumerate(new_tree.find("channel").findall("item")):
			existing_channel.insert(1 + i, item)

		ET.indent(existing_tree, space="    ")
		existing_tree.write(docs_appcast, xml_declaration=True, encoding="unicode")
	else:
		ET.indent(new_tree, space="    ")
		new_tree.write(docs_appcast, xml_declaration=True, encoding="unicode")

	(ARCHIVES / "appcast.xml").unlink()


def commit_docs(tag, no_commit):
	run(["git", "add", "docs/"])
	if no_commit:
		print("Docs changes staged; commit skipped because --no-commit was set.")
		return

	diff = subprocess.run(["git", "diff", "--cached", "--quiet"], check=False)
	if diff.returncode == 0:
		print("No docs changes to commit.")
		return

	run(["git", "commit", "-m", tag])


def create_release(args):
	app_file = find_app()
	if not app_file:
		sys.exit("Error: No .app found in archives/")

	print("App file:", app_file)
	app = app_file.stem
	print("App:", app)

	tag = detect_tag(args, app_file)
	if not tag:
		sys.exit("Error: Could not determine release tag. Pass --tag.")

	print("Tag:", tag)
	print("Beta:", is_beta(tag))
	print("Release:", release_name(tag))

	changelog, release_body = read_changelog(args)
	token = get_token(args)

	zip_file = ARCHIVES / f"{app}_{tag}.zip"
	run(["ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", str(app_file), str(zip_file)])
	shutil.rmtree(app_file)

	release_info = create_github_release(token, tag, release_body)
	note = render_release_note(changelog, archives_release_note_path(tag))
	run([str(GENERATE_APPCAST), str(ARCHIVES)])
	note.rename(docs_release_note_path(tag))

	download = upload_release_asset(token, release_info, zip_file)
	merge_appcast(tag, download)
	commit_docs(tag, args.no_commit)
	print("Done!")


def update_release_notes(args):
	changelog, release_body = read_changelog(args)
	tag = detect_tag(args)
	if not tag:
		sys.exit("Error: Could not determine release tag. Pass --tag.")

	print("Tag:", tag)
	print("Release:", release_name(tag))

	token = get_token(args)
	note = docs_release_note_path(tag)
	with tempfile.TemporaryDirectory() as temp_dir:
		temp_note = Path(temp_dir) / note.name
		render_release_note(changelog, temp_note)
		update_github_release(token, tag, release_body)
		shutil.move(temp_note, note)

	commit_docs(tag, args.no_commit)
	print(f"Docs release notes updated: {note}")
	print("Done!")


def parse_args():
	parser = argparse.ArgumentParser(description="Create or update a VOCR release.")
	parser.add_argument(
		"--update",
		action="store_true",
		help="Update the existing GitHub release notes and docs HTML only.",
	)
	parser.add_argument(
		"--tag",
		help="Release tag to create or update, e.g. v3.0.0-beta.4. The leading v is optional.",
	)
	parser.add_argument(
		"--changelog",
		help="Markdown changelog to publish. Defaults to the first archives/*.md file.",
	)
	parser.add_argument(
		"--token",
		help="GitHub token. Defaults to GITHUB_TOKEN, GH_TOKEN, or an interactive prompt.",
	)
	parser.add_argument(
		"--no-commit",
		action="store_true",
		help="Stage docs changes but do not create the docs commit.",
	)
	return parser.parse_args()


def main():
	args = parse_args()
	if args.update:
		update_release_notes(args)
	else:
		create_release(args)


if __name__ == "__main__":
	main()
