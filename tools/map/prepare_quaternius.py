# Makes phone-sized .glb files from Quaternius' Stylized Nature MegaKit (CC0), for File > Import 3D in Studio.
# blender -b --factory-startup -P tools/map/prepare_quaternius.py -- <the pack's glTF folder> <output folder>
import bmesh
import bpy
import math
import os
import random
import sys

# name: triangles wanted, whole model (leaf cards are thinned and grown, solid parts collapsed)
MODELS = {
	"Rock_Medium_1": 342,
	"Rock_Medium_2": 244,
	"Rock_Medium_3": 522,
	"Pebble_Round_1": 136,
	"Pebble_Square_2": 78,
	"RockPath_Round_Small_1": 300,
	"Fern_1": 288,
	"Plant_1_Big": 360,
	"Plant_7_Big": 112,
	"Clover_1": 200,
	"Grass_Common_Short": 155,
	"Grass_Common_Tall": 200,
	"Grass_Wispy_Short": 180,
	"Flower_3_Group": 350,
	"Flower_4_Group": 450,
	"Bush_Common": 400,
	"Bush_Common_Flowers": 500,
	"Mushroom_Common": 250,
	"Mushroom_Laetiporus": 450,
	"DeadTree_1": 1500,
	"DeadTree_3": 1500,
	"DeadTree_5": 1500,
	"TwistedTree_1": 2500,
	"TwistedTree_2": 2500,
	"TwistedTree_3": 2500,
	"CommonTree_1": 2000,
	"CommonTree_3": 2000,
	"CommonTree_5": 2000,
	"Pine_1": 1800,
	"Pine_5": 1646,
}
LEAF_SHARE = 0.7  # of a tree's or bush's triangles
TEXTURE_SIZE = 512
THINNED = ("Tree", "Pine", "Bush")

args = sys.argv[sys.argv.index("--") + 1 :]
source, output = args[0], args[1]
os.makedirs(output, exist_ok=True)


def triangles(ob):
	ob.data.calc_loop_triangles()
	return len(ob.data.loop_triangles)


def thin_cards(ob, keep_triangles):
	# Leaf cards are loose islands: drop some at random and grow the rest, so the crown keeps its volume.
	bm = bmesh.new()
	bm.from_mesh(ob.data)
	bm.verts.ensure_lookup_table()
	seen, islands = set(), []
	for vert in bm.verts:
		if vert in seen:
			continue
		stack, island = [vert], []
		seen.add(vert)
		while stack:
			v = stack.pop()
			island.append(v)
			for edge in v.link_edges:
				other = edge.other_vert(v)
				if other not in seen:
					seen.add(other)
					stack.append(other)
		islands.append(island)
	total = sum(len(f.verts) - 2 for f in bm.faces)
	keep = min(1, keep_triangles / max(total, 1))
	if keep < 1:
		rng = random.Random(7)
		grow = math.sqrt(1 / keep)
		for island in islands:
			if rng.random() > keep:
				bmesh.ops.delete(bm, geom=island, context="VERTS")
			else:
				centre = sum((v.co for v in island), island[0].co * 0) / len(island)
				for v in island:
					v.co = centre + (v.co - centre) * grow
	bm.to_mesh(ob.data)
	bm.free()
	return len(islands)


def collapse(ob, wanted):
	have = triangles(ob)
	if have <= wanted:
		return
	mod = ob.modifiers.new("d", "DECIMATE")
	mod.ratio = wanted / have
	bpy.context.view_layer.objects.active = ob
	bpy.ops.object.modifier_apply(modifier=mod.name)


for name, wanted in MODELS.items():
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=os.path.join(source, name + ".gltf"))
	for ob in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
		bpy.ops.object.select_all(action="DESELECT")
		ob.select_set(True)
		bpy.context.view_layer.objects.active = ob
		if len(ob.data.materials) > 1:
			bpy.ops.mesh.separate(type="MATERIAL")
	parts = [o for o in bpy.context.scene.objects if o.type == "MESH"]
	before = sum(triangles(o) for o in parts)
	cards = [o for o in parts if o.data.materials and "Leaves" in o.data.materials[0].name] if any(t in name for t in THINNED) else []
	solid = [o for o in parts if o not in cards]
	for ob in cards:
		thin_cards(ob, wanted * LEAF_SHARE / len(cards))
	solidBudget = wanted - sum(triangles(o) for o in cards)
	solidHave = sum(triangles(o) for o in solid)
	for ob in solid:
		collapse(ob, max(40, int(triangles(ob) * min(1, solidBudget / max(solidHave, 1)))))
	for image in bpy.data.images:
		if image.size[0] > TEXTURE_SIZE:
			image.scale(TEXTURE_SIZE, TEXTURE_SIZE)
			image.pack()
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.export_scene.gltf(
		filepath=os.path.join(output, name + ".glb"),
		export_format="GLB",
		export_animations=False,
	)
	after = sum(triangles(o) for o in [o for o in bpy.context.scene.objects if o.type == "MESH"])
	print(f"[qt] {name}: {before} -> {after} triangles, {len(cards)} card parts")
