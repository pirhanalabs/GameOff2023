import engine.AssetManager;

enum Anim
{
	Env;

	PlayerWalkUp;
	PlayerWalkDown;
	PlayerWalkLeft;
	PlayerWalkRight;

	ShrimpWalkUp;
	ShrimpWalkDown;
	ShrimpWalkLeft;
	ShrimpWalkRight;

	Clam;
}

enum Sprite
{
	PlayerShadow;
	PopupPatch;
	WinSmallBtn;

	BgNumPlayer;
	BgNumEnemy;
}

enum Music {}
enum Sfx {}

enum Font
{
	CelticTime16;
	BitFantasy16;
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
		initFonts();
		initSprites();
		initAnims();
		initSfx();
		initMusic();
	}

	private static function initFonts()
	{
		manager.fonts.set(CelticTime16, hxd.Res.fonts.celtictime.celtictime16.toFont());
		manager.fonts.set(BitFantasy16, hxd.Res.fonts.bitfantasy.bitfantasy16.toFont());
	}

	private static function initSprites()
	{
		manager.sprites.set(PlayerShadow, hxd.Res.sprites.player_shadow.toTile().center());
		manager.sprites.set(PopupPatch, hxd.Res.sprites.patch_win.toTile());
		manager.sprites.set(WinSmallBtn, hxd.Res.sprites.win_small_btn.toTile());
		manager.sprites.set(BgNumPlayer, hxd.Res.sprites.player_num_bg.toTile().center());
		manager.sprites.set(BgNumEnemy, hxd.Res.sprites.enemy_num_bg.toTile().center());
	}

	private static function initAnims()
	{
		// environment tilesheet
		manager.anims.set(Env, manager.subTilesheet(hxd.Res.sprites.env.toTile(), 32, 32, 0, 0));

		// player tilesheet
		var tiles = manager.subTilesheet(hxd.Res.sprites.sheets.player.toTile(), 32, 32, -16, -24);
		manager.anims.set(PlayerWalkUp, manager.makeAnim(tiles, [0, 1, 2, 3]));
		manager.anims.set(PlayerWalkLeft, manager.makeAnim(tiles, [4, 5, 6, 7]));
		manager.anims.set(PlayerWalkDown, manager.makeAnim(tiles, [8, 9, 10, 11]));
		manager.anims.set(PlayerWalkRight, manager.makeAnim(tiles, [12, 13, 14, 15]));

		// shrimp
		tiles = manager.subTilesheet(hxd.Res.sprites.sheets.shrimp.toTile(), 32, 32, 0, 0);
		manager.anims.set(ShrimpWalkUp, manager.makeAnim(tiles, [0, 1, 2, 3]));
		manager.anims.set(ShrimpWalkLeft, manager.makeAnim(tiles, [4, 5, 6, 7]));
		manager.anims.set(ShrimpWalkDown, manager.makeAnim(tiles, [8, 9, 10, 11]));
		manager.anims.set(ShrimpWalkRight, manager.makeAnim(tiles, [12, 13, 14, 15]));

		// clam tilesheet
		manager.anims.set(Clam, manager.subTilesheet(hxd.Res.sprites.clam.toTile(), 32, 32, -16, -32));
	}

	private static function initSfx()
	{
		// add sfx here and link in Sfx enum
	}

	private static function initMusic()
	{
		// add music here and link in Music enum
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
