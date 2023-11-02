package engine;

import engine.structs.Coordinate;

class Projection
{
	public static function screenToViewport(sx:Float, sy:Float)
	{
		var ox = (Game.instance.window.width - (Application.VIEW_WID * Application.VIEW_SCALE)) * 0.5;
		var oy = (Game.instance.window.height - (Application.VIEW_HEI * Application.VIEW_SCALE)) * 0.5;
		return new Coordinate((sx - ox) / Application.VIEW_SCALE, (sy - oy) / Application.VIEW_SCALE, World);
	}
}
