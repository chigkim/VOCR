tag = "v2.0.0-alpha.18"
app = "VOCR"

import os
import codecs

gen = "~/Library/Developer/Xcode/DerivedData/VOCR-golvfhxedvwnjecsjhnzcnbmmchc/SourcePackages/artifacts/sparkle/bin/generate_appcast"
archives = "archives"
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
