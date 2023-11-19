package engine.utils;

enum abstract Direction(Int) to Int
{
	var Up = 0;
	var Left = 1;
	var Down = 2;
	var Right = 3;

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
