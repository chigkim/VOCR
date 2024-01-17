app = "VOCR"

import os
import codecs
import xml.etree.ElementTree as ET

def getVersion(file):
	plist_xml = open(file).read()
	root = ET.fromstring(plist_xml)
	dict_element = root.find('dict')
	for i, child in enumerate(dict_element):
		if child.tag == 'key' and child.text == 'CFBundleShortVersionString':
			version_string_element = dict_element[i+1]
			return version_string_element.text
gen = "~/Library/Developer/Xcode/DerivedData/VOCR-golvfhxedvwnjecsjhnzcnbmmchc/SourcePackages/artifacts/sparkle/bin/generate_appcast"
archives = "archives"
tag = getVersion(f"{archives}/{app}.app/Contents/Info.plist")
print(tag)
zip = f"{archives}/{app}_{tag}.zip"
cmd = f"ditto -c -k --sequesterRsrc --keepParent {archives}/{app}.app {zip}"
os.system(cmd)

release = f"https://github.com/chigkim/VOCR/releases/download/{tag}/"
print(release)
notes = f"{app}_{tag}.html"
print(notes)
os.system(f"pandoc -s {archives}/changelog.md -o '{archives}/{notes}'")
os.system(f"{gen} {archives}")
xml = codecs.open(f"{archives}/appcast.xml", "r", "utf-8").read()
xml = xml.replace('url="https://chigkim.github.io/VOCR/', 'url="'+release)
file = codecs.open("docs/appcast.xml", "w", "utf-8")
file.write(xml)
file.close()
os.rename(f"{archives}/{notes}", f"docs/{notes}")
os.remove(f"{archives}/appcast.xml")
