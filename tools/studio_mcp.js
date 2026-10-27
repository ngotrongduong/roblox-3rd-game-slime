// A one-shot client of Roblox Studio's built-in MCP server (the transport is
// tools/studio_mcp_client.js). It lets a session or a subagent drive the open Studio without the
// MCP server being loaded into the session itself. Carried over from the owner's previous game
// (C:\roblox 2nd game\tools\studio_mcp.js).
//
//   node tools/studio_mcp.js list                       the tools and their input schemas
//   node tools/studio_mcp.js call <tool> [args.json]    one call; args from a JSON file (or none)
//   node tools/studio_mcp.js run <file.luau> <studio_id> [Edit|Server|Client] [NAME=file ...]
//                                                       execute_luau with the file's code; each
//                                                       NAME=file becomes a local string NAME
//   node tools/studio_mcp.js shot <studio_id> <out.png> [cx cy cz lx ly lz]
//                                                       screen_capture, the camera placed if given
//
// Text results are printed; images are written next to the args file (or to the temp folder)
// as <tool>_<n>.png and their paths printed. Studio must have Assistant > ... > Settings > MCP
// Servers > "Enable Studio as MCP server" on.
const fs = require("fs");
const os = require("os");
const path = require("path");
const { open } = require("./studio_mcp_client");

const argv = process.argv.slice(2);
const mode = argv[0];
let tool = argv[1];
let argsFile = argv[2];
let inlineArgs = null;
let shotOut = null;
if (mode === "run") {
	tool = "execute_luau";
	let prelude = "";
	for (const extra of argv.slice(4)) {
		const at = extra.indexOf("=");
		if (at > 0) {
			prelude += `local ${extra.slice(0, at)} = [==[${fs.readFileSync(extra.slice(at + 1), "utf8")}]==]\n`;
		}
	}
	inlineArgs = {
		code: prelude + fs.readFileSync(argv[1], "utf8"),
		studio_id: argv[2],
		datamodel_type: argv[3] || "Edit",
	};
	argsFile = argv[1];
} else if (mode === "shot") {
	tool = "screen_capture";
	inlineArgs = { studio_id: argv[1], capture_id: "Shot_" + Date.now() };
	shotOut = argv[2];
	if (argv.length >= 9) {
		const n = argv.slice(3, 9).map(Number);
		inlineArgs.camera_position = n.slice(0, 3);
		inlineArgs.look_at_position = n.slice(3, 6);
	}
	argsFile = shotOut;
} else if (mode !== "list" && mode !== "call") {
	console.error("usage: node studio_mcp.js list | call <tool> [args.json] | run <file.luau> <studio_id> | shot <studio_id> <out.png>");
	process.exit(2);
}

async function main(client) {
	if (mode === "list") {
		const listed = await client.send("tools/list", {});
		for (const t of listed.result.tools) {
			console.log("== " + t.name + "\n" + (t.description || "").trim() + "\n" + JSON.stringify(t.inputSchema));
		}
		return;
	}
	const args = inlineArgs || (argsFile ? JSON.parse(fs.readFileSync(argsFile, "utf8")) : {});
	const answer = await client.call(tool, args);
	if (answer.error) {
		console.log("ERROR " + JSON.stringify(answer.error));
		process.exitCode = 1;
		return;
	}
	const outDir = argsFile ? path.dirname(path.resolve(argsFile)) : os.tmpdir();
	let n = 0;
	for (const part of answer.result.content || []) {
		if (part.type === "text") {
			console.log(part.text);
		} else if (part.type === "image") {
			n += 1;
			const file = shotOut && n === 1 ? path.resolve(shotOut) : path.join(outDir, tool + "_" + n + ".png");
			fs.writeFileSync(file, Buffer.from(part.data, "base64"));
			console.log("IMAGE " + file);
		} else {
			console.log(JSON.stringify(part).slice(0, 2000));
		}
	}
	if (answer.result.isError) process.exitCode = 1;
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
