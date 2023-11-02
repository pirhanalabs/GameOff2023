package engine;

class AssetManager<Anim:EnumValue, Sprite:EnumValue, Font:EnumValue, Sfx:EnumValue, Music:EnumValue>
{
	public var anims(default, null):Map<Anim, Array<h2d.Tile>>;
	public var sprites(default, null):Map<Sprite, h2d.Tile>;
	public var fonts(default, null):Map<Font, h2d.Font>;
	public var sfxs(default, null):Map<Sfx, hxd.res.Sound>;
	public var musics(default, null):Map<Music, hxd.res.Sound>;

	public function new()
	{
		anims = new Map();
		sprites = new Map();
		fonts = new Map();
		sfxs = new Map();
		musics = new Map();
	}

	public function subTilesheet(sheet:h2d.Tile, tw:Int, th:Int, dx:Int = 0, dy:Int = 0)
	{
		return [
			for (y in 0...Math.floor(sheet.height / th))
				for (x in 0...Math.floor(sheet.width / tw))
					sheet.sub(x * tw, y * th, tw, th, dx, dy)
		];
	}

	public function makeAnim(tiles:Array<h2d.Tile>, frames:Array<Int>)
	{
		return [
			for (frame in frames)
				tiles[frame]
		];
	}
}
