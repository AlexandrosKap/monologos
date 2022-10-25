extends Node

# event: art|music|scene|lines
# enemy: art|code|time

onready var game := $GameLevel

func _ready():
	game.grid = Lib.GameGrid.new(6, 5)
	game.win = Vector2(5, 2)
	game.player = Lib.new_actor(Vector2(0, 2))
	game.grid.add_actor(game.player)
	game.grid.add_actor(Lib.new_actor(Vector2(5, 0), "uudd", "mon3|ududl|4"))
	game.grid.add_actor(Lib.new_event(
		game.win,
		"mon5||Level4|...|\"WoOf!\"|...|\"WoOf!\"|I'm not going to pet you.|\"WoOf!\"|..."
	))
	game.init()
