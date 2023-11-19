import engine.Game;

class World
{
	public static var ME(default, null):World;

	public var level:Level;
	public var lights:Array<LightSource>;
	public var entities:Array<Entity>;

	public function new()
	{
		ME = this;
		level = new Level();
		lights = new Array();
		entities = new Array();
	}

	public function createEntity(cx = 0, cy = 0)
	{
		var entity = new Entity(this);
		entity.setPosition(cx, cy);
		entities.push(entity);
		return entity;
	}

	public function addEntity(entity:Entity)
	{
		entities.push(entity);
	}

	public function removeEntity(entity:Entity)
	{
		entities.remove(entity);
	}

	public function addLight(light:LightSource)
	{
		lights.push(light);
	}

	public function removeLight(light:LightSource)
	{
		lights.remove(light);
	}

	public function update()
	{
		World.ME.level.resetLight();

		for (entity in entities)
		{
			entity.update(Game.instance.frame);
		}

		for (lightsource in lights)
		{
			lightsource.update();
		}
	}

	public function postupdate()
	{
		for (entity in entities)
		{
			entity.postupdate();
		}
	}
}
