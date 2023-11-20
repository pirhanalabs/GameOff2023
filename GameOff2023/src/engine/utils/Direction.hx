package engine.utils;

enum abstract Direction(Int) to Int
{
	var Up = 0;
	var Left = 1;
	var Down = 2;
	var Right = 3;

	/**
		If dx and dy or invalid, will return Up;
	**/
	public static function fromDeltas(dx:Int, dy:Int):Direction
	{
		if (dx == 0 && dy == -1)
			return Up;
		if (dx == 0 && dy == 1)
			return Down;
		if (dy == 0 && dx == -1)
			return Left;
		if (dx == 1 && dx == 1)
			return Right;
		return Up;
	}

	public var dx(get, never):Int;
	public var dy(get, never):Int;

	public inline function new(dir:Int)
	{
		this = dir;
	}

	inline function get_dx()
	{
		return (this % 2) * (this - 2);
	}

	inline function get_dy()
	{
		return (this - 1) * (hxd.Math.iabs(this - 1) % 2);
	}
}
