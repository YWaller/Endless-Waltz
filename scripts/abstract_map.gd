
var size = Vector2(0, 0)
var fields = [[null]]
var map
var tilemap
var field_template = preload('abstract_field.gd')

var MAX_MAP_SIZE = 40
const MAP_MAX_X = 40
const MAP_MAX_Y = 40

func reset():
	self.size = Vector2(0, 0)
	self.fields = [[null]]

func init_map(map_node):
	self.map = map_node
	self.tilemap = self.map.get_node("terrain")

func get_fields():
	return fields

# TODO extending should be done in diferent wa
func get_field(position):
	if position.x < 0 || position.y < 0:
		return self.create_out_of_bounds_field()

	if fields[0][0] == null:
		fields[0][0] = self.create_field(Vector2(0, 0))

	if (position.x > size.x || position.y > size.y):
		self.extend(position)
	return fields[position.y][position.x]

func extend(position):
	var row
	var field
	#extend existing rows
	for i in range(size.y + 1):
		row = fields[i]
		for j in range(position.x - size.x):
			row.insert(size.x + j + 1, self.create_field(Vector2(size.x + j + 1, i)))

	#add new rows
	var width = position.x
	if size.x > width:
		width = size.x

	for i in range(position.y - size.y):
		row = []
		for j in range(width + 1):
			row.insert(j, self.create_field(Vector2(j, size.y + i + 1)))
		fields.insert(size.y + i + 1, row)

	if position.x > size.x:
		size.x = position.x
	if position.y > size.y:
		size.y = position.y

func create_field(position):
	var field = field_template.new()
	field.position = position
	field.terrain_type = tilemap.get_cell(position.x, position.y)
	field.abstract_map = self
	return field

func is_spawning_point(position):
	return tilemap.get_cell(position.x, position.y) == 13


func create_out_of_bounds_field():
	var field = self.create_field(Vector2(-1, -1))

	return field

