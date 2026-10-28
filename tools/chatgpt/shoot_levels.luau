-- Review shots of several levels in one go (Server datamodel, after shoot_setup): builds each level
-- in turn and waits, so a screen capture can be taken between calls. Use _G.ShowLevel(i) with the
-- list set in _G.ShotLevels = { module, area, col, row, {levels} } (skill chatgpt-review).
_G.ShowLevel = function(i: number)
	local s = _G.ShotLevels
	return _G.AreaShow(s[1], s[2], s[3], s[4], s[5][i])
end
return "levels ready"
