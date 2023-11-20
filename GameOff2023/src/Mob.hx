class Mob
{
	private static var filter:PixelOutline;

	// death flag
	public var dead:Bool = false;

	// type
	public var type(default, null):MobType;

	// position
	public var cx:Int;
	public var cy:Int;

	// start movement position
	public var sx:Int;
	public var sy:Int;

	// offset movement position
	public var ox:Float;
	public var oy:Float;

	// animations
	public var dir:engine.utils.Direction;
	public var sprite(default, null):h2d.Bitmap;
	public var score_o(default, null):h2d.Text;
	public var ani(get, never):Array<h2d.Tile>;
	public var anims(default, null):Array<Array<h2d.Tile>>;

	inline function get_ani()
	{
		return anims[dir];
	}

	// anim
	public var mov:Null<(mob:Mob, t:Float) -> Void>;
	public var flash:Float = 0;
	public var baseColor:h3d.Vector = new h3d.Vector(0, 0, 0);
	public var flashColor:h3d.Vector = new h3d.Vector(1, 1, 1);

	// frame offset
	public var offx(default, null):Float;
	public var offy(default, null):Float;

	// stats
	public var score:Int;

	public function new(type:MobType, cx:Int, cy:Int)
	{
		if (filter == null)
		{
			filter = new PixelOutline();
		}

		this.type = type;
		this.cx = cx;
		this.cy = cy;
		this.sx = 0;
		this.sy = 0;
		this.ox = 0;
		this.oy = 0;

		this.dir = Down;
		this.sprite = new h2d.Bitmap();
		this.score_o = new h2d.Text(Assets.getFont(CelticTime16), this.sprite);
		this.score_o.textAlign = Center;
		this.score_o.filter = filter;

		this.offx = 0;
		this.offy = 0;

		this.score = 1;

		switch (type)
		{
			case Player:
				anims = [
					Assets.getAnim(Assets.Anim.PlayerWalkUp),
					Assets.getAnim(Assets.Anim.PlayerWalkLeft),
					Assets.getAnim(Assets.Anim.PlayerWalkDown),
					Assets.getAnim(Assets.Anim.PlayerWalkRight)
				];
				offx = 16;
				offy = 24;
				this.score = 3;
			case Shrimp:
				anims = [
					Assets.getAnim(Assets.Anim.ShrimpWalkUp),
					Assets.getAnim(Assets.Anim.ShrimpWalkLeft),
					Assets.getAnim(Assets.Anim.ShrimpWalkDown),
					Assets.getAnim(Assets.Anim.ShrimpWalkRight)
				];
				this.score = 21;
			case _:
				anims = [[null], [null], [null], [null]];
		}
	}

	public function resetMovement()
	{
		mov = null;
		sx = 0;
		sy = 0;
		ox = 0;
		oy = 0;
	}
}
