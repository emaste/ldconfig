--[[
	elfhints.lua
	copy of sbin/ldconfig/elfhints.c
--]]

local lfs = require('lfs')
local Util = require('util')

local S_IWOTH = 2            -- 0002
local S_IWGRP = 16           -- 0020

-- @export @class
local function Elfhints(hintsfile, insecure)
	-- @private
	local dirs = {}

	-- @private @method
	local function add_dir(name, trusted)
		if not trusted and not insecure then
			local fstat, errmsg, errcode = lfs.attributes(name)
			if fstat == nil then
				Util.warn(errmsg, errcode, '%s', name)
				return
			end
			if fstat.uid ~= 0 then
				Util.warnx('%s: ignoring directory not owned by root', name)
				return
			end
			local fperm = tonumber(fstat.permissions, 8)
			if (fperm & S_IWOTH) ~= 0 then
				Util.warnx('%s: ignoring world-writable directory', name)
				return
			end
			if (fperm & S_IWGRP) ~= 0 then
				Util.warnx('%s: ignoring group-writable directory', name)
				return
			end
		end

		for i = 1, #dirs do
			if dirs[i] == name then return end
		end
		dirs[#dirs + 1] = name
	end

	-- @private @method
	local function read_dirs_from_file(listfile)
		local fp, errmsg, errcode = io.open(listfile, 'r')
		if fp == nil then
			Util.err(1, errmsg, errcode, '%s', listfile)
		end
		local linenum = 0
		for line in fp:lines() do
			linenum = linenum + 1
			-- skip comments starting with #
			if string.match(line, '^%s*#') then goto continue end
			local name, trailing = string.match(line, '^%s*(%S+)%s*(%S*)')
			-- matched dir name
			if name ~= nil then add_dir(name, false) end
			-- has trailing characters after dir name 
			if trailing ~= nil and trailing ~= '' then
				Util.warnx('%s:%d: trailing characters ignored', listfile, linenum)
			end
			-- it is sure that lines with only whitespaces won't trigger any of the above
			::continue::
		end
		fp:close()
	end

end -- function Elfhints
Elfhints()

--[[ end elfhints.lua ]]
