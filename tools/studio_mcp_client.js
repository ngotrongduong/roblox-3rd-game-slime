// The transport to Roblox Studio's built-in MCP server (StudioMCP.exe through
// %LOCALAPPDATA%\Roblox\mcp.bat, stdio JSON-RPC), used by tools/studio_mcp.js and by any tool
// that makes many calls in one session. Carried over from the owner's previous game
// (C:\roblox 2nd game\tools\studio_mcp_client.js).
const { spawn } = require("child_process");
const path = require("path");

const NO_STUDIO = /No Roblox Studio instances are connected|No studio available|`studio_id` is not connected/;

async function open(options = {}) {
	const timeoutMs = options.timeoutMs || Number(process.env.STUDIO_MCP_TIMEOUT || 180000);
	const quiet = options.quiet !== false;
	const bat = path.join(process.env.LOCALAPPDATA, "Roblox", "mcp.bat");
	const child = spawn("cmd.exe", ["/c", bat], { stdio: ["pipe", "pipe", "pipe"] });
	let buffer = "";
	let nextId = 1;
	const waiting = new Map();

	child.stderr.on("data", (d) => {
		// the proxy's own warnings (no studio yet, a websocket reset) are noise unless asked for
		if (!quiet) process.stderr.write(d);
	});
	child.stdout.on("data", (chunk) => {
		buffer += chunk.toString("utf8");
		let at;
		while ((at = buffer.indexOf("\n")) >= 0) {
			const line = buffer.slice(0, at).trim();
			buffer = buffer.slice(at + 1);
			if (line === "") continue;
			let message;
			try {
				message = JSON.parse(line);
			} catch {
				continue;
			}
			if (message.id !== undefined && waiting.has(message.id)) {
				const done = waiting.get(message.id);
				waiting.delete(message.id);
				done(message);
			}
		}
	});

	function send(method, params, ms = timeoutMs) {
		const id = nextId++;
		child.stdin.write(JSON.stringify({ jsonrpc: "2.0", id, method, params }) + "\n");
		return new Promise((resolve, reject) => {
			const timer = setTimeout(() => reject(new Error("timeout waiting for " + method)), ms);
			waiting.set(id, (message) => {
				clearTimeout(timer);
				resolve(message);
			});
		});
	}

	const init = await send("initialize", {
		protocolVersion: "2025-06-18",
		capabilities: {},
		clientInfo: { name: "goolineage-studio-mcp", version: "1.0" },
	});
	if (init.error) throw new Error(JSON.stringify(init.error));
	child.stdin.write(JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized", params: {} }) + "\n");

	// Studio attaches to a fresh proxy a moment after it starts: a call made too early is told
	// that no Studio is connected, so it is tried again for a while.
	async function call(name, args, ms) {
		let answer;
		for (let attempt = 1; attempt <= 15; attempt++) {
			answer = await send("tools/call", { name, arguments: args }, ms);
			const text = JSON.stringify(answer.result || answer.error || "");
			if (!NO_STUDIO.test(text)) break;
			await new Promise((r) => setTimeout(r, 1000));
		}
		return answer;
	}

	function text(answer) {
		if (answer.error) return "ERROR " + JSON.stringify(answer.error);
		return (answer.result.content || [])
			.filter((p) => p.type === "text")
			.map((p) => p.text)
			.join("\n");
	}

	function close() {
		child.stdin.end();
		setTimeout(() => child.kill(), 300);
	}

	return { send, call, text, close };
}

module.exports = { open };
