extends Control

export var show_blueprint = false
export var campaign_map = true
export var take_enemy_hq = true
export var control_all_towers = false
export var multiplayer_map = false

var terrain
var underground
var units
var map_layer_back
var map_layer_front
var action_layer
var bag
var random_tile

var mouse_dragging = false
var pos
var game_size
var scale
var root
var camera
var theme

var shake_timer = Timer.new()
var shakes = 0
export var shakes_max = 5
export var shake_time = 0.25
export var shake_boundary = 5
var shake_initial_position

var current_player = 0

const GEN_GRASS = 6
const GEN_FLOWERS = 3
const GEN_STONES = 6
const GEN_SNOW_PARTICLES = 5

var map_file = load('res://scripts/services/map_file_handler.gd').new()
var campaign
var used_tiles_list = []

var tileset
var map_movable = preload('res://terrain/tilesets/summer_movable.xscn')
var map_non_movable = preload('res://terrain/tilesets/summer_non_movable.xscn')
var wave = preload('res://terrain/wave.xscn')
var underground_rock = preload('res://terrain/underground.xscn')

var map_city_small = [
    preload('res://terrain/city/summer/city_small_1.xscn'),
    preload('res://terrain/city/summer/city_small_2.xscn'),
    preload('res://terrain/city/summer/city_small_3.xscn'),
    preload('res://terrain/city/summer/city_small_4.xscn'),
    preload('res://terrain/city/summer/city_small_5.xscn'),
    preload('res://terrain/city/summer/city_small_6.xscn')
    ]
var map_city_big = [
    preload('res://terrain/city/summer/city_big_1.xscn'),
    preload('res://terrain/city/summer/city_big_2.xscn'),
    preload('res://terrain/city/summer/city_big_3.xscn'),
    preload('res://terrain/city/summer/city_big_4.xscn')
    ]
var map_statue = preload('res://terrain/city/summer/city_statue.xscn')
var map_buildings = [
    preload('res://buildings/bunker_blue.xscn'),
    preload('res://buildings/bunker_red.xscn'),
    preload('res://buildings/barrack.xscn'),
    preload('res://buildings/factory.xscn'),
    preload('res://buildings/airport.xscn'),
    preload('res://buildings/tower.xscn'),
    preload('res://buildings/fence.xscn')
]

var map_units = [
    preload('res://units/soldier_blue.xscn'),
    preload('res://units/tank_blue.xscn'),
    preload('res://units/helicopter_blue.xscn'),
    preload('res://units/soldier_red.xscn'),
    preload('res://units/tank_red.xscn'),
    preload('res://units/helicopter_red.xscn')
]

var map_civilians = [
    preload('res://units/civilians/old_woman.tscn'),
    preload('res://units/civilians/protest_guy.tscn'),
    preload('res://units/civilians/protest_guy2.tscn'),
    preload('res://units/civilians/refugee.tscn'),
    preload('res://units/civilians/refugee2.tscn')
]

var waypoint = preload('res://maps/waypoint.tscn')

var is_dead = false

var should_do_awesome_explosions = false
var awesome_explosions_interval = 10
var awesome_explosions_interval_counter = 0


func do_awesome_cinematic_pan():
    self.set_map_pos_global(Vector2(self.sX - 1, self.sY))

func do_awesome_random_explosions():
    if not self.should_do_awesome_explosions:
        return
    var root_tree = self.root.get_tree()
    var all_units = root_tree.get_nodes_in_group("units")
    if all_units.size() == 0:
        return
    randomize()
    var unit = all_units[randi() % all_units.size()]
    if unit.die:
        return
    var stats = unit.get_stats()
    stats.life -= 5
    unit.set_stats(stats)
    if stats.life < 0:
        var field = self.root.bag.abstract_map.get_field(unit.get_pos_map())
        self.root.bag.controllers.action_controller.play_destroy(field)
        self.root.bag.controllers.action_controller.destroy_unit(field)
        self.root.bag.controllers.action_controller.collateral_damage(unit.get_pos_map())
    else:
        unit.show_explosion()

func move_to(target):
    if not mouse_dragging:
        self.camera.target = target;

func set_map_pos_global(position):
    self.camera.set_pos(position)

func set_map_pos(position):
    self.game_size = self.root.get_size()
    position = self.terrain.map_to_world(position*Vector2(-1,-1)) + Vector2(self.game_size.x/(2*self.scale.x), self.game_size.y/(2*self.scale.y))
    self.set_map_pos_global(position)

func move_to_map(target):
    self.camera.move_to_map(target)

func generate_map():
    var temp = null
    var temp2 = null
    var terrain_under_building = null
    var cells_to_change = []
    var cell
    randomize()
    self.used_tiles_list = []

    #map elements count
    var city_small_elements_count = map_city_small.size()
    var city_big_elements_count = map_city_big.size()
    var neigbours = 0

    for x in range(self.bag.abstract_map.MAP_MAX_X):
        for y in range(self.bag.abstract_map.MAP_MAX_Y):

            var terrain_cell = terrain.get_cell(x, y)
            # underground
            if terrain_cell > -1:
                self.generate_underground(x, y)
            else:
                self.generate_wave(x, y)
                continue

            self.used_tiles_list.append(Vector2(x, y))

            if terrain_cell == self.tileset.TERRAIN_PLAIN or terrain_cell == self.tileset.TERRAIN_DIRT:
                # bridges
                neigbours = count_neighbours_in_binary(x, y, [-1])

                if neigbours == 10:
                    cells_to_change.append({x=x, y=y, type=55})
                    temp = null
                elif neigbours == 20:
                    cells_to_change.append({x=x, y=y, type=56})
                    temp = null
                elif not terrain_cell == self.tileset.TERRAIN_DIRT:
                    # plain
                    cells_to_change.append({x=x, y=y, type=1})
                    # grass, flowers, log
                    if ( randi() % 10 ) <= GEN_GRASS:
                        temp = map_movable.instance()
                        temp.set_frame(randi()%3)
                    if ( randi() % 10 ) <= GEN_FLOWERS:
                        temp2 = map_movable.instance()
                        temp2.set_frame(8 + (randi()%8))
                else:
                    # dirt
                    cells_to_change.append({x=x, y=y, type=0})
                    if ( randi() % 10 ) <= GEN_STONES:
                        temp = map_movable.instance()
                        temp.set_frame(16 + (randi()%8))
            if temp:
                temp.set_pos(terrain.map_to_world(Vector2(x, y)))
                map_layer_back.add_child(temp)
                temp = null
            if temp2:
                temp2.set_pos(terrain.map_to_world(Vector2(x, y)))
                map_layer_back.add_child(temp2)
                temp2 = null

            # forest
            if terrain_cell == self.tileset.TERRAIN_FOREST:
                temp = map_non_movable.instance()
                temp.set_frame(randi()%10)
                cells_to_change.append({x=x, y=y, type=1})

            # mountains
            if terrain_cell == self.tileset.TERRAIN_MOUNTAINS:
                temp = map_non_movable.instance()
                temp.set_frame(11 + (randi()%2))
                if randi()%10 < GEN_SNOW_PARTICLES :
                    temp.particle_enabled = true;
                cells_to_change.append({x=x, y=y, type=1})

            # city
            if terrain_cell == self.tileset.TERRAIN_CITY || terrain_cell == self.tileset.TERRAIN_CITY_DESTROYED:
                # have road near or have less than 5 neighbours
                if count_neighbours(x,y,[self.tileset.TERRAIN_ROAD,self.tileset.TERRAIN_DIRT_ROAD, self.tileset.TERRAIN_BRIDGE, self.tileset.TERRAIN_RIVER]) > 0 or count_neighbours(x,y,[self.tileset.TERRAIN_CITY]) < 5:
                    temp = map_city_small[randi() % city_small_elements_count].instance()
                else:
                    # no roads and not alone
                    temp = map_city_big[randi() % city_big_elements_count].instance()
                if terrain_cell == self.tileset.TERRAIN_CITY_DESTROYED:
                    temp.set_damage()
                terrain_under_building = 9

            # special buildings
            if terrain_cell == self.tileset.TERRAIN_STATUE:
                temp = map_statue.instance()
                terrain_under_building = 9

            if terrain_cell == self.tileset.TERRAIN_SPAWN:
                cells_to_change.append({x=x, y=y, type=13})

            # concrete
            if terrain_cell == self.tileset.TERRAIN_CONCRETE:
                if randi() % 10 > 5:
                    random_tile = 3
                else:
                    random_tile = 4
                cells_to_change.append({x=x, y=y, type=random_tile})

            # military buildings

            if terrain_cell == self.tileset.TERRAIN_HQ_BLUE: # HQ blue
                temp = map_buildings[0].instance()
                terrain_under_building = 11
            if terrain_cell == self.tileset.TERRAIN_HQ_RED: # HQ red
                temp = map_buildings[1].instance()
                terrain_under_building = 12
            if terrain_cell == self.tileset.TERRAIN_BARRACKS_FREE: # barrack
                temp = map_buildings[2].instance()
                terrain_under_building = 10
            if terrain_cell == self.tileset.TERRAIN_FACTORY_FREE: # factory
                temp = map_buildings[3].instance()
                terrain_under_building = 10
            if terrain_cell == self.tileset.TERRAIN_AIRPORT_FREE: # airport
                temp = map_buildings[4].instance()
                terrain_under_building = 10
            if terrain_cell == self.tileset.TERRAIN_TOWER_FREE: # tower
                temp = map_buildings[5].instance()
                terrain_under_building = 10
            if terrain_cell == self.tileset.TERRAIN_BARRACKS_RED: # barrack
                temp = map_buildings[2].instance()
                temp.player = 1
                terrain_under_building = 12
            if terrain_cell == self.tileset.TERRAIN_FACTORY_RED: # factory
                temp = map_buildings[3].instance()
                temp.player = 1
                terrain_under_building = 12
            if terrain_cell == self.tileset.TERRAIN_AIRPORT_RED: # airport
                temp = map_buildings[4].instance()
                temp.player = 1
                terrain_under_building = 12
            if terrain_cell == self.tileset.TERRAIN_TOWER_RED: # tower
                temp = map_buildings[5].instance()
                temp.player = 1
                terrain_under_building = 12
            if terrain_cell == self.tileset.TERRAIN_BARRACKS_BLUE: # barrack
                temp = map_buildings[2].instance()
                temp.player = 0
                terrain_under_building = 11
            if terrain_cell == self.tileset.TERRAIN_FACTORY_BLUE: # factory
                temp = map_buildings[3].instance()
                temp.player = 0
                terrain_under_building = 11
            if terrain_cell == self.tileset.TERRAIN_AIRPORT_BLUE: # airport
                temp = map_buildings[4].instance()
                temp.player = 0
                terrain_under_building = 11
            if terrain_cell == self.tileset.TERRAIN_TOWER_BLUE: # tower
                temp = map_buildings[5].instance()
                temp.player = 0
                terrain_under_building = 11
            if terrain_cell == self.tileset.TERRAIN_FENCE: # fence
                temp = map_buildings[6].instance()
                terrain_under_building = 10

            if temp:
                self.attach_object(Vector2(x,y), temp)

                if temp.group == 'building':
                    temp.claim(temp.player, 0)
                temp = 1
                if terrain_under_building == null:
                    if count_neighbours(x,y,[0]) >= count_neighbours(x,y,[1]):
                        temp = 0
                    else:
                        temp = 1
                else:
                    temp = terrain_under_building

                cells_to_change.append({x=x, y=y, type=temp})
                temp = null

            # roads
            if terrain_cell == self.tileset.TERRAIN_ROAD: # city road
                cells_to_change.append({x=x, y=y, type=self.build_sprite_path(x, y, [self.tileset.TERRAIN_ROAD, self.tileset.TERRAIN_BRIDGE])})
            if terrain_cell == self.tileset.TERRAIN_DIRT_ROAD: # dirt road
                cells_to_change.append({x=x, y=y ,type=self.build_sprite_path(x ,y, [self.tileset.TERRAIN_DIRT_ROAD, self.tileset.TERRAIN_BRIDGE])})
            if terrain_cell == self.tileset.TERRAIN_RIVER: # river
                cells_to_change.append({x=x, y=y, type=self.build_sprite_path(x, y, [self.tileset.TERRAIN_RIVER, self.tileset.TERRAIN_BRIDGE])})
            if terrain_cell == self.tileset.TERRAIN_BRIDGE: # bridge
                cells_to_change.append({x=x, y=y, type=self.build_sprite_path(x, y, [self.tileset.TERRAIN_BRIDGE, self.tileset.TERRAIN_RIVER])})

            if units.get_cell(x,y) > -1:
                self.spawn_unit(x,y,units.get_cell(x,y))

            terrain_under_building = null

    for cell in cells_to_change:
        if(cell.type > -1):
            terrain.set_cell(cell.x,cell.y,cell.type)
    self.connect_fences()
    units.hide()

    self.bag.fog_controller.clear_fog()
    return

func attach_object(position, object):
    object.set_pos(terrain.map_to_world(position))
    map_layer_front.add_child(object)
    self.find_spawn_for_building(position.x, position.y, object)

func connect_fences():
    for fence in get_tree().get_nodes_in_group("terrain_fence"):
        fence.connect_with_neighbours()

func count_neighbours(x, y, type):
    var counted = 0
    var tiles = 1

    for cx in range(x-tiles, x+tiles+1):
        for cy in range(y-tiles, y+tiles+1):
            for t in type:
                if terrain.get_cell(cx,cy) == t:
                    counted = counted + 1

    return counted

func count_neighbours_in_binary(x, y, type):
    var counted = 0

    if terrain.get_cell(x, y-1) in type:
        counted += 2
    if terrain.get_cell(x+1, y) in type:
        counted += 4
    if terrain.get_cell(x, y+1) in type:
        counted += 8
    if terrain.get_cell(x-1, y) in type:
        counted += 16

    return counted

func find_spawn_for_building(x, y, building):
    if building.group != "building":
        return
    if building.can_spawn == false:
        return

    var acceptable_tiles = [
        self.tileset.TERRAIN_PLAIN,
        self.tileset.TERRAIN_DIRT,
        self.tileset.TERRAIN_CONCRETE,
        self.tileset.TERRAIN_ROAD,
        self.tileset.TERRAIN_DIRT_ROAD,
        self.tileset.TERRAIN_RIVER,
        self.tileset.TERRAIN_BRIDGE,
        self.tileset.TERRAIN_SPAWN,
    ]

    self.look_for_spawn(x, y, 1, 0, building)
    self.look_for_spawn(x, y, 0, 1, building)
    self.look_for_spawn(x, y, -1, 0, building)
    self.look_for_spawn(x, y, 0, -1, building)

    var current_spawn = terrain.get_cell(building.spawn_point.x, building.spawn_point.y)
    for acceptable_tile in acceptable_tiles:
        if current_spawn == acceptable_tile:
            return

    self.look_for_spawn(x, y, 1, 0, building, acceptable_tiles)
    self.look_for_spawn(x, y, 0, 1, building, acceptable_tiles)
    self.look_for_spawn(x, y, -1, 0, building, acceptable_tiles)
    self.look_for_spawn(x, y, 0, -1, building, acceptable_tiles)


func look_for_spawn(x, y, offset_x, offset_y, building, acceptable_tiles = null):
    var cell = terrain.get_cell(x + offset_x, y + offset_y)
    if acceptable_tiles == null:
        acceptable_tiles = [self.tileset.TERRAIN_SPAWN]
    for acceptable_tile in acceptable_tiles:
        if cell == acceptable_tile:
            building.spawn_point_position = Vector2(offset_x, offset_y)
            building.spawn_point = Vector2(x + offset_x, y + offset_y)

func build_sprite_path(x, y, type):
    var neighbours

    # big bridge
    if type[0] == self.tileset.TERRAIN_ROAD or type[0] == self.tileset.TERRAIN_DIRT_ROAD:
        neighbours = count_neighbours_in_binary(x, y, [-1])
        if neighbours == 10:
            return 55
        if neighbours == 20:
            return 56

    # river bridge
    if type[0] == self.tileset.TERRAIN_BRIDGE:
        neighbours = count_neighbours_in_binary(x, y, [self.tileset.TERRAIN_RIVER])
        if neighbours == 10:
            return 31
        if neighbours == 20:
            return 30

    neighbours = count_neighbours_in_binary(x, y, type)

    # road
    if type[0] == self.tileset.TERRAIN_ROAD:
        if neighbours in [10,2,8]:
            return 19
        if neighbours in [20,16,4]:
            return 20
        if neighbours == 24:
            return 21
        if neighbours == 12:
            return 22
        if neighbours == 18:
            return 23
        if neighbours == 6:
            return 24
        if neighbours == 26:
            return 25
        if neighbours == 28:
            return 26
        if neighbours == 14:
            return 27
        if neighbours == 22:
            return 28
        if neighbours == 30:
            return 29

    # coutry road
    if type[0] == self.tileset.TERRAIN_DIRT_ROAD:
        if neighbours in [10,2,8]:
            return 36
        if neighbours in [20,16,4]:
            return 37
        if neighbours == 24:
            return 38
        if neighbours == 12:
            return 39
        if neighbours == 18:
            return 40
        if neighbours == 6:
            return 41
        if neighbours == 26:
            return 42
        if neighbours == 28:
            return 43
        if neighbours == 14:
            return 44
        if neighbours == 22:
            return 45
        if neighbours == 30:
            return 46

    # road mix
    if type[0] == 16:
        if neighbours == 2:
            return 32
        if neighbours == 16:
            return 33
        if neighbours == 8:
            return 34
        if neighbours == 4:
            return 35

    # river
    if type[0] == self.tileset.TERRAIN_RIVER:
        if neighbours in [10,2,8]:
            if randi() % 4 > 2:
                return 47
            else:
                return 53
        if neighbours in [20,16,4]:
            if randi() % 4 > 2:
                return 48
            else:
                return 54
        if neighbours == 24:
            return 49
        if neighbours == 12:
            return 50
        if neighbours == 18:
            return 51
        if neighbours == 6:
            return 52

    # nothing to change
    return false

func spawn_unit(x, y, type):
    var temp
    var new_x
    var new_y
    var MOVE_OFFSET = 32
    var MAX_CIVILIANS_ON_TILE = 6

    if type == 6:
        for civil in range(MAX_CIVILIANS_ON_TILE):
            temp = map_civilians[randi() % map_civilians.size()].instance()
            new_x = (randi() % MOVE_OFFSET) - (MOVE_OFFSET/2)
            new_y = (randi() % MOVE_OFFSET) - (MOVE_OFFSET/2)
            temp.set_pos(terrain.map_to_world(Vector2(x,y)) + Vector2(new_x, new_y))
            map_layer_front.add_child(temp)
    else:
        temp = map_units[type].instance()
        temp.set_pos(terrain.map_to_world(Vector2(x,y)))
        temp.position_on_map = Vector2(x,y)
        map_layer_front.add_child(temp)
    return temp

func generate_underground(x, y):
    var temp = null
    var neighbours = count_neighbours_in_binary(x, y, [-1])

    temp = underground_rock.instance()
    temp.set_frame(0)
    if neighbours in [10]:
        temp.set_frame(1)
    if neighbours in [20]:
        temp.set_frame(2)
    temp.set_pos(terrain.map_to_world(Vector2(x+1,y+1)))
    underground.add_child(temp)
    temp = null

func generate_wave(x, y):
    var generate = false
    var temp = null
    var waves_range = 4

    for cx in range(x-waves_range, x+waves_range+1):
        for cy in range(y-waves_range, y+waves_range+1):
            if terrain.get_cell(cx, cy) > -1:
                generate = true

    if generate:
        temp = wave.instance()
        temp.set_pos(terrain.map_to_world(Vector2(x+1,y+1)))
        underground.add_child(temp)
        temp = null
        return true

    return false

func set_default_zoom():
    self.scale = (Vector2(2, 2))

func get_map_data_as_array():
    var temp_data = []
    var temp_terrain = -1
    var temp_unit = -1

    for x in range(self.bag.abstract_map.MAP_MAX_X):
        for y in range(self.bag.abstract_map.MAP_MAX_Y):
            if terrain.get_cell(x, y) > -1:
                temp_terrain = terrain.get_cell(x, y)

            if units.get_cell(x, y) > -1:
                temp_unit = units.get_cell(x, y)

            if temp_terrain > -1 or temp_unit > -1:
                temp_data.append({
                    x=x,y=y,
                    terrain=temp_terrain,
                    unit=temp_unit
                })

            temp_terrain = -1
            temp_unit = -1

    return temp_data

func save_map(file_name):
    var temp_data = {
        'tiles' : self.get_map_data_as_array(),
        'theme' : self.theme
    }

    file_name = str(file_name)

    if self.check_file_name(file_name):
        self.store_map_in_binary_file(file_name, temp_data)
        self.store_map_in_plain_file(file_name, temp_data)
        return true
    else:
        return false

func store_map_in_binary_file(file_name, data):
    var file_path = "user://" + file_name + ".map"
    map_file.write(file_path, data)
    if file_name != "restore_map":
        self.root.bag.map_list.store_map(file_name)
        self.root.bag.controllers.menu_controller.update_custom_maps_count_label()

func store_map_in_plain_file(file_name, data):
    var file_path = "user://" + file_name + ".gd"
    map_file.write_as_plain_file(file_path, data)

func check_file_name(name):
    # we need to check here for unusual charracters
    # and trim spaces, convert to lower case etc
    # allowed: [a-z] and "-"
    # and can not name 'settings' !!!
    if name == "" || name == "settings":
        return false

    var validator = RegEx.new()
    validator.compile("^([a-zA-Z0-9-_]*)$")
    validator.find(name)
    var matches = validator.get_captures()

    if matches[1] != name:
        return false

    return true

func load_map(file_name, is_remote = false, switch_tileset=true):
    if self.map_file.load_data_from_file(file_name, is_remote):
        if switch_tileset:
            self.switch_to_tileset(self.map_file.get_theme())
        self.fill_map_from_data_array(self.map_file.get_tiles())
        self.theme = self.map_file.get_theme()
        # TODO [waypoints] - add building waypoints
        return true
    return false

func load_campaign_map(file_name):
    var campaign_map = self.campaign.get_map_data(file_name)
    self.fill_map_from_data_array(campaign_map.map_data)

func fill_map_from_data_array(data):
    var cell
    self.init_nodes()
    if not self.show_blueprint:
        underground.clear()
    terrain.clear()
    units.clear()
    for cell in data:
        if cell.terrain > -1:
            terrain.set_cell(cell.x, cell.y, cell.terrain)

        if cell.unit > -1:
            units.set_cell(cell.x, cell.y, cell.unit)
    units.raise()

func fill(width, height):
    var offset_x = 0
    var offset_y = 0

    terrain.clear()
    units.clear()
    offset_x = (self.bag.abstract_map.MAP_MAX_X * 0.5) - (width * 0.5)
    offset_y = (self.bag.abstract_map.MAP_MAX_Y * 0.5) - (height * 0.5)

    for x in range(width):
        for y in range(height):
            terrain.set_cell(x+offset_x, y+offset_y, 0)

func clear_layer(layer):
    if layer == 0:
        self.units.clear()
        self.terrain.clear()
    if layer == 1:
        self.units.clear()

func init_background():
    for x in range(self.bag.abstract_map.MAP_MAX_X):
        for y in range(self.bag.abstract_map.MAP_MAX_Y):
            self.underground.set_cell(x,y,3)

func init_nodes():
    self.underground = self.get_node("underground")
    self.terrain = self.get_node("terrain")
    self.units = terrain.get_node("units")
    self.map_layer_back = terrain.get_node("back")
    self.map_layer_front = terrain.get_node("front")
    self.action_layer = terrain.get_node("actions")

func _ready():
    root = get_node("/root/game")
    self.init_nodes()
    self.bag = self.root.bag
    self.bag.fog_controller.init_node(self, terrain)
    self.camera = self.bag.camera
    self.tileset = self.bag.map_tiles

    if root:
        scale = self.camera.get_scale()
    else:
        self.set_default_zoom()
    pos = terrain.get_pos()

    self.shake_timer.set_wait_time(shake_time / shakes_max)
    self.shake_timer.set_one_shot(true)
    self.shake_timer.set_autostart(false)
    self.shake_timer.connect('timeout', self, 'do_single_shake')
    self.add_child(shake_timer)

    # where the magic happens
    if show_blueprint:
        self.init_background()
    else:
        self.generate_map()

    set_process_input(true)

func shake_camera():
    if root.settings['shake_enabled'] and not mouse_dragging:
        self.shakes = 0
        shake_initial_position = terrain.get_pos()
        self.do_single_shake()

func do_single_shake():
    var target
    if shakes < shakes_max:
        var direction_x = randf()
        var direction_y = randf()
        var distance_x = randi() % shake_boundary
        var distance_y = randi() % shake_boundary
        if direction_x <= 0.5:
            distance_x = -distance_x
        if direction_y <= 0.5:
            distance_y = -distance_y

        pos = Vector2(shake_initial_position) + Vector2(distance_x, distance_y)
        target = pos
        underground.set_pos(pos)
        terrain.set_pos(pos)
        self.shakes += 1
        self.shake_timer.start()
    else:
        pos = shake_initial_position
        target = pos
        self.underground.set_pos(shake_initial_position)
        self.terrain.set_pos(shake_initial_position)

func switch_to_tileset(tileset):
    self.get_node('terrain').set_tileset(self.bag.tileset_handler.available_tilesets[tileset])
    self.map_movable = self.bag.tileset_handler.available_objects[tileset]['movable']
    self.map_non_movable = self.bag.tileset_handler.available_objects[tileset]['non-movable']
    self.map_city_small = self.bag.tileset_handler.available_city[tileset]['small']
    self.map_city_big = self.bag.tileset_handler.available_city[tileset]['large']
    self.map_statue = self.bag.tileset_handler.available_city[tileset]['statue']

func _init_bag(bag):
    self.bag = bag
    self.campaign = bag.campaign

