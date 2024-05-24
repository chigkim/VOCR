token = input("Github Token:")
owner = 'chigkim'
repo = "VOCR"
archives = "archives"
gen = "~/Library/Developer/Xcode/DerivedData/VOCR-golvfhxedvwnjecsjhnzcnbmmchc/SourcePackages/artifacts/sparkle/bin/generate_appcast"

import requests
import os
import codecs
import xml.etree.ElementTree as ET
from glob import glob
import json
import re
import shutil

def getInfo(file, key):
	plist_xml = open(file).read()
	root = ET.fromstring(plist_xml)
	dict_element = root.find('dict')
	for i, child in enumerate(dict_element):
		if child.tag == 'key' and child.text == key:
			return dict_element[i+1].text


app_file = glob(f"{archives}/*.app")[0]
print("App file:", app_file)
app = app_file[app_file.rindex("/")+1:app_file.rindex(".app")]
print("App:", app)
info = app_file+"/Contents/Info.plist"
tag = "v"+getInfo(info, "CFBundleShortVersionString")
print("Tag:", tag)
release_name = f"{repo} {tag}"
print("Release:", release_name)
zip = f"{archives}/{app}_{tag}.zip"
cmd = f"ditto -c -k --sequesterRsrc --keepParent {app_file} {zip}"
os.system(cmd)
shutil.rmtree(app_file)
changelog = glob(f"{archives}/*.md")[0]
release_body = open(changelog).read()
file_path = zip
asset_name = os.path.basename(file_path)  # Gets the file name from the path
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
	'prerelease': False
}
print(json.dumps(data_release, indent="\t"))
response_release = requests.post(url_create_release, json=data_release, headers=headers)
if response_release.status_code == 201:
	print('Release created successfully!')
	note = zip.replace(".zip", ".html")
	print(note)
	cmd = f"pandoc -s '{changelog}' -o '{note}'"
	os.system(cmd)
	cmd = f"{gen} {archives}"
	os.system(cmd)
	[os.remove("docs/"+file) for file in os.listdir("docs") if ".html" in file]
	os.rename(note, note.replace(archives, "docs"))
	release_info = response_release.json()
	upload_url = release_info['upload_url'].split('{')[0] + '?name=' + asset_name
	headers_asset = {
		'Authorization': f'token {token}',
		'Content-Type': 'application/octet-stream'
	}
	with open(file_path, 'rb') as file:
		data_asset = file.read()
	response_asset = requests.post(upload_url, headers=headers_asset, data=data_asset)
	if response_asset.status_code == 201:
		print('Asset uploaded successfully!')
		download = response_asset.json()['browser_download_url']
		xml = codecs.open(f"{archives}/appcast.xml", "r", "utf-8").read()
		search = re.search(r'url="(.*?)"', xml)[1]
		xml = xml.replace(search, download)
		with codecs.open("docs/appcast.xml", "w", "utf-8") as file:
			file.write(xml)
		os.remove(f"{archives}/appcast.xml")
		cmd = "git add docs/*"
		os.system(cmd)
		cmd = f"git commit -a -m {tag}"
		os.system(cmd)
	else:
		print('Failed to upload asset:', response_asset.json())
else:
	print('Failed to create release:', response_release.json())
