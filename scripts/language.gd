extends "res://scripts/bag_aware.gd"

var available_languages = []

func _initialize():
    self.available_languages = self.__get_available_languages()

func switch_to_next_language():
    var old_language = self.bag.root.settings['language']

    var old_lang_pos = self.available_languages.find(old_language)
    var new_lang_pos = ( old_lang_pos + 1 ) % self.available_languages.size()

    var new_language = self.available_languages[new_lang_pos]

    self.bag.root.settings['language'] = new_language
    TranslationServer.set_locale(new_language)
    self.bag.root.write_settings_to_file()

    self.reload_labels()
    self.bag.controllers.online_menu_controller.refreshed = false

func reload_labels():
    #MAIN MENU
    var menu = self.bag.controllers.menu_controller
    menu.manage_close_button()
    self.reload_button(menu.demo_button, 'LABEL_RUN_DEMO', 'Label1')
    self.reload_button(menu.settings_button, 'LABEL_SETTINGS')
    self.reload_button(menu.quit_button, 'LABEL_QUIT_GAME')
    self.reload_button(menu.campaign_button, 'LABEL_CAMPAIGN')
    self.reload_button(menu.play_button, 'LABEL_SKIRMISH')
    self.reload_button(menu.online_button, 'LABEL_ONLINE')
    self.reload_button(menu.workshop_button, 'LABEL_MAP EDITOR')
    menu.update_campaign_progress_label()
    menu.update_custom_maps_count_label()

    #TITLE SCREEN
    var title_screen = self.bag.controllers.menu_controller.get_node('middle/center/game_panel/under_logo')
    title_screen.get_node('copy').set_text(tr('LABEL_VERSION') + ' ' + self.bag.root.version_short + '-BETA')
    self.reload_label(title_screen.get_node('title3'), 'MSG_GAME_DESCRIPTION_1')
    self.reload_label(title_screen.get_node('title5'), 'MSG_GAME_DESCRIPTION_2')
    self.reload_label(title_screen.get_node('title4'), 'MSG_FREE_AS_FREEDOM')

    #CAMPAIGN
    var campaign = self.bag.controllers.campaign_menu_controller
    if campaign:
        self.reload_button(campaign.back_button, 'LABEL_BACK')
        self.reload_button(campaign.prev_button, 'LABEL_PREVIOUS', 'title')
        self.reload_button(campaign.next_button, 'LABEL_NEXT', 'title')
        self.reload_button(campaign.start_button, 'LABEL_START', 'title')
        self.reload_label(campaign.campaign_menu.get_node('middle/control/dialog_controls/playing_as'), 'LABEL_PLAYING_AS')
        self.reload_label(campaign.campaign_menu.get_node('middle/control/dialog_controls/difficulty_'), 'LABEL_DIFFICULTY')
        self.reload_label(campaign.campaign_menu.get_node('middle/control/dialog_controls/red/blue_team'), 'LABEL_RED_TEAM')
        self.reload_label(campaign.campaign_menu.get_node('middle/control/dialog_controls/blue/blue_team'), 'LABEL_BLUE_TEAM')
        self.reload_label(campaign.campaign_menu.get_node('middle/control/dialog_controls/mission_num_'), 'LABEL_MISSION')

    #SKIRMISH
    var skirmish = menu.maps_sub_menu
    self.reload_button(skirmish.get_node("bottom/control/menu_controls/close"), 'LABEL_BACK')
    self.reload_button(self.bag.map_picker.delete_button, 'LABEL_DELETE_MODE')
    self.reload_label(self.bag.map_picker.picker.get_node('controls/maps_label'), 'LABEL_MAPS')
    self.reload_label(self.bag.map_picker.picker.get_node('controls/page_label'), 'LABEL_PAGE')

    self.reload_button(self.bag.skirmish_setup.back_button, 'LABEL_BACK')
    self.reload_button(self.bag.skirmish_setup.play_button, 'LABEL_PLAY')
    self.reload_label(self.bag.skirmish_setup.panel.get_node('controls/selected_map_'), 'LABEL_SELECTED_MAP')
    self.reload_label(self.bag.skirmish_setup.panel.get_node('controls/maps_page'), 'LABEL_TURNS_CAP')

    #ONLINE
    self.reload_label(self.bag.controllers.online_menu_controller.online_menu.get_node('controls/online_headline'), 'MSG_MULTIPLAYER_LOBBY_HEADLINE')
    self.reload_label(self.bag.controllers.online_menu_controller.online_menu.get_node('controls/online_subline'), 'MSG_MULTIPLAYER_LOBBY_SUB')
    self.reload_label(self.bag.controllers.online_menu_controller.online_menu.get_node('controls/online_maps'), 'LABEL_ONLINE_MENU')


    self.bag.controllers.online_menu_controller.refreshed = false

    #WORKSHOP
    var workshop = self.bag.controllers.workshop_gui_controller
    self.reload_button(workshop.navigation_panel.menu_button, 'LABEL_BACK')
    self.reload_button(workshop.navigation_panel.toolbox_button, 'LABEL_WORKSHOP_TOOLBOX')
    self.reload_button(workshop.navigation_panel.undo_button, 'LABEL_WORKSHOP_UNDO_BUILD')
    self.reload_button(workshop.navigation_panel.drag_button, 'LABEL_WORKSHOP_MOVE_MAP')
    self.reload_label(workshop.navigation_panel.navigation_panel.get_node('controls/building_blocks_button/Label1'), 'LABEL_WORKSHOP_TILES')
    workshop.navigation_panel.drag_button_pressed()
    workshop.navigation_panel.reset_block_label()

    self.reload_label(workshop.toolbox_panel.toolbox_panel.get_node('front/Label'), 'LABEL_WORKSHOP_TOOLBOX')
    self.reload_label(workshop.toolbox_panel.toolbox_panel.get_node('front/label_lose_data'), 'MSG_WORKSHOP_LOSE_MAP_DATA')
    self.reload_label(workshop.toolbox_panel.toolbox_panel.get_node('front/label_fill_map'), 'MSG_WORKSHOP_FILL_MAP')
    self.reload_label(workshop.toolbox_panel.toolbox_panel.get_node('front/label_size'), 'LABEL_WORKSHOP_SIZE')
    self.reload_label(workshop.toolbox_panel.toolbox_panel.get_node('front/label_clear_map'), 'LABEL_WORKSHOP_CLEAR_MAP')
    self.reload_button(workshop.toolbox_panel.fill_button, 'LABEL_WORKSHOP_CREATE', 'label')
    self.reload_button(workshop.toolbox_panel.clear_terrain_button, 'LABEL_CLEAR', 'label')
    self.reload_button(workshop.toolbox_panel.clear_units_button, 'LABEL_WORKSHOP_UNITS', 'label')
    workshop.toolbox_panel.refresh_theme_button()
    self.reload_label(workshop.toolbox_panel.toolbox_panel.get_node('front/label_theme'), 'LABEL_WORKSHOP_THEME')

    self.reload_button(workshop.building_blocks_panel.terrain_button, 'LABEL_WORKSHOP_TERRAIN')
    self.reload_button(workshop.building_blocks_panel.buildings_button, 'LABEL_WORKSHOP_BUILDINGS')
    self.reload_button(workshop.building_blocks_panel.units_button, 'LABEL_WORKSHOP_UNITS')
    workshop.building_blocks_panel.reload_blocks()

    self.reload_button(workshop.file_panel.toggle_button, 'LABEL_WORKSHOP_FILES_MANAGER')
    self.reload_button(workshop.file_panel.play_button, 'LABEL_PREVIEW')
    self.reload_button(workshop.file_panel.load_button, 'LABEL_WORKSHOP_LOAD')
    self.reload_button(workshop.file_panel.save_button, 'LABEL_WORKSHOP_SAVE')
    self.reload_button(workshop.file_panel.pick_button, 'LABEL_WORKSHOP_PICK_MAP')
    self.reload_label(workshop.file_panel.file_panel.get_node('controls/top/map_name_'), 'MSG_WORKSHOP_USE_UNIQUE_NAME')


    #IN-GAME
    var hud = self.bag.root.hud
    var hud_controller = self.bag.controllers.action_controller.hud_controller
    var hud_panel = self.bag.controllers.hud_panel_controller
    var hud_game_over
    if hud:
        self.reload_button(hud_controller.menu_button, 'LABEL_MENU')
        self.reload_label(hud_panel.info_panel_scene.get_node('ap_'), 'LABEL_ACTION_POINTS')
        self.reload_label(hud_panel.info_panel_scene.get_node('ap_1'), 'LABEL_NEXT_TURN_GAIN')

        self.reload_label(hud_panel.building_panel.building_panel.get_node('attack'), 'LABEL_ATTACK')
        self.reload_label(hud_panel.building_panel.building_panel.get_node('health'), 'LABEL_HEALTH')
        self.reload_label(hud_panel.building_panel.building_panel.get_node('range'), 'LABEL_RANGE')
        self.reload_label(hud_panel.building_panel.building_panel.get_node('price_'), 'LABEL_DEPLOY_PRICE')
        self.reload_button(hud_panel.building_panel.build_card.deploy_button, 'LABEL_DEPLOY')

        self.reload_label(hud_panel.unit_panel.unit_panel.get_node('attack_'), 'LABEL_ATTACK')
        self.reload_label(hud_panel.unit_panel.unit_panel.get_node('health_'), 'LABEL_HEALTH')
        self.reload_label(hud_panel.unit_panel.unit_panel.get_node('action_points_'), 'LABEL_ACTION_POINTS')

        self.reload_label(hud_panel.end_turn_panel_scene.get_node('turn_'), 'LABEL_TURN')

        self.reload_label(hud.get_node('top_center/center/game_card/gamepad_buttons/Label'), 'LABEL_SELECT_UNIT')
        self.reload_label(hud.get_node('top_center/center/game_card/gamepad_buttons/Label1'), 'LABEL_NEXT_TURN')

    #GAME OVER
        hud_game_over = hud_controller.hud_end_game
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/game_over'), 'LABEL_GAME_OVER')
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/domination'), 'LABEL_DOMINATION')
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/unit_moves'), 'LABEL_MOVES')
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/spawn_count'), 'LABEL_DEPLOYED')
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/kills'), 'LABEL_ELIMINATED')
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/game_time'), 'LABEL_GAME_TIME')
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/turns'), 'LABEL_TURNS')
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/time'), 'LABEL_TIME')
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/turn_time'), 'LABEL_PLAYERS_TIME')
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/game_time'), 'LABEL_GAME_TIME')
        self.reload_label(hud_game_over.get_node('center/controls/labels/headers/overall'), 'LABEL_TOTAL_SCORE')
        self.reload_label(hud_game_over.get_node('center/controls/labels/blue/blue1'), 'LABEL_BLUE')
        self.reload_label(hud_game_over.get_node('center/controls/labels/blue/blue2'), 'LABEL_BLUE')
        self.reload_label(hud_game_over.get_node('center/controls/labels/blue/blue3'), 'LABEL_BLUE')
        self.reload_label(hud_game_over.get_node('center/controls/labels/red/red1'), 'LABEL_RED')
        self.reload_label(hud_game_over.get_node('center/controls/labels/red/red2'), 'LABEL_RED')
        self.reload_label(hud_game_over.get_node('center/controls/labels/red/red3'), 'LABEL_RED')


    #GAMEPAD INFO
    var gamepad_popup = self.bag.gamepad_popup.popup.get_node('center')
    self.reload_label(gamepad_popup.get_node('Label'), 'TITLE_GAMEPAD_CONFIG')
    self.reload_label(gamepad_popup.get_node('left_shoulder'), 'LABEL_PREVIOUS_UNIT')
    self.reload_label(gamepad_popup.get_node('right_shoulder'), 'LABEL_NEXT_UNIT')
    self.reload_label(gamepad_popup.get_node('analog'), 'LABEL_SELECTOR_MOVEMENT')
    self.reload_label(gamepad_popup.get_node('dpad'), 'LABEL_GAME_MENU_MOVEMENT')
    self.reload_label(gamepad_popup.get_node('x'), 'LABEL_DEPLOY_UNIT')
    self.reload_label(gamepad_popup.get_node('y'), 'LABEL_END_TURN')
    self.reload_label(gamepad_popup.get_node('a'), 'LABEL_SELECT')
    self.reload_label(gamepad_popup.get_node('b'), 'LABEL_BACK_TO_MENU')

    self.bag.campaign.reload_maps_definition()



func reload_button(button, translation, label_node_name="Label"):
    if button and button.has_node(label_node_name):
        self.reload_label(button.get_node(label_node_name), translation)
    else:
        self.reload_label(button, translation)

func reload_label(label, translation):
    if label:
        label.set_text(tr(translation))

func __get_available_languages():
    var languages = load('res://translations/languages.gd').new()
    if self.bag.root.settings['ENV'] == 'dev' :
        var langs = languages.available + languages.in_develop
        #langs.sort()
        return langs

    return languages.available

