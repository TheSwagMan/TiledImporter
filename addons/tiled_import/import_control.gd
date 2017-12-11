tool
extends Control

func _ready():
	$tabc/Tileset/container/set_in_btn.connect("pressed", self, "set_import_ask_path")
	$tabc/Tileset/container/set_out_btn.connect("pressed", self, "set_export_ask_path")
	$tabc/Tileset/container/ok_btn.connect("pressed", self, "import_tileset")
	$tabc/Tileset/container/set_in_dlg.connect("file_selected", self, "set_import_path")
	$tabc/Tileset/container/set_out_dlg.connect("file_selected", self, "set_export_path")

	$tabc/Tilemap/container/map_in_btn.connect("pressed", self, "map_import_ask_path")
	$tabc/Tilemap/container/set_in_btn.connect("pressed", self, "set_open_ask_path")
	$tabc/Tilemap/container/map_out_btn.connect("pressed", self, "map_export_ask_path")
	$tabc/Tilemap/container/ok_btn.connect("pressed", self, "import_tilemap")
	$tabc/Tilemap/container/set_in_dlg.connect("file_selected", self, "set_open_path")
	$tabc/Tilemap/container/map_in_dlg.connect("file_selected", self, "map_import_path")
	$tabc/Tilemap/container/map_out_dlg.connect("file_selected", self, "map_export_path")

func set_import_ask_path():
	$tabc/Tileset/container/set_in_dlg.popup()

func set_export_ask_path():
	$tabc/Tileset/container/set_out_dlg.popup()

func set_open_ask_path():
	$tabc/Tilemap/container/set_in_dlg.popup()

func map_import_ask_path():
	$tabc/Tilemap/container/map_in_dlg.popup()

func map_export_ask_path():
	$tabc/Tilemap/container/map_out_dlg.popup()

func set_import_path(path):
	$tabc/Tileset/container/set_in_pth.text = path

func set_export_path(path):
	$tabc/Tileset/container/set_out_pth.text = path

func set_open_path(path):
	$tabc/Tilemap/container/set_in_pth.text = path

func map_import_path(path):
	$tabc/Tilemap/container/map_in_pth.text = path

func map_export_path(path):
	$tabc/Tilemap/container/map_out_pth.text = path

func parse_my_file(path):
	var file = File.new()
	var error = file.open(path, File.READ)
	if error != OK:
		print("Error : " + str(error))
		return FAILED
	var parsed = parse_json(file.get_as_text())
	file.close()
	return (parsed)
	

func import_tileset():
	print("Importing tileset...")
	var tileset_path = $tabc/Tileset/container/set_in_pth.text
	var export_path = $tabc/Tileset/container/set_out_pth.text
	print("From " + tileset_path + " to " + export_path)
	var parsed_tileset = parse_my_file(tileset_path)
	var root = Node2D.new()
	root.set_name(parsed_tileset.name)
	var image_path = tileset_path.get_base_dir() + "/" + parsed_tileset.image
	var dir = Directory.new()
	var img_tex = ImageTexture.new()
	img_tex.load(image_path)
	var img = img_tex.get_data()
	for i in range(parsed_tileset.tilecount / parsed_tileset.columns):
		for j in range(parsed_tileset.columns):
			var idx = i * parsed_tileset.tilecount / parsed_tileset.columns + j
			var sprite = Sprite.new()
			root.add_child(sprite)
			sprite.set_owner(root)
			sprite.set_name(str(idx))
			var tex = ImageTexture.new()
			sprite.centered = false
			sprite.position = Vector2(j * parsed_tileset.tileheight, i * parsed_tileset.tilewidth)
			tex.create_from_image(img.get_rect(Rect2(sprite.position, Vector2(parsed_tileset.tilewidth, parsed_tileset.tileheight))))
			tex.set_flags(0)
			sprite.texture = tex
			if parsed_tileset.has("tiles") and parsed_tileset.tiles.has(str(idx)):
				var static_body = StaticBody2D.new()
				sprite.add_child(static_body)
				static_body.set_owner(root)
				for obj in parsed_tileset.tiles[str(idx)].objectgroup.objects:
					if obj.type == "":
						var shape = CollisionShape2D.new()
						static_body.add_child(shape)
						shape.set_owner(root)
						var rect = RectangleShape2D.new()
						rect.extents = Vector2(obj.width / 2, obj.height / 2)
						shape.shape = rect
						shape.position = Vector2(obj.x + obj.width / 2, obj.y + obj.height / 2)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(export_path, packed)
	print("Done !")

func import_tilemap():
	print("Importing tilemap...")
	var tilemap_path = $tabc/Tilemap/container/map_in_pth.text
	var tileset_path = $tabc/Tilemap/container/set_in_pth.text
	var export_path = $tabc/Tilemap/container/map_out_pth.text
	print("From " + tilemap_path + " and " + tileset_path + " to " + export_path)
	var parsed_tilemap = parse_my_file(tilemap_path)
	var tileset = load(tileset_path)
	var root = Node2D.new()
	for layer in parsed_tilemap.layers:
		if layer.type == "tilelayer":
			var tm = TileMap.new()
			tm.tile_set = tileset
			tm.cell_size = Vector2(parsed_tilemap.tilewidth, parsed_tilemap.tileheight)
			tm.set_name(layer.name)
			tm.modulate = 0xffffff | (int(0xff * layer.opacity) << 24)
			tm.visible = layer.visible
			root.add_child(tm)
			tm.set_owner(root)
			for i in range(layer.height):
				for j in range(layer.width):
					tm.set_cell(j - layer.y, i - layer.x, layer.data[i * layer.width + j] - 1)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(export_path, packed)
	print("Done !")