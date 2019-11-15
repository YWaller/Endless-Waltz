
var root_node
var root_tree
var ysort
var damage_layer
var selector
var active_field = null
var active_indicator = preload('res://gui/selector.xscn').instance()
var hud_controller = preload('res://scripts/hud_controller.gd').new()
var status = load('res://scripts/controllers/action_status.gd').new()
var sound_controller
var pathfinding
var demo_timer
var positions
var actual_movement_tiles = {}

var current_player = 0
var player_ap = [0,0]
var turn = 1
var title
var camera
var is_cpu_player
var start_ap_for_current_turn = 0

var game_ended = false
var exploding = false

var interaction_indicators = {
    'bl' : { 'offset' : Vector2(0, 1), 'indicator' : null },
    'br' : { 'offset' : Vector2(1, 0), 'indicator' : null },
    'tl' : { 'offset' : Vector2(-1, 0), 'indicator' : null },
    'tr' : { 'offset' : Vector2(0, -1), 'indicator' : null }
}

const BREAK_EVENT_LOOP = 1
const AP_HANDICAP = 0.8

func reset():
    self.root_tree = null
    self.ysort = null
    self.damage_layer = null
    self.selector = null
    self.active_field = null
    self.sound_controller = null
    self.pathfinding = null
    self.demo_timer = null
    self.positions = null
    self.current_player = 0
    self.is_cpu_player = false
    self.player_ap = [0, 0]
    self.turn = 1
    self.title = null
    self.camera = null
    self.game_ended = false
    self.exploding = false

func init_root(root, map, hud):
    self.reset()
    self.root_node = root
    self.root_tree = self.root_node.get_tree()

    self.root_node.bag.abstract_map.reset()
    self.root_node.bag.abstract_map.init_map(map)
    self.root_node.bag.action_map.init_map(map)
    self.root_node.bag.battle_stats.reset()

    camera = root.scale_root
    ysort = map.get_node('terrain/front')
    damage_layer = map.get_node('terrain/destruction')
    selector = root.selector
    self.import_objects()
    hud_controller.init_root(root, self, hud)
    hud_controller.set_turn(turn)

    self.positions = self.root_node.bag.positions
    self.positions.bootstrap()
    self.positions.get_player_bunker_position(self.current_player)

    sound_controller = root.sound_controller
    var interaction_template = load('res://gui/movement.xscn')
    for direction in self.interaction_indicators:
        self.interaction_indicators[direction]['indicator'] = interaction_template.instance()
        ysort.add_child(self.interaction_indicators[direction]['indicator'])
        self.interaction_indicators[direction]['indicator'].hide()

    demo_timer = root_node.get_node("DemoTimer")

func refresh_abstract_map():
    self.root_node.bag.abstract_map.reset()
    self.root_node.bag.abstract_map.init_map(self.root_node.current_map)
    self.import_objects()

func set_active_field(position):
    var field = self.root_node.bag.abstract_map.get_field(position)
    self.clear_active_field()
    self.activate_field(field)
    self.move_camera_to_point(field.position)
    return field

func handle_action(position):
    if game_ended:
        return self.status.list[self.status.GAME_ENDED]

    var field = self.root_node.bag.abstract_map.get_field(position)
    if field.object == null:
        if active_field != null && active_field.object != null && field != active_field:
            if active_field.has_unit()  && self.is_movement_possible(field, active_field) && !field.is_empty() && self.has_ap():
                return self.move_unit(active_field, field)
            else:
                return self.clear_active_field()
    else:
        if field.has_terrain():
            return self.status.list[self.status.HAS_TERRAIN]

        if field.object.player == self.current_player:
            return self.__activate_field(field)
        else:
            if active_field != null && active_field.has_unit():
                return self.__handle_unit_actions(active_field, field)

    return self.status.list[self.status.UNEXPECTED]

func __activate_field(field):
    if (field.has_unit() || (field.has_building() && field.object.can_spawn)):
        self.activate_field(field)
    return self.status.list[self.status.ACTIVATE_FIELD]

func __handle_unit_actions(active_field, field):
    if self.has_ap() && active_field.is_adjacent(field):
        if field.has_unit():
            return self.handle_battle(active_field, field)
        elif active_field.object.type == 0 && field.has_building():
            if self.root_node.bag.movement_controller.can_move(active_field, field):
                return self.capture_building(active_field, field)
    else:
        return self.status.list[self.status.CANNOT_DO]

func capture_building(active_field, field):
    self.use_ap(field)

    if self.root_node.bag.match_state.is_multiplayer:
        self.root_node.bag.match_state.register_action_taken({'action': 'capture', 'who': [active_field.position.x, active_field.position.y], 'what': [field.position.x, field.position.y]})

    field.object.claim(self.current_player, self.turn)
    sound_controller.play('occupy_building')
    self.root_node.bag.ap_gain.update()
    if field.object.type == 4:
        active_field.object.take_all_ap()
    else:
        self.despawn_unit(active_field)
    self.root_node.bag.fog_controller.clear_fog()
    self.activate_field(field)

    self.root_node.bag.storyteller.register_story_event({
        'type' : 'claim',
        'details' : {
            'building' : field.object,
        }
    })

    #TODO - move it in handle
    if self.root_node.bag.game_conditions.check_win_conditions(field):
        return self.status.list[self.status.CAPTURE_AND_WIN]
    else:
        return self.status.list[self.status.CAPTURE]

func activate_field(field):
    self.clear_active_field()
    self.active_field = field
    if active_indicator != null and active_indicator.is_inside_tree():
        active_indicator.get_parent().remove_child(active_indicator)
    self.root_node.bag.abstract_map.tilemap.add_child(active_indicator)
    self.root_node.bag.abstract_map.tilemap.move_child(active_indicator, 0)
    var position = Vector2(self.root_node.bag.abstract_map.tilemap.map_to_world(field.position))
    position.y += 2
    active_indicator.set_pos(position)
    sound_controller.play('select')
    if not self.is_cpu_player:
        if field.has_unit():
            self.hud_controller.show_unit_card(field.object, self.current_player)
            self.add_movement_indicators(field)
        if field.has_building() && not self.is_cpu_player:
            field.object.spawn_field = self.root_node.bag.abstract_map.get_field(field.object.spawn_point)
            self.hud_controller.show_building_card(field.object, player_ap[self.current_player])

func clear_active_field():
    self.active_field = null
    if self.root_node.bag.abstract_map.tilemap.is_a_parent_of(active_indicator):
        self.root_node.bag.abstract_map.tilemap.remove_child(active_indicator)
    if not self.is_cpu_player:
        self.hud_controller.clear_unit_card()
        self.hud_controller.clear_building_card()
        self.root_node.bag.action_map.reset()
        self.hide_interaction_indicators()
    return self.status.list[self.status.CLEAR_ACTIVE_FIELD]

func add_movement_indicators(field):
    self.root_node.bag.action_map.reset()
    self.hide_interaction_indicators()
    if player_ap[self.current_player] > 0 && field.object.ap > 0 && not self.is_cpu_player && player_ap[self.current_player] >= 1:
        # calculating range
        var tiles_range = min(field.object.ap, player_ap[self.current_player])
        var first_action_range = max(0, field.object.ap - 1)
        self.actual_movement_tiles.clear()
        var tiles = self.root_node.bag.action_map.find_movement_tiles(field, tiles_range)

        for tile in tiles:
            self.actual_movement_tiles[tile] = tiles[tile]

        self.root_node.bag.action_map.mark_movement_tiles(field, tiles, first_action_range, self.current_player)
        self.add_interaction_indicators(field)

func add_interaction_indicators(field):
    var neighbour
    var indicator
    var indicator_position

    if player_ap[self.current_player] == 0:
        return

    for direction in self.interaction_indicators:
        indicator = self.interaction_indicators[direction]['indicator']
        indicator.hide()

        neighbour = self.root_node.bag.abstract_map.get_field(Vector2(field.position) + self.interaction_indicators[direction]['offset'])

        if neighbour.is_empty():
            continue

        indicator_position = Vector2(self.root_node.bag.abstract_map.tilemap.map_to_world(neighbour.position))

        if neighbour.has_attackable_enemy(field.object):
            self.__show_indicator(indicator, indicator_position + Vector2(1,1), "attack")
        elif neighbour.has_capturable_building(field.object) && self.root_node.bag.movement_controller.can_move(field, neighbour):
            self.__show_indicator(indicator, indicator_position, "enter")

func __show_indicator(indicator, position, type):
    indicator.set_pos(position)
    indicator.show()
    indicator.get_node('anim').play(type)

func hide_interaction_indicators():
    for direction in self.interaction_indicators:
        self.interaction_indicators[direction]['indicator'].hide()

func despawn_unit(field):
    ysort.remove_child(field.object)
    field.object.call_deferred("free")
    field.object.life = 0 #despawn bug
    field.object = null

func destroy_unit(field):
    field.object.die_after_explosion(ysort)
    field.object = null

func spawn_unit_from_active_building():
    if active_field == null:
        return
    var active_object = active_field.object
    if active_object == null || active_object.group != 'building' || active_object.can_spawn == false:
        return
    var spawn_point = self.root_node.bag.abstract_map.get_field(active_object.spawn_point)
    var required_ap = active_object.get_required_ap()
    if spawn_point.object == null && self.has_enough_ap(required_ap):
        if self.root_node.bag.match_state.is_multiplayer:
            self.root_node.bag.match_state.register_action_taken({'action': 'spawn', 'from': [active_field.position.x, active_field.position.y]})
        var unit = active_object.spawn_unit(current_player)
        ysort.add_child(unit)
        unit.set_pos_map(spawn_point.position)
        spawn_point.object = unit
        self.deduct_ap(required_ap)
        sound_controller.play_unit_sound(unit, sound_controller.SOUND_SPAWN)
        self.activate_field(spawn_point)
        self.move_camera_to_point(spawn_point.position)

        #gather stats
        self.root_node.bag.battle_stats.add_spawn(self.current_player)
        self.root_node.bag.fog_controller.clear_fog()
        self.root_node.bag.storyteller.register_story_event({
            'type' : 'deploy',
            'details' : {
                'building' : active_object,
                'unit' : unit
            }
        })
        return true

func import_objects():
    self.attach_objects(self.root_tree.get_nodes_in_group("units"))
    self.attach_objects(self.root_tree.get_nodes_in_group("buildings"))
    self.attach_objects(self.root_tree.get_nodes_in_group("terrain"))

func attach_objects(collection):
    for entity in collection:
        self.root_node.bag.abstract_map.get_field(entity.get_initial_pos()).object = entity

func end_turn():
    sound_controller.play('end_turn')
    if self.root_node.bag.match_state.is_multiplayer:
        self.multiplayer_end_turn()
    else:
        self.local_end_turn()

func local_end_turn():
    self.stats_set_time()
    self.root_node.bag.game_conditions.check_turn_cap()
    if self.game_ended:
        return

    var save = true
    if self.root_node.bag.match_state.is_multiplayer:
        save = false

    var is_current_cpu_player = root_node.settings['cpu_' + str(current_player)]

    if not is_current_cpu_player:
        self.root_node.bag.camera.store_position_for_player(current_player)

    if self.current_player == 0:
        self.switch_to_player(1, save)
    else:
        self.turn += 1
        self.switch_to_player(0, save)
        self.root_node.bag.storyteller.register_story_event({
            'type' : 'turn_end',
            'details' : {'turn' : self.turn - 1}
        })
    hud_controller.set_turn(turn)

    #gather stats
    self.root_node.bag.battle_stats.add_domination(self.current_player, self.positions.get_player_buildings(self.current_player).size())

func multiplayer_end_turn():
    self.stats_set_time()

    var is_current_cpu_player = root_node.settings['cpu_' + str(current_player)]

    if not is_current_cpu_player:
        self.root_node.bag.camera.store_position_for_player(current_player)

    if self.current_player == 0:
        self.switch_to_player(1, false)
    else:
        self.turn += 1
        self.switch_to_player(0, false)
    hud_controller.set_turn(turn)

    self.root_node.hud_controller.switch_cinematic_to_multiplayer()
    self.root_node.lock_for_cpu()
    self.root_node.bag.online_multiplayer.update_turn_state()

    self.root_node.bag.battle_stats.add_domination(self.current_player, self.positions.get_player_buildings(self.current_player).size())

func go_into_multiplayer_wait_mode():
    return

func move_camera_to_active_bunker():
    if self.root_node.bag.root.settings['camera_move_to_bunker']:
        var bunker_position = self.positions.get_player_bunker_position(current_player)
        if bunker_position != null:
            self.move_camera_to_point(bunker_position)
            self.root_node.move_selector_to_map_position(bunker_position)
    else:
        self.root_node.bag.camera.restore_position_for_player(current_player)

func move_camera_to_point(position):
    self.root_node.bag.abstract_map.map.move_to_map(position)

func in_game_menu_pressed():
    hud_controller.close_in_game_card()

func has_ap():
    if player_ap[current_player] > 0:
        return true
    sound_controller.play('no_moves')
    return false

func has_enough_ap(ap):
    if player_ap[current_player] >= ap:
        return true
    return false

func use_ap(field):
    var position = field.position
    var cost = 1
    if self.actual_movement_tiles.has(position):
        cost = self.actual_movement_tiles[position]
    self.deduct_ap(cost)

func is_movement_possible(field, active_field):
    #TODO hack for AI
    if self.is_cpu_player:
        if self.root_node.bag.match_state.is_multiplayer:
            return true
        else:
            return active_field.is_adjacent(field)

    var position = field.position
    if self.actual_movement_tiles.has(position):
        return true

    return false

func deduct_ap(ap):
    self.update_ap(player_ap[current_player] - ap)
    if self.player_ap[self.current_player] < 1:
        var units = self.positions.get_player_units(current_player)
        for unit in units.values():
            unit.force_no_ap_idle()

func update_ap(ap):
    player_ap[current_player] = ap
    hud_controller.update_ap(player_ap[current_player])
    if player_ap[current_player] == 0:
        hud_controller.warn_end_turn()

func refill_ap():
    self.positions.refresh_units()
    self.positions.refresh_buildings()

    var total_ap = player_ap[current_player]
    var buildings = self.positions.get_player_buildings(current_player)
    var bonus_ap = 0
    for building in buildings.values():
        bonus_ap = bonus_ap + building.bonus_ap

    if self.apply_handicap():
        bonus_ap = floor(bonus_ap * self.AP_HANDICAP)
    self.update_ap(total_ap + bonus_ap)

func show_bonus_ap():
    var buildings = self.positions.get_player_buildings(current_player)
    for building_pos in buildings:
        if buildings[building_pos].bonus_ap > 0 && not self.root_node.bag.fog_controller.is_fogged(building_pos):
            buildings[building_pos].show_floating_ap()

func switch_to_player(player, save_game=true):
    self.stats_start_time()
    self.clear_active_field()
    current_player = player
    self.is_cpu_player = root_node.settings['cpu_' + str(current_player)]

    self.reset_player_units(player)
    selector.set_player(player)
    self.root_node.bag.abstract_map.map.current_player = player
    self.root_node.bag.fog_controller.clear_fog()
    self.root_node.bag.ap_gain.update()
    self.root_node.bag.controllers.hud_panel_controller.info_panel.info_panel_set_current_team(player)
    self.hud_controller.set_current_team_label(player)
    if root_node.settings['cpu_' + str(player)]:
        if not self.root_node.bag.match_state.is_multiplayer:
            self.refill_ap()
            self.root_node.bag.perform.start_ai_timer()
            self.show_bonus_ap()
            self.start_ap_for_current_turn = self.player_ap[player]
            self.root_node.lock_for_cpu()
        self.move_camera_to_active_bunker()
    else:
        root_node.unlock_for_player()
        self.root_node.bag.controllers.hud_panel_controller.info_panel.end_button_enable()
        if save_game && self.root_node.bag.saving != null and not self.root_node.bag.match_state.is_multiplayer:
            self.root_node.bag.saving.save_state()
        self.refill_ap()
        if self.root_node.bag.match_state.is_multiplayer:
            self.root_node.bag.match_state.reset_actions_taken()
        if self.root_node.settings['tooltips_enabled']:
            hud_controller.show_in_game_card([], current_player)
        else:
            hud_controller.call_deferred("begin_player_turn")


func perform_ai_stuff():
    var success = false
    if self.is_cpu_player && player_ap[current_player] > 0:
        success = self.root_node.bag.ai.start_do_ai(current_player, player_ap[current_player])

    self.hud_controller.update_cpu_progress(player_ap[current_player], self.start_ap_for_current_turn)

    return player_ap[current_player] > 0 && success

func apply_handicap():
    if self.root_node.settings['easy_mode'] and not self.root_node.bag.match_state.is_multiplayer:
        if self.is_cpu_player && !(root_node.settings['cpu_1'] && root_node.settings['cpu_0']):
            return true

    return false

func reset_player_units(player):
    self.positions.refresh_units()
    var units = self.positions.get_player_units(player)
    var limit_ap = self.apply_handicap()
    for unit in units.values():
        unit.reset_ap(limit_ap)

func end_game(winning_player):
    if self.root_node.bag.match_state.is_multiplayer and not self.root_node.settings['cpu_' + str(winning_player)]:
        self.root_node.bag.online_multiplayer.end_game()
    self.clear_active_field()
    self.game_ended = true
    self.root_node.bag.perform.stop_ai_timer()
    if root_node.hud.is_hidden():
        root_node.hud.show()
    hud_controller.show_win(winning_player, self.root_node.bag.battle_stats.get_stats(), turn)
    selector.hide()
    if root_node.is_demo:
        demo_timer.reset(demo_timer.STATS)
        demo_timer.start()
    if self.root_node.bag.match_state.is_campaign() && winning_player > -1:
        if not self.root_node.settings['cpu_' + str(winning_player)]:
            var mission_num = self.root_node.bag.match_state.get_map_number()
            if mission_num > self.root_node.bag.campaign.get_campaign_progress():
                self.root_node.bag.campaign.update_campaign_progress(mission_num)
                self.root_node.bag.controllers.campaign_menu_controller.fill_mission_data(mission_num + 1)
                self.root_node.bag.controllers.menu_controller.update_campaign_progress_label()
    if not self.root_node.bag.match_state.is_campaign() and winning_player > -1 and not self.root_node.settings['cpu_' + str(winning_player)] and self.root_node.workshop_file_name != 'restore_map' and not self.root_node.is_remote:
        self.root_node.bag.map_list.mark_map_win(self.root_node.workshop_file_name)
    if not self.root_node.is_demo_mode() and not self.root_node.bag.match_state.is_multiplayer:
        self.root_node.bag.saving.invalidate_save_file()
    self.root_node.bag.match_state.reset()
    self.root_node.bag.timers.set_timeout(0.1, hud_controller.hud_end_game_missions_button, "grab_focus")

func play_destroy(field):
    sound_controller.play_unit_sound(field.object, sound_controller.SOUND_DIE)

func update_unit(field):
    if !self.is_cpu_player:
        hud_controller.update_unit_card(active_field.object)
        self.add_movement_indicators(active_field)

func move_unit(active_field, field):
    var action_cost = self.root_node.bag.movement_controller.DEFAULT_COST
    if !self.is_cpu_player && self.actual_movement_tiles.has(field.position):
        action_cost = self.actual_movement_tiles[field.position]

    if self.root_node.bag.movement_controller.move_object(active_field, field, action_cost):
        if self.root_node.bag.match_state.is_multiplayer:
            self.root_node.bag.match_state.register_action_taken({'action': 'move', 'from': [active_field.position.x, active_field.position.y], 'to': [field.position.x, field.position.y]})
        sound_controller.play_unit_sound(field.object, sound_controller.SOUND_MOVE)
        self.use_ap(field)
        self.activate_field(field)
        self.root_node.bag.fog_controller.clear_fog()
        #gather stats
        self.root_node.bag.battle_stats.add_moves(self.current_player)
        self.update_unit(self.active_field)

        self.root_node.bag.storyteller.register_story_event({
            'type' : 'move',
            'details' : {
                'who' : field.object,
                'where' : field.position
            }
        })

        return self.status.list[self.status.MOVE_UNIT]

    else:
        sound_controller.play('no_moves')
        return self.status.list[self.status.NO_MOVES]

func stats_start_time():
    self.root_node.bag.battle_stats.start_counting_time()

func stats_set_time():
    self.root_node.bag.battle_stats.set_counting_time(self.current_player)

func handle_battle(active_field, field):
    var markers
    if (self.root_node.bag.battle_controller.can_attack(active_field.object, field.object)):
        self.use_ap(field)

        sound_controller.play_unit_sound(field.object, sound_controller.SOUND_ATTACK)
        if self.root_node.bag.match_state.is_multiplayer:
            self.root_node.bag.match_state.register_action_taken({'action': 'attack', 'who': [active_field.position.x, active_field.position.y], 'whom': [field.position.x, field.position.y]})

        if (self.root_node.bag.battle_controller.resolve_fight(active_field.object, field.object)):
            markers = field.object.story_markers
            self.play_destroy(field)
            self.destroy_unit(field)
            self.update_unit(active_field)

            #gather stats
            self.root_node.bag.battle_stats.add_kills(current_player)
            self.collateral_damage(field.position)
            self.root_node.bag.storyteller.register_story_event({
                'type' : 'die',
                'details' : {
                    'killer' : active_field.object,
                    'victim' : markers
                }
            })
        else:
            sound_controller.play_unit_sound(field.object, sound_controller.SOUND_DAMAGE)
            field.object.show_explosion()
            self.update_unit(active_field)
            # defender can deal damage
            if self.root_node.bag.battle_controller.can_defend(field.object, active_field.object):
                if (self.root_node.bag.battle_controller.resolve_defend(active_field.object, field.object)):
                    markers = active_field.object.story_markers
                    self.play_destroy(active_field)
                    self.destroy_unit(active_field)
                    self.clear_active_field()

                    #gather stats
                    self.root_node.bag.battle_stats.add_kills(abs(current_player - 1))
                    self.collateral_damage(active_field.position)
                    self.root_node.bag.storyteller.register_story_event({
                        'type' : 'die',
                        'details' : {
                            'killer' : field.object,
                            'victim' : markers
                        }
                    })
                else:
                    sound_controller.play_unit_sound(field.object, sound_controller.SOUND_DAMAGE)
                    self.update_unit(active_field)
                    active_field.object.show_explosion()
        self.root_node.bag.fog_controller.clear_fog()
    else:
        sound_controller.play('no_attack')
        self.update_unit(active_field)

    return self.status.list[self.status.BATTLE]

func collateral_damage(center):
    var damage_chance = 0.5
    for mod in [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)] :
        if randf() <= damage_chance:
            self.damage_terrain(center + mod)

    var field = self.root_node.bag.abstract_map.get_field(center)
    if field.damage == null:
        field.add_damage(damage_layer)

func damage_terrain(position):
    var field = self.root_node.bag.abstract_map.get_field(position)
    if field == null || field.object == null || field.object.group != 'terrain':
        return

    field.object.set_damage()

func refresh_hud():
    hud_controller.set_turn(self.turn)
    hud_controller.update_ap(player_ap[current_player])

func switch_unit(direction):
    if not self.is_cpu_player:
        sound_controller.play('menu')
        var unit_pos = self.root_node.bag.unit_switcher.switch_unit(self.current_player, self.active_field, direction)
        if unit_pos != null :
            var unit_field = self.root_node.bag.abstract_map.get_field(unit_pos)
            self.activate_field(unit_field)

        if self.active_field != null:
            self.root_node.move_selector_to_map_position(self.active_field.position)
            self.move_camera_to_point(self.active_field.position)

