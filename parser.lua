

local find = string.find
local sub = string.sub
local match = string.match
local insert = table.insert

local JSON = require("json")

local function split(str, pat)
   local t = {}
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = find(str , fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         insert(t,cap)
      end
      last_end = e+1
      s, e, cap = find( str,fpat, last_end)
   end
   if last_end <= #str then
      cap = sub( str , last_end)
      insert(t, cap)
   end
   return t
end

local function trim(s)
   return match(s,'^()%s*$') and '' or match(s,'^%s*(.*%S)')
end

local function slice( tbl , s , e )
	local out = ""
	for i,v in ipairs( tbl ) do
		if i > s and i < e then
			out = out .. v
		end
	end
	return out
end

local exports = {}

exports.Parse = function(multipartBodyBuffer,boundary)

	local prev = nil;
	local lastline='';
	local header = '';
	local info = ''; local state=0; local buffer={};
	local allParts = {};
	local header2state = false;
	local counter = 0;
	local startbody = nil;
	local endbody = 0;
	local headercapture = "";
	local header1state = false

	for i=1,#multipartBodyBuffer do

		local oneByte = sub( multipartBodyBuffer ,i,i);
		local prevByte = sub( multipartBodyBuffer ,i-1,i-1);
		local newLineDetected = ((oneByte == "\n") and (prevByte == "\r"));
		local newLineChar = ((oneByte == "\n") or (oneByte == "\r"));

		if header1state then
			headercapture = headercapture .. prevByte
		end
		
		if not newLineChar then
			lastline = lastline .. oneByte;
		elseif lastline ~= "" then
			

			if not startbody and not header1state then
				if header2state then
					headercapture = headercapture .. lastline .. "; "
				end
				header2state = true
			end

			if ("--" .. boundary) == lastline then
				header1state = not header1state
				if header1state == false then
					headercapture = string.sub( headercapture , 1 , #headercapture - #lastline) .. "; "
				end
			end

			lastline= ""
			counter = 0
		else
			if not header1state then
				counter = counter + 1
				if counter == 3 then
					startbody = i
				end
			end
		end
	end

	allParts.DATA = sub( multipartBodyBuffer , startbody + 1 , #multipartBodyBuffer - (#boundary + 8) )
	allParts.headers = headercapture:gsub('%c', '')
	return allParts;
end


return exports