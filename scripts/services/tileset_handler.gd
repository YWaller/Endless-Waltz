extends "res://scripts/bag_aware.gd"

var available_tilesets = {
    'summer' : preload("res://maps/tilesets/summer_tileset.xml"),
    'fall'   : preload("res://maps/tilesets/fall_tileset.xml"),
    'winter' : preload("res://maps/tilesets/winter_tileset.xml")
}

var available_objects = {
    'summer' : {
        'movable' : preload('res://terrain/tilesets/summer_movable.xscn'),
        'non-movable' : preload('res://terrain/tilesets/summer_non_movable.xscn')
    },
    'fall' : {
        'movable' : preload('res://terrain/tilesets/fall_movable.xscn'),
        'non-movable' : preload('res://terrain/tilesets/fall_non_movable.xscn')
    },
    'winter' : {
        'movable' : preload('res://terrain/tilesets/winter_movable.xscn'),
        'non-movable' : preload('res://terrain/tilesets/winter_non_movable.xscn')
    }
}

var available_city = {
    'summer' : {
        'small' : [
            preload('res://terrain/city/summer/city_small_1.xscn'),
            preload('res://terrain/city/summer/city_small_2.xscn'),
            preload('res://terrain/city/summer/city_small_3.xscn'),
            preload('res://terrain/city/summer/city_small_4.xscn'),
            preload('res://terrain/city/summer/city_small_5.xscn'),
            preload('res://terrain/city/summer/city_small_6.xscn')
        ],
        'large' : [
            preload('res://terrain/city/summer/city_big_1.xscn'),
            preload('res://terrain/city/summer/city_big_2.xscn'),
            preload('res://terrain/city/summer/city_big_3.xscn'),
            preload('res://terrain/city/summer/city_big_4.xscn')
        ],
        'statue' : preload('res://terrain/city/summer/city_statue.xscn')
    },
    'fall' : {
        'small' : [
            preload('res://terrain/city/fall/city_small_1.xscn'),
            preload('res://terrain/city/fall/city_small_2.xscn'),
            preload('res://terrain/city/fall/city_small_3.xscn'),
            preload('res://terrain/city/fall/city_small_4.xscn'),
            preload('res://terrain/city/fall/city_small_5.xscn'),
            preload('res://terrain/city/fall/city_small_6.xscn')
        ],
        'large' : [
            preload('res://terrain/city/fall/city_big_1.xscn'),
            preload('res://terrain/city/fall/city_big_2.xscn'),
            preload('res://terrain/city/fall/city_big_3.xscn'),
            preload('res://terrain/city/fall/city_big_4.xscn')
        ],
        'statue' : preload('res://terrain/city/fall/city_statue.xscn')
    },
    'winter' : {
        'small' : [
            preload('res://terrain/city/winter/city_small_1.xscn'),
            preload('res://terrain/city/winter/city_small_2.xscn'),
            preload('res://terrain/city/winter/city_small_3.xscn'),
            preload('res://terrain/city/winter/city_small_4.xscn'),
            preload('res://terrain/city/winter/city_small_5.xscn'),
            preload('res://terrain/city/winter/city_small_6.xscn')
        ],
        'large' : [
            preload('res://terrain/city/winter/city_big_1.xscn'),
            preload('res://terrain/city/winter/city_big_2.xscn'),
            preload('res://terrain/city/winter/city_big_3.xscn'),
            preload('res://terrain/city/winter/city_big_4.xscn')
        ],
        'statue' : preload('res://terrain/city/winter/city_statue.xscn')
    }
}

var seasons = {
    'summer' : {'day' : 21, 'month': 4},
    'fall' : {'day' : 21, 'month': 9},
    'winter' : {'day' : 21, 'month': 12}
}

func get_current_tileset():
    for theme in self.seasons:
        if self.bag.helpers.comp_days(self.seasons[theme], OS.get_date()) != 1:
            return theme
    return 'winter'

