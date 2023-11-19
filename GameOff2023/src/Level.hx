import haxe.EnumFlags;
import pirhana.Grid2D;

enum TileFlag
{
	Col; // collision
	See; // seethrough
	Bmp; // bump trigger
	Stp; // step trigger
}

class LevelTile
{
	public var id(default, null):Int;
	public var x(default, null):Int;
	public var y(default, null):Int;

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
				flags.set(See);
			case 2:
				flags.set(Col);
				flags.set(See);
			case 3:
				flags.set(Col);
			case 4: // ?
				flags.set(Bmp);
				flags.set(Col);
			case _:
		}
	}

	public function getTileId()
	{
		return id;
	}

	public function fget(flag:TileFlag)
	{
		return flags.has(flag);
	}
}

class Level
{
	public var width(default, null):Int;
	public var height(default, null):Int;

	public var level(default, null):pirhana.Grid2D<LevelTile>;
	public var light(default, null):pirhana.Grid2D<Bool>;

	public function new()
	{
		this.width = 16;
		this.height = 13;

		var data = [
			[3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
			[3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 3],
			[3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3],
			[3, 1, 3, 3, 3, 3, 1, 3, 3, 1, 3, 3, 3, 3, 3, 3],
			[3, 1, 3, 1, 1, 3, 1, 3, 1, 1, 3, 3, 1, 1, 1, 3],
			[3, 1, 3, 3, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 3],
			[3, 1, 1, 1, 1, 1, 1, 3, 1, 1, 3, 1, 1, 1, 1, 3],
			[3, 3, 3, 1, 4, 3, 3, 3, 1, 1, 3, 3, 3, 3, 1, 3],
			[3, 1, 1, 1, 1, 3, 1, 3, 1, 1, 3, 1, 1, 1, 1, 3],
			[3, 1, 3, 3, 1, 3, 1, 3, 3, 3, 3, 1, 1, 1, 1, 3],
			[3, 1, 3, 3, 1, 3, 1, 1, 1, 1, 3, 1, 1, 1, 1, 3],
			[3, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 3],
			[3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
		];
		level = new pirhana.Grid2D(width, height, (x, y) -> new LevelTile(x, y, data[y][x]));
	}

	public function fget(cx:Int, cy:Int, flag:TileFlag)
	{
		if (!inBounds(cx, cy))
			return false;
		return getTile(cx, cy).fget(flag);
	}

	public function getEntity(cx:Int, cy:Int)
	{
		// if (!inBounds(cx, cy))
		// {
		// 	return null;
		// }
		// return getTile(cx, cy).entity;
	}

	public function hasEntity(cx:Int, cy:Int)
	{
		// return getEntity(cx, cy) != null;
	}

	public function resetLight()
	{
		light = new Grid2D(width, height, (x, y) -> false);
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
