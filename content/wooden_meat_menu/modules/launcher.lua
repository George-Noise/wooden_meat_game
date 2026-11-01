local MENU_PACK = "wooden_meat_menu"
local WORLDS_DIR = "worlds"
local DEFAULT_ZIP = "prepared_world.zip"
local TAG = "[launcher] "

local function log(msg)
	print(TAG .. tostring(msg))
end

local function fail(msg, err)
	local text = msg
	if err ~= nil then
		text = msg .. "\n" .. tostring(err)
	end
	log("ОШИБКА: " .. text)
	if type(debug) == "table" and type(debug.traceback) == "function" then
		log("traceback:\n" .. debug.traceback(tostring(text), 2))
	end
end

local function join(root, name)
	local last = root:sub(-1)
	if last == ":" or last == "/" or last == "\\" then
		return root .. name
	end
	return root .. "/" .. name
end

local function is_safe_name(name)
	if type(name) ~= "string" or name == "" then
		return false
	end
	if name:find("[/\\]") or name:find("%.%.") then
		return false
	end
	return true
end

local function find_world_zip()
	local packdir = pack.get_folder(MENU_PACK)
	if packdir == "" then
		return nil, "пак '" .. MENU_PACK .. "' не установлен"
	end
	local dir = join(packdir, WORLDS_DIR)
	local default_path = join(dir, DEFAULT_ZIP)
	if file.isfile(default_path) then
		return default_path
	end
	if file.isdir(dir) then
		for _, path in ipairs(file.list(dir)) do
			if file.isfile(path) and file.ext(path) == "zip" then
				log("prepared_world.zip не найден, использую " .. path)
				return path
			end
		end
	end
	return nil, "не найден файл " .. DEFAULT_ZIP .. " в " .. dir
end

local function find_world_root(mount)
	local root = mount .. ":"
	if file.isfile(join(root, "world.json")) then
		return root
	end
	local found = nil
	for _, path in ipairs(file.list(root)) do
		if file.isdir(path) and file.isfile(join(path, "world.json")) then
			if found then
				error("в zip несколько папок с world.json", 0)
			end
			found = path
		end
	end
	return found
end

local function read_world_name(root)
	local text = file.read(join(root, "world.json"))
	local ok, data = pcall(json.parse, text)
	if not ok then
		error("world.json не парсится: " .. tostring(data), 0)
	end
	if type(data) ~= "table" or not is_safe_name(data.name) then
		error("world.json: отсутствует или некорректно поле 'name'", 0)
	end
	return data.name
end

local function get_zip_world_name(zippath)
	log("монтирую " .. zippath)
	local mount = file.mount(zippath)
	log("точка монтирования: " .. mount .. ":")
	local world_name = nil
	local ok, err = pcall(function()
		local root = find_world_root(mount)
		if root == nil then
			error("в zip нет world.json (ни в корне, ни в одной из папок)", 0)
		end
		log("корень мира в zip: " .. root)
		world_name = read_world_name(root)
	end)
	pcall(file.unmount, mount)
	if not ok then
		error(tostring(err), 0)
	end
	return world_name
end

local function copy_file(src, dst)
	local data = file.read(src)
	if not file.write_bytes(dst, data) then
		error("file.write_bytes вернул false для " .. dst, 0)
	end
end

local function copy_tree(src, dst)
	file.mkdirs(dst)
	local entries = file.list(src)
	for _, path in ipairs(entries) do
		local name = path:sub(#src + 1):gsub("^[/\\]+", "")
		if name ~= "" then
			local target = join(dst, name)
			if file.isdir(path) then
				copy_tree(path, target)
			else
				copy_file(path, target)
			end
		end
	end
	return #entries
end

local function unpack_world(zippath, world_name)
	if world_name == nil then
		world_name = get_zip_world_name(zippath)
	end
	log("имя мира из world.json: '" .. world_name .. "'")
	local dst = join("user:worlds", world_name)
	if file.exists(dst) then
		log("старая папка мира найдена, удаляю: " .. dst)
		file.remove_tree(dst)
	end

	log("монтирую " .. zippath)
	local mount = file.mount(zippath)
	log("точка монтирования: " .. mount .. ":")
	local ok, err = pcall(function()
		local root = find_world_root(mount)
		if root == nil then
			error("в zip нет world.json (ни в корне, ни в одной из папок)", 0)
		end
		log("корень мира в zip: " .. root)
		log("распаковываю в " .. dst)
		copy_tree(root, dst)
		log("распаковка завершена")
	end)
	pcall(file.unmount, mount)
	if not ok then
		error(tostring(err), 0)
	end
	return world_name
end

local function open_world(app, world_name)
	log("открываю мир '" .. world_name .. "'")
	local okopen, open_err = pcall(app.open_world, world_name)
	if not okopen then
		fail("не удалось открыть мир", open_err)
	end
end

local function play_prepared(app, known_name)
	local zippath, err = find_world_zip()
	if zippath == nil then
		fail("не удалось найти zip мира: " .. tostring(err))
		return
	end
	log("zip мира: " .. zippath)

	local world_name = nil
	local ok, unpack_err = pcall(function()
		world_name = unpack_world(zippath, known_name)
	end)
	if not ok then
		fail("не удалось распаковать мир", unpack_err)
		return
	end

	open_world(app, world_name)
end

local function continue_prepared(app)
	local zippath, err = find_world_zip()
	if zippath == nil then
		fail("не удалось найти zip мира: " .. tostring(err))
		return
	end
	log("zip мира: " .. zippath)

	local world_name = nil
	local ok, name_err = pcall(function()
		world_name = get_zip_world_name(zippath)
	end)
	if not ok then
		fail("не удалось прочитать имя мира из zip", name_err)
		return
	end
	log("имя мира из world.json: '" .. world_name .. "'")

	local dst = join("user:worlds", world_name)
	if file.isdir(dst) and file.isfile(join(dst, "world.json")) then
		log("мир '" .. world_name .. "' уже распакован, открываю как есть")
		open_world(app, world_name)
		return
	end

	log("мира нет в user:worlds, запускаю новую игру")
	play_prepared(app, world_name)
end

return {
	play_prepared = play_prepared,
	continue_prepared = continue_prepared,
}
