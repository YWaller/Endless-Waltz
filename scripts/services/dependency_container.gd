var root

var controllers = preload("res://scripts/controllers/controllers.gd").new()

var language = preload("res://scripts/language.gd").new()
var map_list = preload("res://scripts/maps/map_list.gd").new()
var campaign = preload("res://maps/campaign.gd").new()
var abstract_map = preload('res://scripts/abstract_map.gd').new()
var match_state = preload("res://scripts/match_state.gd").new()
var demo_mode = preload("res://scripts/demo_mode.gd").new()
var camera = preload("res://scripts/camera.gd").new()
var hud_dead_zone = preload("res://scripts/services/hud_dead_zone.gd").new()
var workshop_dead_zone = preload("res://scripts/services/workshop_dead_zone.gd").new()
var menu_back = preload("res://scripts/menu_back.gd").new()

var action_map = preload('res://scripts/action_map.gd').new()
var battle_controller = preload('res://scripts/battle_controller.gd').new()
var movement_controller = preload('res://scripts/movement_controller.gd').new()
var ap_gain = preload("res://gui/hud/ap_gain.gd").new()
var map_tiles = preload("res://scripts/maps/map_tiles.gd").new()
var positions = preload('res://scripts/services/positions.gd').new()
var migrations = preload("res://scripts/migrations/migrations.gd").new()
var timers = preload("res://scripts/timers.gd").new()
var menu_background_map = preload("res://maps/menu_map_background.gd").new()
var helpers = preload("res://scripts/services/helpers.gd").new()
var fog_controller = preload('res://scripts/fog_controller.gd').new()
var processing = preload('res://scripts/processing.gd').new()
var file_handler = preload('res://scripts/services/file_handler.gd').new()

var map_picker = preload("res://gui/hud/map_picker.gd").new()
var skirmish_setup = preload("res://gui/hud/skirmish_setup_panel.gd").new()
var confirm_popup = preload("res://scripts/popups/confirm.gd").new()
var prompt_popup = preload("res://scripts/popups/prompt.gd").new()
var message_popup = preload("res://scripts/popups/message.gd").new()
var message_big_popup = preload("res://scripts/popups/big_message.gd").new()
var gamepad_popup = preload("res://scripts/popups/gamepad_info.gd").new()

var resolution = preload('res://scripts/services/resolution.gd').new()
var gamepad = preload('res://scripts/gamepad_input.gd').new()
var pandora = preload('res://scripts/pandora_input.gd').new()
var unit_switcher = preload('res://scripts/unit_switcher.gd').new()

var online_request = preload('res://scripts/online/request.gd').new()
var online_request_async = preload('res://scripts/online/request_async.gd').new()
var online_player = preload('res://scripts/online/player.gd').new()
var online_maps = preload('res://scripts/online/maps.gd').new()
var online_multiplayer = preload('res://scripts/online/multiplayer.gd').new()
var tileset_handler = preload('res://scripts/services/tileset_handler.gd').new()
var script_player = preload('res://scripts/services/script_player.gd').new()
var battle_stats = preload("res://scripts/battle_stats.gd").new()
var game_conditions = preload("res://scripts/game_conditions.gd").new()
var ai = preload("res://scripts/ai/ai.gd").new()
var perform = preload("res://scripts/ai/perform.gd").new()
var logger = preload('res://scripts/services/logger.gd').new()
var storyteller = preload("res://scripts/storyteller/storyteller.gd").new()
var waypoint_factory = preload("res://scripts/objects/waypoints/waypoint_factory.gd").new()

var saving = null
var workshop = null

func init_root(root_node):
    self.root = root_node

    self.language._init_bag(self)
    self.migrations._init_bag(self)
    self.map_list._init_bag(self)
    self.campaign.load_campaign_progress()

    if Globals.get('tof/enable_workshop'):
        self.controllers.workshop_gui_controller = preload("res://scripts/controllers/workshop_gui_controller.gd").new()
        self.workshop = preload("res://gui/workshop/workshop.xscn").instance()
        self.controllers.workshop_gui_controller.init_root(root_node)
        self.workshop.init(self.root)

    self.controllers.campaign_menu_controller.init_root(root_node)
    self.controllers.hud_panel_controller.init_root(root_node)
    self.controllers.workshop_menu_controller.init_root(root_node)
    self.controllers.background_map_controller.init_root(root_node)
    self.controllers.online_menu_controller._init_bag(self)

    self.menu_back._init_bag(self)
    self.hud_dead_zone.init_root(root_node)
    self.workshop_dead_zone.init_root(root_node)

    self.positions._init_bag(self)
    self.demo_mode._init_bag(self)
    self.action_map._init_bag(self)
    self.ap_gain._init_bag(self)

    self.unit_switcher._init_bag(self)
    self.camera._init_bag(self)
    self.timers._init_bag(self)
    self.map_picker._init_bag(self)
    self.confirm_popup._init_bag(self)
    self.prompt_popup._init_bag(self)
    self.message_popup._init_bag(self)
    self.message_big_popup._init_bag(self)
    self.gamepad_popup._init_bag(self)
    self.skirmish_setup._init_bag(self)
    self.fog_controller._init_bag(self)
    self.resolution._init_bag(self)
    self.gamepad._init_bag(self)
    self.pandora._init_bag(self)

    self.processing._init_bag(self)
    self.processing.ready = true
    self.processing.register(self.camera)
    self.processing.register(self.gamepad)

    self.online_request._init_bag(self)
    self.online_request_async._init_bag(self)
    self.online_player._init_bag(self)
    self.online_maps._init_bag(self)
    self.online_multiplayer._init_bag(self)
    self.tileset_handler._init_bag(self)
    self.script_player._init_bag(self)
    self.game_conditions._init_bag(self)
    self.ai.pathfinder._init_bag(self)
    self.ai._init_bag(self)
    self.perform._init_bag(self)
    self.waypoint_factory._init_bag(self)

    self.storyteller._init_bag(self)

    if Globals.get('tof/enable_save_load'):
        self.saving = load('res://scripts/saving.gd').new()
        self.saving._init_bag(self)


