--!strict
-- Which pieces of a rebuilt stage really changed: each new piece is matched by what it is and where it stands, not by
-- its build order, so a piece added early does not make every later piece of the same name look changed.
local UpgradeDiff = {}

export type Piece = { signature: string, size: number }

-- Returns the indexes of `after` with no equal piece left in `before`, biggest first, at most `limit`.
function UpgradeDiff.changed(before: { string }, after: { Piece }, limit: number): { number }
	local left: { [string]: number } = {}
	for _, signature in before do
		left[signature] = (left[signature] or 0) + 1
	end
	local out: { number } = {}
	for index, piece in after do
		local count = left[piece.signature] or 0
		if count > 0 then
			left[piece.signature] = count - 1
		else
			table.insert(out, index)
		end
	end
	table.sort(out, function(a: number, b: number): boolean
		if after[a].size ~= after[b].size then
			return after[a].size > after[b].size
		end
		return a < b
	end)
	for index = #out, limit + 1, -1 do
		out[index] = nil
	end
	return out
end

return UpgradeDiff
