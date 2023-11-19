enum LightSourceType
{
	Flashlight;
	SmallSpotlight;
}

class LightSource
{
	public var entity(default, null):Entity;
	public var type(default, null):LightSourceType;

	public var cx(default, null):Int;
	public var cy(default, null):Int;

	private var world(get, never):World;
	private var level(get, never):Level;

	public function new(type:LightSourceType)
	{
		this.type = type;
	}

	public function setPosition(cx:Int, cy:Int)
	{
		this.cx = cx;
		this.cy = cy;
	}

	public function follow(entity:Entity)
	{
		this.entity = entity;
	}

	public function update()
	{
		if (this.entity != null)
		{
			cx = this.entity.cx;
			cy = this.entity.cy;
		}

		switch (type)
		{
			case Flashlight:
				updateFlashlight(level.light, cx, cy);
			case SmallSpotlight:
				updateSmallSpotlight(level.light, cx, cy);
		}
	}

	/** straight line up to the furthest wall. Illuminate in a 3x3 box and neighbooring walls **/
	private function updateFlashlight(lightmap:pirhana.Grid2D<Bool>, cx:Int, cy:Int)
	{
		if (entity == null)
		{
			return; // skip if no entity attached
		}

		var posx = entity.cx;
		var posy = entity.cy;
		var dx = entity.direction.dx;
		var dy = entity.direction.dy;

		var tile:Level.LevelTile = null;

		do
		{
			tile = level.getTile(posx, posy);
			level.light.set(posx, posy, true);

			for (n in level.getNeighbors(posx, posy))
			{
				if (tile.fget(See))
				{
					if (n.fget(See))
					{
						level.light.set(n.x, n.y, true);
						for (nn in level.getNeighbors(n.x, n.y))
						{
							if (!nn.fget(See))
							{
								level.light.set(nn.x, nn.y, true);
							}
						}
					}
					else
					{
						level.light.set(n.x, n.y, true);
					}
				}
			}

			posx += dx;
			posy += dy;
		}
		while (tile != null && tile.fget(See));
	}

	/**
		Illuminate a small spotlight + shaped at given location
	**/
	private function updateSmallSpotlight(lightmap:pirhana.Grid2D<Bool>, cx:Int, cy:Int)
	{
		var tile = level.getTile(cx, cy);
		level.light.set(cx, cy, true);

		for (n in level.getNeighbors(cx, cy))
		{
			if (tile.fget(See))
			{
				if (n.fget(See))
				{
					level.light.set(n.x, n.y, true);
					for (nn in level.getNeighbors(n.x, n.y))
					{
						if (!nn.fget(See))
						{
							level.light.set(nn.x, nn.y, true);
						}
					}
				}
				else
				{
					level.light.set(n.x, n.y, true);
				}
			}
		}
	}

	inline function get_world()
	{
		return World.ME;
	}

	inline function get_level()
	{
		return world.level;
	}
}
