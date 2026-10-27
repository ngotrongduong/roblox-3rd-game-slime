-- A tiny test kit for the Lune checks. A spec file returns a function that receives this kit:
--   return function(T)
--       T.test("level is the sum of the stats", function()
--           T.eq(Stats.level({ ... }), 4)
--       end)
--   end
local T = {}

local passed, failed = 0, 0
local failures: { string } = {}
local currentFile = "?"

local function show(v: any): string
	if type(v) == "string" then
		return string.format("%q", v)
	end
	return tostring(v)
end

function T.setFile(name: string)
	currentFile = name
end

function T.test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failed += 1
		table.insert(failures, currentFile .. " > " .. name .. ": " .. tostring(err))
	end
end

function T.ok(cond: any, msg: string?)
	if not cond then
		error(msg or "expected a true value", 2)
	end
end

function T.eq(actual: any, expected: any, msg: string?)
	if actual ~= expected then
		error((msg and msg .. ": " or "") .. "expected " .. show(expected) .. ", got " .. show(actual), 2)
	end
end

function T.near(actual: number, expected: number, tolerance: number, msg: string?)
	if math.abs(actual - expected) > tolerance then
		error(
			(msg and msg .. ": " or "")
				.. "expected "
				.. tostring(expected)
				.. " ± "
				.. tostring(tolerance)
				.. ", got "
				.. tostring(actual),
			2
		)
	end
end

-- Deep equality of plain tables (no cycles).
function T.same(actual: any, expected: any, msg: string?)
	local function deep(a: any, b: any, path: string): string?
		if type(a) ~= type(b) then
			return path .. ": type " .. type(b) .. " expected, got " .. type(a)
		end
		if type(a) ~= "table" then
			if a ~= b then
				return path .. ": expected " .. show(b) .. ", got " .. show(a)
			end
			return nil
		end
		for k, v in b do
			local d = deep(a[k], v, path .. "." .. tostring(k))
			if d then
				return d
			end
		end
		for k in a do
			if b[k] == nil then
				return path .. "." .. tostring(k) .. ": unexpected key"
			end
		end
		return nil
	end
	local d = deep(actual, expected, "value")
	if d then
		error((msg and msg .. ": " or "") .. d, 2)
	end
end

-- The call must raise an error.
function T.throws(fn: () -> (), msg: string?)
	local ok = pcall(fn)
	if ok then
		error(msg or "expected an error", 2)
	end
end

function T.report(): boolean
	for _, f in failures do
		print("FAIL " .. f)
	end
	print(string.format("%d passed, %d failed", passed, failed))
	return failed == 0
end

return T
