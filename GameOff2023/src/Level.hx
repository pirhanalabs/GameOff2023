import haxe.EnumFlags;

enum TileFlag
{
	Collision;
	SeeThrough;
}

class LevelTile
{
	public var id(default, null):Int;
	public var x(default, null):Int;
	public var y(default, null):Int;
	public var visible:Bool = false;

	private var flags:haxe.EnumFlags<TileFlag>;

	public function new(x:Int, y:Int, id:Int)
	{
		this.x = x;
		this.y = y;
		this.id = id;
		flags = new EnumFlags();

		switch (id)
		{
			case 1:
				flags.set(SeeThrough);
			case 2:
				flags.set(Collision);
				flags.set(SeeThrough);
			case 3:
				flags.set(Collision);
			case _:
		}
	}

	public function getTileId()
	{
		return visible ? id : 0;
	}

	public function hasFlag(flag:TileFlag)
	{
		return flags.has(flag);
	}
}

class Level
{
	public var width(default, null):Int;
	public var height(default, null):Int;

	var level:pirhana.Grid2D<LevelTile>;

	public function new()
	{
		this.width = 15;
		this.height = 8;

		var data = [
			[3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
			[3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3],
			[3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3],
			[3, 1, 3, 3, 3, 3, 1, 3, 3, 1, 3, 3, 3, 3, 3],
			[3, 1, 3, 1, 1, 3, 1, 3, 1, 1, 3, 1, 1, 1, 3],
			[3, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 3],
			[3, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 3],
			[3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
		];
		level = new pirhana.Grid2D(width, height, (x, y) -> new LevelTile(x, y, data[y][x]));
	}

	public function inBounds(x:Int, y:Int)
	{
		return x >= 0 && y >= 0 && x < width && y < height;
	}

	public function getNeighbors(x:Int, y:Int)
	{
		var list = [];
		if (inBounds(x + 1, y))
			list.push(getTile(x + 1, y));
		if (inBounds(x - 1, y))
			list.push(getTile(x - 1, y));
		if (inBounds(x, y + 1))
			list.push(getTile(x, y + 1));
		if (inBounds(x, y - 1))
			list.push(getTile(x, y - 1));
		return list;
	}

	public function each(fn:(x:Int, y:Int, tile:LevelTile) -> Void)
	{
		for (y in 0...height)
		{
			for (x in 0...width)
			{
				fn(x, y, getTile(x, y));
			}
		}
	}

	public function getTile(x:Int, y:Int)
	{
		return level.get(x, y);
	}
}
