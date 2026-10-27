// Serves one folder on http://localhost:<port>/ for a few minutes, so that Studio's MCP tool
// upload_image (which takes http URLs) can upload local pictures:
//   node tools/serve_dir.js <folder> [port=8765] [minutes=10]
// Carried over from the owner's previous game (C:\roblox 2nd game\tools\serve_dir.js).
const http = require("http");
const fs = require("fs");
const path = require("path");

const [dir, portArg, minutesArg] = process.argv.slice(2);
const root = path.resolve(dir || ".");
const port = Number(portArg || 8765);
const types = { ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg" };

const server = http.createServer((req, res) => {
	const name = decodeURIComponent((req.url || "/").split("?")[0]).replace(/^\/+/, "");
	const file = path.join(root, name);
	if (!file.startsWith(root) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
		res.writeHead(404);
		res.end("not found");
		return;
	}
	res.writeHead(200, { "Content-Type": types[path.extname(file).toLowerCase()] || "application/octet-stream" });
	fs.createReadStream(file).pipe(res);
});
server.listen(port, "127.0.0.1", () => console.log(`serving ${root} on http://localhost:${port}/`));
setTimeout(() => process.exit(0), Number(minutesArg || 10) * 60000);
