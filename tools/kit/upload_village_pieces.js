// Uploads the village landmarks' models (the owner's Meshy sheets cut into pieces, art/models/**/meshy/**/<key>_pieces.glb,
// and Claude's Blender pieces, art/models/granary/blender/<Piece>.fbx) to the owner's Roblox account and writes their ids
// into the game: every object of a file is a kit prop of the same name (`mesh = 0` in src/shared/ConfigMeshyKit.luau or
// Config.luau), a sheet's one picture is `Meshy<Key>` in ConfigMeshyKit's Textures. Each file goes up as ONE Model by
// Open Cloud (only from art/models, the folder the owner approved; only through a Studio whose place is saved to Roblox:
// a local place answers "Scope 'asset:read' has not been granted"), and the ids are read back with InsertService:LoadAsset.
// art/models/village_ids.json keeps what is done: a file in it is skipped, take its entry out to upload it again.
//   node tools/kit/upload_village_pieces.js <studio_id of a place saved to Roblox>
const fs = require("fs");
const path = require("path");
const { open } = require("../studio_mcp_client");

const ROOT = path.resolve(__dirname, "..", "..");
const MODELS = path.join(ROOT, "art", "models");
const IDS = path.join(MODELS, "village_ids.json");
const CONFIGS = ["ConfigMeshyKit.luau", "Config.luau"].map((f) => path.join(ROOT, "src", "shared", f));
const OWNER = "2366260872";
// sheet key -> its name in ConfigMeshyKit's Textures
const TEXTURE = {
	granary: "MeshyGranary",
	kitchen: "MeshyKitchen",
	village: "MeshyVillage",
	stall: "MeshyStall",
	stallitems: "MeshyStallItems",
	kitchenkit: "MeshyKitchenKit",
	flowerpots: "MeshyFlowerPots",
	environment: "MeshyEnvironment",
	restaurant: "MeshyRestaurant",
};

const studio = process.argv[2];
if (!studio) {
	console.error("usage: node tools/kit/upload_village_pieces.js <studio_id>");
	process.exit(2);
}

function files() {
	const out = [];
	const walk = (dir) => {
		for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
			const full = path.join(dir, entry.name);
			if (entry.isDirectory()) walk(full);
			else if (entry.name.endsWith("_pieces.glb")) out.push(full);
		}
	};
	for (const dir of ["granary/meshy", "kitchen/meshy", "props/meshy"]) walk(path.join(MODELS, dir));
	const blender = path.join(MODELS, "granary", "blender");
	for (const name of fs.readdirSync(blender)) if (name.endsWith(".fbx")) out.push(path.join(blender, name));
	return out;
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

async function uploadModel(client, name, file) {
	const request = {
		assetType: "Model",
		displayName: `Goo Lineage village ${name}`,
		description: `Goo Lineage V2 village landmark pieces: ${name}`,
		creationContext: { creator: { userId: OWNER } },
	};
	const cloud = (args) => client.call("open_cloud_invoke", { studio_id: studio, ...args });
	const started = body(
		text(
			await cloud({
				method: "POST",
				endpoint: "/assets/v1/assets",
				body: JSON.stringify({ request }),
				files: [{ name: "fileContent", path: file }],
				scopes: ["asset:read", "asset:write"],
			}),
		),
	);
	for (let tries = 0; tries < 60; tries++) {
		await sleep(3000);
		const endpoint = `/assets/v1/operations/${started.operationId}`;
		const op = body(text(await cloud({ method: "GET", endpoint, scopes: ["asset:read"] })));
		if (op.done) {
			if (!op.response || !op.response.assetId) throw new Error(JSON.stringify(op));
			return op.response.assetId;
		}
	}
	throw new Error(`${name}: the upload did not finish`);
}

// every MeshPart of the uploaded Model: its name, mesh id and picture
async function piecesOf(client, model) {
	const code = `local m = game:GetService("InsertService"):LoadAsset(${model})
local out = {}
for _, d in m:GetDescendants() do
	if d:IsA("MeshPart") then
		table.insert(out, d.Name .. "|" .. (string.match(d.MeshId, "%d+") or "0") .. "|" .. (string.match(d.TextureID, "%d+") or "0"))
	end
end
m:Destroy()
return table.concat(out, ";")`;
	const reply = text(await client.call("execute_luau", { studio_id: studio, datamodel_type: "Edit", code }));
	const pieces = {};
	let texture = 0;
	for (const match of reply.matchAll(/([\w.]+)\|(\d+)\|(\d+)/g)) {
		pieces[match[1]] = Number(match[2]);
		texture = texture || Number(match[3]);
	}
	if (Object.keys(pieces).length === 0) throw new Error(`model ${model} has no MeshPart: ${reply.slice(0, 200)}`);
	return { pieces, texture };
}

// puts what ids.json knows into the two config files; says which names it could not place
function writeConfig(ids) {
	const sources = CONFIGS.map((file) => fs.readFileSync(file, "utf8"));
	const lost = [];
	for (const [key, entry] of Object.entries(ids)) {
		for (const [name, mesh] of Object.entries(entry.pieces)) {
			const row = new RegExp(`(\\b${name} = \\{\\s*\\{ mesh = )\\d+`);
			const at = sources.findIndex((source) => row.test(source));
			if (at < 0) lost.push(`${key}: ${name}`);
			else sources[at] = sources[at].replace(row, `$1${mesh}`);
		}
		if (TEXTURE[key] && entry.texture) {
			const row = new RegExp(`(\\b${TEXTURE[key]} = )"[^"]*"`);
			sources[0] = sources[0].replace(row, `$1"rbxassetid://${entry.texture}"`);
		}
	}
	CONFIGS.forEach((file, i) => fs.writeFileSync(file, sources[i]));
	return lost;
}

async function main(client) {
	const ids = fs.existsSync(IDS) ? JSON.parse(fs.readFileSync(IDS, "utf8")) : {};
	for (const file of files()) {
		const key = path.basename(file).replace(/(_pieces)?\.(glb|fbx)$/, "");
		if (ids[key]) {
			console.log(`SKIP ${key} (in village_ids.json)`);
			continue;
		}
		const model = await uploadModel(client, key, file);
		const { pieces, texture } = await piecesOf(client, model);
		ids[key] = { model: Number(model), texture, pieces };
		fs.writeFileSync(IDS, JSON.stringify(ids, null, "\t") + "\n");
		console.log(`DONE ${key} model ${model}: ${Object.keys(pieces).length} pieces, texture ${texture}`);
	}
	const lost = writeConfig(ids);
	console.log(lost.length === 0 ? "CONFIG OK" : `NOT IN CONFIG: ${lost.join(", ")}`);
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
