# Samples every monster slime's five actions (tools/blender/monster_rig.py baked them into <region>_rigged.blend, one
# action <Name>_<Action> a take) into the game's data, src/shared/MonsterClips/<Name>.luau, at every baked frame (30 a
# second): for every bone but the Root (it never moves) its move from its rest in the model's Roblox axes ((X, Y, Z) =
# (-x, z, y) of Blender's), a position in studs at the built size and a turn as axis times angle (radians). Each channel
# is stored as 12-bit steps between its own lowest value and that plus its span, two characters of the base-64 alphabet a
# sample; a channel that never changes is its value alone. With them the mesh's middle and every bone's rest point, so
# the game makes the bones by name under the mesh it loads (client/ClipRig). Shared/MonsterClip reads them.
# Run: tools/blender/monster_clips.ps1 <region>
import bpy, json, math, os, sys

ARGS = sys.argv[sys.argv.index("--") + 1 :]
REGION = ARGS[0]
DIR = "C:/Roblox 3rd game/art/models/monster_slimes/" + REGION
OUT = "C:/Roblox 3rd game/src/shared/MonsterClips"
ACTIONS = ("Idle", "Move", "Attack", "Hit", "Die")
ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
STEPS = 4095
STILL = 1e-5  # a channel that moves less than this is a constant


def rb(v):
	return (-v[0], v[2], v[1])


def rotvec(q):
	"""A unit quaternion as axis times angle (the shorter way round)."""
	if q.w < 0:
		q = -q
	s = math.sqrt(max(0.0, 1 - q.w * q.w))
	angle = 2 * math.acos(min(1.0, q.w))
	if s < 1e-9:
		return (0.0, 0.0, 0.0)
	return (q.x / s * angle, q.y / s * angle, q.z / s * angle)


def num(x):
	text = f"{x:.5f}".rstrip("0").rstrip(".")
	return "0" if text in ("-0", "") else text


bpy.ops.wm.open_mainfile(filepath=f"{DIR}/{REGION}_rigged.blend")
with open(f"{DIR}/rig_{REGION}.json") as f:
	info = json.load(f)
scene = bpy.context.scene
os.makedirs(OUT, exist_ok=True)
for name, spec in info.items():
	rig = bpy.data.objects[name + "Rig"]
	ob = bpy.data.objects[name]
	cos = [v.co for v in ob.data.vertices]
	lo = [min(c[i] for c in cos) for i in range(3)]
	hi = [max(c[i] for c in cos) for i in range(3)]
	height = hi[2] - lo[2]
	centre = rb([(a + b) / 2 for a, b in zip(lo, hi)])
	bones = [b.name for b in rig.data.bones if b.name != "Root"]
	# (every bone points up with no roll, so Roblox's import gives each the part's own axes: X = -Blender's bone X,
	# Y = its Y, both mapped; checked here so the game can make the bones unturned)
	for b in rig.data.bones:
		m = b.matrix_local
		x, y = rb(-m.col[0].xyz), rb(m.col[1].xyz)
		if abs(x[0] - 1) > 1e-4 or abs(y[1] - 1) > 1e-4:
			print(f"WARN {name}.{b.name}: its rest is turned ({x}, {y}); the game makes it unturned")
	if "peak" not in spec:
		print(f"WARN {name}: no attack peak in rig_{REGION}.json, 0.5 s taken")
	ad = rig.animation_data or rig.animation_data_create()
	for tr in ad.nla_tracks:
		tr.mute = True
	lines = [
		f"-- {name}'s five actions, sampled by tools/blender/monster_clips.py from",
		f"-- art/models/monster_slimes/{REGION}/{REGION}_rigged.blend (generated: change the motion there and sample again).",
		"return {",
		f"\theight = {num(height)},",
		f"\thover = {num(spec['hover'])},",
		f"\tpeak = {num(spec.get('peak', 0.5))},",
		"\t-- the mesh's middle and every bone's rest point (parents first: name, parent, x, y, z), in built studs",
		"\tcentre = { " + ", ".join(num(x) for x in centre) + " },",
		"\trest = {",
	]
	for b in rig.data.bones:
		at = rb(b.head_local)
		parent = b.parent.name if b.parent else ""
		lines.append(f'\t\t{{ "{b.name}", "{parent}", ' + ", ".join(num(x) for x in at) + " },")
	lines += [
		"\t},",
		"\tbones = { " + ", ".join(f'"{b}"' for b in bones) + " },",
		"\tactions = {",
	]
	worst = 0.0
	for an in ACTIONS:
		act = bpy.data.actions[f"{name}_{an}"]
		ad.action = act
		if hasattr(ad, "action_slot") and len(act.slots):
			ad.action_slot = act.slots[0]
		length, loop = spec["actions"][an]
		frames = int(round(length * 30)) + 1
		chans = [[] for _ in range(6 * len(bones))]
		for fr in range(frames):
			scene.frame_set(fr)
			for k, bn in enumerate(bones):
				pb = rig.pose.bones[bn]
				Q = rig.data.bones[bn].matrix_local.to_3x3()
				loc = Q @ pb.location
				turn = (Q @ pb.rotation_quaternion.normalized().to_matrix() @ Q.inverted()).to_quaternion()
				for c, x in enumerate(rb(loc) + rb(rotvec(turn))):
					chans[6 * k + c].append(x)
		ranges, data = [], []
		for ch in chans:
			lo, hi = min(ch), max(ch)
			if hi - lo < STILL:
				ranges += [num((lo + hi) / 2), "0"]
				continue
			span = hi - lo
			ranges += [num(lo), num(span)]
			for x in ch:
				code = round((x - lo) / span * STEPS)
				worst = max(worst, abs(lo + span * code / STEPS - x))
				data.append(ALPHABET[code // 64] + ALPHABET[code % 64])
		lines += [
			f"\t\t{an} = {{",
			f"\t\t\tlength = {num(length)},",
			f"\t\t\tloop = {'true' if loop else 'false'},",
			f"\t\t\tframes = {frames},",
			"\t\t\tranges = { " + ", ".join(ranges) + " },",
			f'\t\t\tdata = "{"".join(data)}",',
			"\t\t},",
		]
		print(f"ACTION {name}_{an} {frames} frames {sum(1 for r in ranges[1::2] if r != '0')} moving channels of {len(chans)}")
	lines += ["\t},", "}", ""]
	path = f"{OUT}/{name}.luau"
	with open(path, "w", newline="\n") as f:
		f.write("\n".join(lines))
	print(f"CLIPS {name} height {height:.2f} bones {len(bones)} worst step {worst:.5f} {os.path.getsize(path) // 1024} KB")
print("DONE")
