enum Anim
{
	Env;
}

enum Sprite {}
enum Music {}
enum Sfx {}

enum Font
{
	CelticTime16;
}

class Assets
{
	private static var _initialized = false;

	private static var manager:engine.AssetManager<Anim, Sprite, Font, Sfx, Music>;

	public static function initialize()
	{
		if (_initialized)
			return;
		_initialized = true;

		// fonts
		manager.fonts.set(CelticTime16, hxd.Res.fonts.celtictime.celtictime16.toFont());

		// anims / tilesheets
		manager.anims.set(Env, manager.subTilesheet(hxd.Res.sprites.env.toTile(), 32, 32, 0, 0));
	}

	public static function getFont(id:Font)
	{
		return manager.fonts.get(id);
	}

	public static function getSprite(id:Sprite)
	{
		return manager.sprites.get(id);
	}

	public static function getAnim(id:Anim)
	{
		return manager.anims.get(id);
	}

	public static function getMusic(id:Music)
	{
		return manager.musics.get(id);
	}

	public static function getSfx(id:Sfx)
	{
		return manager.sfxs.get(id);
	}
}
