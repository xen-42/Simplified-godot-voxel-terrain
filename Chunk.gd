extends StaticBody
tool

const vertices = [
	Vector3(0, 0, 0), #0
	Vector3(1, 0, 0), #1
	Vector3(0, 1, 0), #2
	Vector3(1, 1, 0), #3
	Vector3(0, 0, 1), #4
	Vector3(1, 0, 1), #5
	Vector3(0, 1, 1), #6
	Vector3(1, 1, 1)  #7
]

const TOP = [2, 3, 7, 6]
const BOTTOM = [0, 4, 5, 1]
const LEFT = [6, 4, 0, 2]
const RIGHT = [3, 1, 5, 7]
const FRONT = [7, 5, 4, 6]
const BACK = [2, 0, 1, 3]

var blocks = []

var st = SurfaceTool.new()
var mesh = null
var mesh_instance = null

var material = preload("res://assets/new_spatialmaterial.tres")

var chunk_position = Vector2() setget set_chunk_position

var noise = OpenSimplexNoise.new()

func _ready():
	material.albedo_texture.set_flags(2)
	
	generate()
	update()

func generate():
	blocks = []
	blocks.resize(Global.DIMENSION.x)
	for i in range(0, Global.DIMENSION.x):
		blocks[i] = []
		blocks[i].resize(Global.DIMENSION.y)
		for j in range(0, Global.DIMENSION.y):
			blocks[i][j] = []
			blocks[i][j].resize(Global.DIMENSION.z)
			for k in range(0, Global.DIMENSION.z):
				var global_pos = chunk_position * \
					Vector2(Global.DIMENSION.x, Global.DIMENSION.z) + \
					Vector2(i, k)
				
				var height = int((noise.get_noise_2dv(global_pos) + 1)/2 * Global.DIMENSION.y)
				
				var block = Global.AIR
				
				if j < height / 2:
					block = Global.STONE
				elif j < height:
					block = Global.DIRT
				elif j == height:
					block = Global.GRASS
				
				blocks[i][j][k] = block

func update():
	# Unload
	if mesh_instance != null:
		mesh_instance.call_deferred("queue_free")
		mesh_instance = null
	
	mesh = Mesh.new()
	mesh_instance = MeshInstance.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in Global.DIMENSION.x:
		for y in Global.DIMENSION.y:
			for z in Global.DIMENSION.z:
				create_block(x, y, z)
	
	st.generate_normals(false)
	st.set_material(material)
	st.commit(mesh)
	mesh_instance.set_mesh(mesh)
	
	add_child(mesh_instance)
	mesh_instance.create_trimesh_collision()
	
	self.visible = true

func check_transparent(x, y, z):
	if x >= 0 and x < Global.DIMENSION.x and \
		y >= 0 and y < Global.DIMENSION.y and \
		z >= 0 and z < Global.DIMENSION.z:
			return not Global.types[blocks[x][y][z]][Global.SOLID]
	return true

func create_block(x, y, z):
	var block = blocks[x][y][z]
	if block == Global.AIR:
		return
	
	var block_info = Global.types[block]
	
	if check_transparent(x, y + 1, z):
		create_face(TOP, x, y, z, block_info[Global.TOP])
	
	if check_transparent(x, y - 1, z):
		create_face(BOTTOM, x, y, z, block_info[Global.BOTTOM])
	
	if check_transparent(x - 1, y, z):
		create_face(LEFT, x, y, z, block_info[Global.LEFT])
		
	if check_transparent(x + 1, y, z):
		create_face(RIGHT, x, y, z, block_info[Global.RIGHT])
		
	if check_transparent(x, y, z - 1):
		create_face(BACK, x, y, z, block_info[Global.BACK])
		
	if check_transparent(x, y, z + 1):
		create_face(FRONT, x, y, z, block_info[Global.FRONT])
	
func create_face(i, x, y, z, texture_atlas_offset):
	var offset = Vector3(x, y, z)
	var a = vertices[i[0]] + offset
	var b = vertices[i[1]] + offset
	var c = vertices[i[2]] + offset
	var d = vertices[i[3]] + offset
	
	var uv_offset = texture_atlas_offset / Global.TEXTURE_ATLAS_SIZE
	var height = 1.0 / Global.TEXTURE_ATLAS_SIZE.y
	var width = 1.0 / Global.TEXTURE_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(0, height)
	var uv_c = uv_offset + Vector2(width, height)
	var uv_d = uv_offset + Vector2(width, 0)
	
	st.add_triangle_fan(([a, b, c]), ([uv_a, uv_b, uv_c]))
	st.add_triangle_fan(([a, c, d]), ([uv_a, uv_c, uv_d]))
	
func set_chunk_position(pos):
	chunk_position = pos
	translation = Vector3(pos.x, 0, pos.y) * Global.DIMENSION
	
	self.visible = false
	
	
	
	
	
	
	
	
	
