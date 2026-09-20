local LocaleFile = LoadResourceFile(U.Cache.Resource, ('locales/%s.json'):format(Config.Locale or 'en'))
local Locales = json.decode(LocaleFile)

function _(str, ...)
	if Locales and Locales[str] then
		if select('#', ...) > 0 then
			return Locales[str]:format(...)
		end
		return Locales[str]
	end

	return str
end

function _U(str, ...)
	return tostring(_(str, ...):gsub("^%l", string.upper))
end
