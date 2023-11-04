import engine.AssetManager;

enum Anim
{
	Env;
	Player;
}

enum Sprite
{
	PlayerShadow;
}

enum Music {}
enum Sfx {}

enum Font
{
	CelticTime16;
}

class Assets
{
	private static var _initialized = false;

	private static var manager:AssetManager<Anim, Sprite, Font, Sfx, Music>;

	public static function initialize()
	{
		if (_initialized)
			return;
		_initialized = true;

		manager = new AssetManager();
		// fonts
		manager.fonts.set(CelticTime16, hxd.Res.fonts.celtictime.celtictime16.toFont());

		// sprites
		manager.sprites.set(PlayerShadow, hxd.Res.sprites.player_shadow.toTile().center());
		// anims / tilesheets
		manager.anims.set(Env, manager.subTilesheet(hxd.Res.sprites.env.toTile(), 32, 32, 0, 0));
		manager.anims.set(Player, manager.subTilesheet(hxd.Res.sprites.player.toTile(), 32, 32, -16, -24));
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
