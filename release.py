import requests
import shlex
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
import json
import shutil

def run(cmd):
	subprocess.run(shlex.split(cmd), check=True)

token = input("Github Token:")
owner = 'chigkim'
repo = "VOCR"
archives = Path("archives")
docs = Path("docs")
gen = Path("~/Library/Developer/Xcode/DerivedData/VOCR-gjsqmtcgzvvuvfcpuxtfgxerxtyc/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast").expanduser()

def getInfo(file, key):
	plist_xml = file.read_text()
	root = ET.fromstring(plist_xml)
	dict_element = root.find('dict')
	for i, child in enumerate(dict_element):
		if child.tag == 'key' and child.text == key:
			return dict_element[i+1].text

apps = list(archives.glob("*.app"))
if not apps:
	sys.exit("Error: No .app found in archives/")
app_file = apps[0]
print("App file:", app_file)
app = app_file.stem
print("App:", app)
info = app_file / "Contents" / "Info.plist"
tag = "v"+getInfo(info, "CFBundleShortVersionString")
is_beta = "beta" in tag
print("Tag:", tag)
print("Beta:", is_beta)
release_name = f"{repo} {tag}"
print("Release:", release_name)
zip_file = archives / f"{app}_{tag}.zip"
run(f"ditto -c -k --sequesterRsrc --keepParent '{app_file}' '{zip_file}'")
shutil.rmtree(app_file)

changelogs = list(archives.glob("*.md"))
if not changelogs:
	sys.exit("Error: No changelog .md found in archives/")
changelog = changelogs[0]
release_body = changelog.read_text()
asset_name = zip_file.name
url_create_release = f'https://api.github.com/repos/{owner}/{repo}/releases'
headers = {
	'Authorization': f'token {token}',
	'Content-Type': 'application/json'
}
data_release = {
	'tag_name': tag,
	'name': release_name,
	'body': release_body,
	'draft': False,
	'prerelease': is_beta
}
print(json.dumps(data_release, indent="\t"))

response_release = requests.post(url_create_release, json=data_release, headers=headers)
if not response_release.ok:
	sys.exit(f"Failed to create release: {response_release.json()}")
print('Release created successfully!')

note = zip_file.with_suffix(".html")
print(note)
run(f"pandoc -s '{changelog}' -o '{note}'")
run(f"'{gen}' '{archives}'")
note.rename(docs / note.name)

release_info = response_release.json()
upload_url = release_info['upload_url'].split('{')[0] + '?name=' + asset_name
headers_asset = {
	'Authorization': f'token {token}',
	'Content-Type': 'application/octet-stream'
}
data_asset = zip_file.read_bytes()
response_asset = requests.post(upload_url, headers=headers_asset, data=data_asset)
if not response_asset.ok:
	sys.exit(f"Failed to upload asset: {response_asset.json()}")
print('Asset uploaded successfully!')

download = response_asset.json()['browser_download_url']
sparkle_ns = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
ET.register_namespace('sparkle', sparkle_ns)
new_tree = ET.parse(archives / "appcast.xml")
for item in new_tree.iter('item'):
	title = item.find('title')
	if title is not None:
		if title.text == tag[1:]:
			enclosure = item.find('enclosure')
			if enclosure is not None:
				enclosure.set('url', download)
		if 'beta' in title.text and item.find(f'{{{sparkle_ns}}}channel') is None:
			channel = ET.SubElement(item, f'{{{sparkle_ns}}}channel')
			channel.text = 'beta'

docs_appcast = docs / "appcast.xml"
if docs_appcast.exists():
	existing_tree = ET.parse(docs_appcast)
	existing_channel = existing_tree.find('channel')
	# Remove existing items with the same version to avoid duplicates
	for item in new_tree.find('channel').findall('item'):
		t = item.find('title')
		if t is not None:
			for old_item in existing_channel.findall('item'):
				old_t = old_item.find('title')
				if old_t is not None and old_t.text == t.text:
					existing_channel.remove(old_item)
	# Insert new items at the top (after <title>)
	for i, item in enumerate(new_tree.find('channel').findall('item')):
		existing_channel.insert(1 + i, item)
	ET.indent(existing_tree, space="    ")
	existing_tree.write(docs_appcast, xml_declaration=True, encoding='unicode')
else:
	ET.indent(new_tree, space="    ")
	new_tree.write(docs_appcast, xml_declaration=True, encoding='unicode')
(archives / "appcast.xml").unlink()
run("git add docs/")
run(f"git commit -a -m {tag}")
print("Done!")
