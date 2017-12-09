tool
extends Control

func _ready():
	$container/map_btn.connect("pressed", self, "map_ask_path")
	$container/set_btn.connect("pressed", self, "set_ask_path")
	$container/ok_btn.connect("pressed", self, "do_it")
	$container/map_dlg.connect("file_selected", self, "map_path")
	$container/set_dlg.connect("file_selected", self, "set_path")

func map_ask_path():
	$container/map_dlg.popup()

func set_ask_path():
	$container/set_dlg.popup()

func map_path(path):
	$container/map_pth.text = path

func set_path(path):
	$container/set_pth.text = path

func do_it():
	var map_file = File.new()
	var e
	var root
	var packed
	e = map_file.open($container/map_pth.text, File.READ)
	if e != OK:
		print("Error :" + str(e))
		return FAILED
	var a = parse_json(map_file.get_as_text())
	var set_file = File.new()
	e = set_file.open($container/set_pth.text, File.READ)
	if e != OK:
		print("Error :" + str(e))
		return FAILED
	var b = parse_json(set_file.get_as_text())
	# parse tileset
	var tileset = TileSet.new()
	root = Node2D.new()
	root.set_name(b.name)
	print($container/set_pth.text.get_base_dir() + "/" + b.image)
	var img = load($container/set_pth.text.get_base_dir() + "/" + b.image).get_data()
	for i in range(b.columns):
		for j in range(b.tilecount / b.columns):
			var idx = i * b.tilecount / b.columns + j
			var sprite = Sprite.new()
			var tex = ImageTexture.new()
			sprite.centered = false
			sprite.position = Vector2(j * b.tileheight, i * b.tilewidth)
			tex.create_from_image(img.get_rect(Rect2(sprite.position, Vector2(b.tilewidth, b.tileheight))))
			tex.set_flags(0)
			$TextureRect.texture = tex
			sprite.texture = tex
			root.add_child(sprite)
			sprite.set_owner(root)
			tileset.create_tile(idx)
			tileset.tile_set_name(idx, ("%0" + str(str(b.tilecount).length()) + "d") % idx)
			tileset.tile_set_texture(idx, tex)
	packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save($container/set_pth.text + ".tileset.tscn", packed)
	ResourceSaver.save($container/set_pth.text + ".tileset.tres", tileset)
	# parse tilemap
	root = Node2D.new()
	for layer in a.layers:
		if layer.type == "tilelayer":
			var tm = TileMap.new()
			tm.tile_set = tileset
			tm.cell_size = Vector2(a.tilewidth, a.tileheight)
			tm.set_name(layer.name)
			tm.modulate = 0xffffff | (int(0xff * layer.opacity) << 24)
			tm.visible = layer.visible
			root.add_child(tm)
			tm.set_owner(root)
			for i in range(layer.height):
				for j in range(layer.width):
					tm.set_cell(j - layer.y, i - layer.x, layer.data[i * layer.width + j] - 1)
	packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save($container/map_pth.text + ".tilemap.tscn", packed)
	print("Done.")