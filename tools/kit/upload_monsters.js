// Uploads the monster slimes (tools/blender/monster_rig.py's art/models/monster_slimes/<region>/<Name>/<Name>.fbx and
// its 1024 texture <Name>.png) to the owner's Roblox account through the open Studio, and writes what the game needs into
// art/models/monster_slimes/ids.json: { <Name>: { model, mesh, texture } } (the Model asset, the mesh id inside it, the
// image). The FBX goes up as a Model by Open Cloud (only from art/models, the folder the owner approved), the mesh id is
// read from it with InsertService:LoadAsset, the image goes up by Studio's upload_image from tools/chatgpt/serve.py
// (127.0.0.1:18923 serves the repo). A monster already in ids.json is skipped: take its entry out to upload it again.
//   node tools/kit/upload_monsters.js <studio_id> <region> [<region> ...]
const fs = require("fs");
const path = require("path");
const { open } = require("../studio_mcp_client");

const ROOT = path.resolve(__dirname, "..", "..");
const DIR = path.join(ROOT, "art", "models", "monster_slimes");
const IDS = path.join(DIR, "ids.json");
const OWNER = "2366260872";
const SERVE = "http://127.0.0.1:18923/";

const [studio, ...regions] = process.argv.slice(2);
if (!studio || regions.length === 0) {
	console.error("usage: node tools/kit/upload_monsters.js <studio_id> <region> [<region> ...]");
	process.exit(2);
}

function text(answer) {
	if (answer.error) throw new Error(JSON.stringify(answer.error));
	const parts = (answer.result.content || []).filter((p) => p.type === "text").map((p) => p.text);
	if (answer.result.isError) throw new Error(parts.join("\n"));
	return parts.join("\n");
}

// the JSON body after Open Cloud's status line
function body(reply) {
	const at = reply.indexOf("{");
	if (at < 0 || !/-> 2\d\d/.test(reply)) throw new Error(reply.slice(0, 400));
	return JSON.parse(reply.slice(at));
}

const sleep = (ms) => new Promise((done) => setTimeout(done, ms));

async function uploadModel(client, name, fbx) {
	const request = {
		assetType: "Model",
		displayName: `Goo Lineage monster ${name}`,
		description: `Goo Lineage V2 monster slime ${name}, rigged`,
		creationContext: { creator: { userId: OWNER } },
	};
	const started = body(
		text(
			await client.call("open_cloud_invoke", {
				studio_id: studio,
				method: "POST",
				endpoint: "/assets/v1/assets",
				body: JSON.stringify({ request }),
				files: [{ name: "fileContent", path: fbx }],
				scopes: ["asset:read", "asset:write"],
			}),
		),
	);
	for (let tries = 0; tries < 40; tries++) {
		await sleep(3000);
		const op = body(
			text(
				await client.call("open_cloud_invoke", {
					studio_id: studio,
					method: "GET",
					endpoint: `/assets/v1/operations/${started.operationId}`,
					scopes: ["asset:read"],
				}),
			),
		);
		if (op.done) {
			if (!op.response || !op.response.assetId) throw new Error(JSON.stringify(op));
			return op.response.assetId;
		}
	}
	throw new Error(`${name}: the upload did not finish`);
}

async function meshOf(client, model) {
	const code = `local m = game:GetService("InsertService"):LoadAsset(${model})
local part = m:FindFirstChildWhichIsA("MeshPart", true)
local bones = 0
for _, d in m:GetDescendants() do if d:IsA("Bone") then bones += 1 end end
local out = if part then string.match(part.MeshId, "%d+") .. " " .. tostring(part.Size) .. " " .. tostring(part.HasSkinnedMesh) .. " " .. bones else "none"
m:Destroy()
return out`;
	const reply = text(await client.call("execute_luau", { studio_id: studio, datamodel_type: "Edit", code }));
	const words = reply.trim().split(/\s+/);
	if (words[0] === "none") throw new Error(`model ${model} has no MeshPart`);
	return { mesh: words[0], note: words.slice(1).join(" ") };
}

async function uploadImage(client, rel) {
	const url = SERVE + rel.split(path.sep).join("/");
	const reply = text(await client.call("upload_image", { studio_id: studio, imagePaths: [url] }));
	const match = reply.match(/rbxassetid:\/\/(\d+)/);
	if (!match) throw new Error(`${rel}: ${reply.slice(0, 400)}`);
	return match[1];
}

async function main(client) {
	const ids = fs.existsSync(IDS) ? JSON.parse(fs.readFileSync(IDS, "utf8")) : {};
	for (const region of regions) {
		const rig = JSON.parse(fs.readFileSync(path.join(DIR, region, `rig_${region}.json`), "utf8"));
		for (const name of Object.keys(rig)) {
			if (ids[name] && ids[name].mesh && ids[name].texture) {
				console.log(`SKIP ${name} (in ids.json)`);
				continue;
			}
			const fbx = path.join(DIR, region, name, `${name}.fbx`);
			const png = path.join(DIR, region, name, `${name}.png`);
			if (!fs.existsSync(fbx) || !fs.existsSync(png)) throw new Error(`${name}: no ${fbx} or ${png}`);
			const model = await uploadModel(client, name, fbx);
			const { mesh, note } = await meshOf(client, model);
			const texture = await uploadImage(client, path.relative(ROOT, png));
			ids[name] = { model: Number(model), mesh: Number(mesh), texture: Number(texture) };
			fs.writeFileSync(IDS, JSON.stringify(ids, null, "\t") + "\n");
			console.log(`DONE ${name} model ${model} mesh ${mesh} texture ${texture} (size, skinned, bones: ${note})`);
		}
	}
}

let client;
open()
	.then((c) => {
		client = c;
		return main(c);
	})
	.catch((e) => {
		console.error("FAILED " + e.message);
		process.exitCode = 1;
	})
	.finally(() => {
		if (client) client.close();
		setTimeout(() => process.exit(), 400);
	});
