// Turns the text of tools/map/market_raypreview.luau into a PNG: node tools/map/market_rle_to_png.js <in.txt> <out.png> [scale]
const fs = require("fs");
const zlib = require("zlib");
const [, , input, output, scaleArg] = process.argv;
const scale = Number(scaleArg || 2);
const lines = fs.readFileSync(input, "utf8").split(/\r?\n/);
const start = lines.findIndex((l) => /^\d+ \d+$/.test(l.trim()));
const [W, H] = lines[start].trim().split(" ").map(Number);
const raw = Buffer.alloc((W * scale * 3 + 1) * H * scale);
for (let y = 0; y < H; y++) {
	const row = [];
	for (const item of (lines[start + 1 + y] || "").split(",")) {
		const [n, c] = item.split(".");
		for (let k = 0; k < Number(n); k++) row.push(c);
	}
	for (let s = 0; s < scale; s++) {
		let o = (y * scale + s) * (W * scale * 3 + 1);
		raw[o++] = 0;
		for (let x = 0; x < W; x++) {
			const c = row[x] || "000";
			const r = parseInt(c[0], 16) * 17, g = parseInt(c[1], 16) * 17, b = parseInt(c[2], 16) * 17;
			for (let t = 0; t < scale; t++) {
				raw[o++] = r;
				raw[o++] = g;
				raw[o++] = b;
			}
		}
	}
}
function crc32(buf) {
	let c, crc = ~0;
	for (let n = 0; n < buf.length; n++) {
		c = (crc ^ buf[n]) & 255;
		for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
		crc = (crc >>> 8) ^ c;
	}
	return ~crc >>> 0;
}
function chunk(type, data) {
	const len = Buffer.alloc(4);
	len.writeUInt32BE(data.length);
	const td = Buffer.concat([Buffer.from(type), data]);
	const crc = Buffer.alloc(4);
	crc.writeUInt32BE(crc32(td));
	return Buffer.concat([len, td, crc]);
}
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(W * scale, 0);
ihdr.writeUInt32BE(H * scale, 4);
ihdr[8] = 8;
ihdr[9] = 2;
fs.writeFileSync(output, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(raw)), chunk("IEND", Buffer.alloc(0))]));
