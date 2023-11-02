package engine;

import engine.structs.Coordinate;

class Screen
{
	private var game(get, never):Game;

	inline function get_game()
	{
		return Game.instance;
	}

	@:allow(engine.ScreenManager)
	function ready():Void
	{
		// override this in subclasses
	}

	@:allow(engine.Game)
	function update(frame:Frame):Void
	{
		// override this in subclasses
	}

	@:allow(engine.Game)
	function postupdate():Void
	{
		// override this in subclasses
	}

	@:allow(engine.ScreenManager)
	function dispose():Void
	{
		// override this in subclasses
	}

	@:allow(engine.ScreenManager)
	function suspend():Void
	{
		// override this in subclasses
	}

	@:allow(engine.ScreenManager)
	function resume():Void
	{
		// override this in subclasses
	}
}
