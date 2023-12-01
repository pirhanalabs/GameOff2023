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

	Vase1;
	Vase2;
	Bait;
}

enum Sprite
{
	PlayerShadow;
	PopupPatch;
	WinSmallBtn;

	BgNumPlayer;
	BgNumEnemy;

	TitleBg;
}

enum Music
{
	Title;
	MainTheme;
	GameOver;
}

enum Sfx
{
	PlayerHurt;
	ShrimpHurt;
	Vase1Hurt;
	Vase2Hurt;
	BaitHurt;
	ShrimpAlert;
	PlayerMove;
	ShrimpMove;

	Confirm;
	CantDo;
	MenuBtn;
}

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
		manager.sprites.set(TitleBg, hxd.Res.sprites.ScalesoftheDeep_Title.toTile().center());
	}

	private static function initAnims()
	{
		// environment tilesheet
		manager.anims.set(Env, manager.subTilesheet(hxd.Res.sprites.env.toTile(), 32, 32, 0, 0));
		trace(manager.anims.get(Env));

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

		// vases
		manager.anims.set(Vase1, [getAnim(Env)[60]]);
		manager.anims.set(Vase2, [getAnim(Env)[65]]);
		manager.anims.set(Bait, manager.makeAnim(getAnim(Env), [50, 51, 52, 53, 54, 55, 56, 57]));

		// clam tilesheet
		manager.anims.set(Clam, manager.subTilesheet(hxd.Res.sprites.clam.toTile(), 32, 32, -16, -32));
	}

	private static function initSfx()
	{
		manager.sfxs.set(PlayerHurt, hxd.Res.sfx.player.SFX_Player_Health_Death_Short);
		manager.sfxs.set(ShrimpHurt, hxd.Res.sfx.shrimp.SFX_Shrimp_Die);
		manager.sfxs.set(Vase1Hurt, hxd.Res.sfx.vase.SFX_Interactive_Vase_Break_short);
		manager.sfxs.set(Vase2Hurt, hxd.Res.sfx.vase.SFX_Interactive_Vase_Break_short);
		manager.sfxs.set(BaitHurt, hxd.Res.sfx.player.SFX_Player_Interaction_PickUpBait);

		manager.sfxs.set(ShrimpAlert, hxd.Res.sfx.shrimp.SFX_Shrimp_Alert);
		manager.sfxs.set(ShrimpMove, hxd.Res.sfx.shrimp.SFX_Shrimp_Move);
		manager.sfxs.set(PlayerMove, hxd.Res.sfx.player.SFX_Player_Walk_1);

		manager.sfxs.set(Confirm, hxd.Res.sfx.gui.SFX_HUD_GUI_Confirm);
		manager.sfxs.set(CantDo, hxd.Res.sfx.gui.SFX_HUD_GUI_InvalidAction);
		manager.sfxs.set(MenuBtn, hxd.Res.sfx.gui.SFX_HUD_GUI_StartGame);
	}

	private static function initMusic()
	{
		manager.musics.set(Title, hxd.Res.musics.MUS_Title);
		manager.musics.set(MainTheme, hxd.Res.musics.MUS_Explore_Theme2_Loop);
		manager.musics.set(GameOver, hxd.Res.musics.MUS_YouDied);
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
