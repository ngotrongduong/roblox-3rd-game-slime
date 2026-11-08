# Goo Lineage V2 - which skin file belongs to which Secret recipe, matched by NAME: the original art's file pairs do
# not always match the recipe's colours (the file white-yellow is the Sakura Bunny, recipe white + pink).
#   python tools/skins/map_secret_skins.py [upload result.json ...]
# Reads src/shared/SecretRecipes.luau and art/turnaround/batch_*.json; writes art/models/slime_body/skins/
# secret_map.json ({recipe id: file pair}). Upload results (Studio upload_image's {url: "rbxassetid://id"}) are merged
# into skins/asset_ids.json as "s_<file pair>"; then the Luau rows for SkinIds.Secrets are printed.
import json
import re
import sys

ROOT = "C:/Roblox 3rd game/"
SKINS = ROOT + "art/models/slime_body/skins/"


def key(name):
	return re.sub(r"[^a-z]", "", name.lower().replace("slime", ""))


source = open(ROOT + "src/shared/SecretRecipes.luau", encoding="utf-8").read()
recipes = {}
for a, b, name in re.findall(r'\{\s*"(\w+)",\s*"(\w+)",\s*"([^"]+)"', source):
	recipes[key(name)] = "secret-" + "-".join(sorted((a, b)))
files = {}
for batch in ("batch_wingless.json", "batch_winged.json"):
	for s in json.load(open(ROOT + "art/turnaround/" + batch, encoding="utf-8")):
		files[key(s["name"])] = s["subject"].replace("secret-", "")
out = {}
for name, pair in files.items():
	if name not in recipes:
		sys.exit("[GooLineage] no recipe named like " + name)
	out[recipes[name]] = pair
json.dump(dict(sorted(out.items())), open(SKINS + "secret_map.json", "w", encoding="utf-8"), indent="\t")
print("[GooLineage] %d of %d recipes have a skin; moved: %s" % (
	len(out), len(recipes), ", ".join("%s<-%s" % (r, p) for r, p in sorted(out.items()) if r != "secret-" + p)))
ids = json.load(open(SKINS + "asset_ids.json", encoding="utf-8"))
for upload in sys.argv[1:]:
	for url, asset in json.load(open(upload, encoding="utf-8")).items():
		ids[url.rsplit("/", 1)[1].replace(".png", "")] = int(asset.replace("rbxassetid://", ""))
if len(sys.argv) > 1:
	json.dump(ids, open(SKINS + "asset_ids.json", "w", encoding="utf-8"), indent="\t")
for recipe, pair in sorted(out.items()):
	if "s_" + pair in ids:
		print('\t["%s"] = %s,' % (recipe, ids["s_" + pair]))
