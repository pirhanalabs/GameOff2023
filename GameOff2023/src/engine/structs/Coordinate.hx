package engine.structs;

import engine.RenderLayer.RenderLayerSpace;

class Coordinate
{
	public var space:RenderLayerSpace;
	public var x(default, null):Float;
	public var y(default, null):Float;

	public function new(x:Float, y:Float, space:RenderLayerSpace)
	{
		this.x = x;
		this.y = y;
		this.space = space;
	}
}
