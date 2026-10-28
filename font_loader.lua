local HttpService = game:GetService("HttpService")

local FontLoader = {}

FontLoader.Config = {
	Folder = "FontLoader",
	Refresh = false,
	Fonts = {
		ProggyClean = {
			{
				Url = "https://github.com/cutelilfemboy12/Resources/raw/refs/heads/main/ProggyClean.ttf",
				Weight = Enum.FontWeight.Regular,
				Style = Enum.FontStyle.Normal,
			},
		},
	},
}

local FONT_SIGNATURES = {
	["\0\1\0\0"] = true,
	["OTTO"] = true,
	["true"] = true,
	["ttcf"] = true,
}

local getAsset = getcustomasset or getsynasset
local families = {}

local function checkExecutor()
	assert(writefile and isfile and isfolder and makefolder, "FontLoader: executor is missing file functions")
	assert(getAsset, "FontLoader: executor is missing getcustomasset")
end

local function ensureFolder(path: string)
	if not isfolder(path) then
		makefolder(path)
	end
end

local function faceLabel(weight: Enum.FontWeight, style: Enum.FontStyle): string
	if style == Enum.FontStyle.Italic then
		return weight.Name .. "Italic"
	end
	return weight.Name
end

local function download(url: string, path: string)
	if isfile(path) and not FontLoader.Config.Refresh then
		return
	end

	local ok, data = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then
		error(string.format("FontLoader: could not download %s (%s)", url, tostring(data)), 0)
	end
	if type(data) ~= "string" or not FONT_SIGNATURES[string.sub(data, 1, 4)] then
		error(string.format("FontLoader: %s is not a font file", url), 0)
	end

	writefile(path, data)
end

function FontLoader.register(name: string, faces)
	FontLoader.Config.Fonts[name] = faces
	families[name] = nil
end

function FontLoader.load(name: string): string
	local family = families[name]
	if family then
		return family
	end

	local faces = FontLoader.Config.Fonts[name]
	if not faces then
		error(string.format("FontLoader: unknown font %q", name), 2)
	end
	checkExecutor()

	local folder = FontLoader.Config.Folder
	local fontFolder = folder .. "/" .. name
	ensureFolder(folder)
	ensureFolder(fontFolder)

	local entries = table.create(#faces)
	for _, face in faces do
		local weight = face.Weight or Enum.FontWeight.Regular
		local style = face.Style or Enum.FontStyle.Normal
		local label = face.Name or faceLabel(weight, style)
		local extension = string.lower(string.match(face.Url, "%.(%w+)$") or "ttf")
		local path = string.format("%s/%s.%s", fontFolder, label, extension)

		download(face.Url, path)
		table.insert(entries, {
			name = label,
			weight = weight.Value,
			style = string.lower(style.Name),
			assetId = getAsset(path),
		})
	end

	local familyPath = string.format("%s/%s.font", fontFolder, name)
	writefile(familyPath, HttpService:JSONEncode({ name = name, faces = entries }))

	family = getAsset(familyPath)
	families[name] = family
	return family
end

function FontLoader.get(name: string, weight: Enum.FontWeight?, style: Enum.FontStyle?): Font
	return Font.new(FontLoader.load(name), weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal)
end

function FontLoader.loadAll()
	for name in FontLoader.Config.Fonts do
		FontLoader.load(name)
	end
end

return FontLoader
