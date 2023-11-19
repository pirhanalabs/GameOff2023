package screens;

import engine.Frame;
import engine.Screen;
import engine.utils.Direction;
import h3d.col.HeightMap;
import h3d.shader.GpuParticle;

typedef UpdateFn = (frame:Frame) -> Void;
typedef PostUpdateFn = () -> Void;

class Game extends Screen
{
	var _upd:UpdateFn;
	var _drw:PostUpdateFn;
	var _lvl:Level;

	var t:Float;
	var pt:Float; // player timer
	var tiles:Array<h2d.Bitmap>;
	var floats:Array<
		{
			txt:h2d.Text,
			x:Float,
			y:Float,
			ty:Float,
			t:Float
		}> = [];
	var mobs:Array<Mob>;
	var player:Mob;

	var dirx = [0, 0, -1, 1];
	var diry = [-1, 1, 0, 0];
	var dirs = [Direction.Up, Direction.Down, Direction.Left, Direction.Right];
	var btn_buffer:Int = -1;
	var btns = [
		GameAction.MOVE_UP,
		GameAction.MOVE_DOWN,
		GameAction.MOVE_LEFT,
		GameAction.MOVE_RIGHT
	];

	var win:Array<Window> = [];
	var winput:Array<Window> = [];

	public function new()
	{
		// do
	}

	override function ready()
	{
		super.ready();

		// initialize update methods
		_upd = update_game;
		_drw = postupdate_game;

		startgame();
	}

	function startgame()
	{
		_lvl = new Level();

		tiles = [];
		_lvl.each((x, y, t) ->
		{
			var b = new h2d.Bitmap(Assets.getAnim(Env)[t.getTileId()]);
			b.x = t.x * Const.TILE_WID;
			b.y = t.y * Const.TILE_HEI;
			tiles.push(b);
			game.render(Ground, b);
		});

		mobs = [];
		player = addMob(Player, 5, 5);

		addMob(Shrimp, 11, 10);
		addMob(Shrimp, 8, 7);

		pt = 0;
	}

	function updateWindows(frame:Frame)
	{
		for (w in win.iterator())
		{
			w.update(frame);
			if (w.destroyed)
			{
				w.dispose();
				win.remove(w);
				winput.remove(w);
			}
		}
	}

	function drawWindows()
	{
		for (w in win)
		{
			w.postupdate();
		}
	}

	function isWalkable(cx:Int, cy:Int, checkmob:Bool)
	{
		if (!_lvl.inBounds(cx, cy))
		{
			return false;
		}
		if (_lvl.getTile(cx, cy).fget(Col))
		{
			return false;
		}
		if (checkmob && getMob(cx, cy) != null)
		{
			return false;
		}

		return true;
	}

	function getMob(cx:Int, cy:Int)
	{
		for (mob in mobs)
		{
			if (mob.cx == cx && mob.cy == cy)
			{
				return mob;
			}
		}
		return null;
	}

	function moveMob(mob:Mob, dir:Direction)
	{
		mob.ani = mob.anims[dir];

		var dx = dir.dx;
		var dy = dir.dy;
		var destx = mob.cx + dx;
		var desty = mob.cy + dy;

		pt = 0;
		_upd = update_pturn;

		if (isWalkable(destx, desty, true))
		{
			mobwalk(mob, dx, dy);
		}
		else
		{
			pausefollow = true;
			mobbump(mob, dx, dy);

			var other = getMob(destx, desty);
			if (other == null)
			{
				var t = _lvl.getTile(destx, desty);
				if (t.fget(Bmp))
				{
					trigger_bump(t, destx, desty);
				}
			}
			else
			{
				hitmob(mob, other);
				game.camera.shakeS(0.1, 0.5);
				// game.camera.bump(dx * 2 * -1, dy * 2 * -1);
			}
		}
	}

	function mobwalk(mob:Mob, dx:Int, dy:Int)
	{
		mob.mov = mov_walk;
		mob.cx += dx;
		mob.cy += dy;
		mob.ox = -dx * 32;
		mob.oy = -dy * 32;
		mob.sx = -dx * 32;
		mob.sy = -dy * 32;
	}

	function mobbump(mob:Mob, dx:Int, dy:Int)
	{
		mob.mov = mov_bump;
		mob.ox = 0;
		mob.oy = 0;
		mob.sx = dx * 32;
		mob.sy = dy * 32;
	}

	function hitmob(atk:Mob, def:Mob)
	{
		if (atk.score < def.score)
		{
			// atk die
			def.flash = 15;
			def.dead = true;
			atk.score += def.score;
			addFloat('+${def.score}', def.cx * Const.TILE_WID + Const.TILE_WID_2, def.cy * Const.TILE_HEI + Const.TILE_HEI_2, 0xb0d07e);
		}
		else
		{
			def.flash = 15;
			def.dead = true;
			atk.score += def.score;
			addFloat('+${def.score}', def.cx * Const.TILE_WID + Const.TILE_WID_2, def.cy * Const.TILE_HEI + Const.TILE_HEI_2, 0xb0d07e);
			// mobs.remove(def);
			// def.sprite.remove();
		}
	}

	function trigger_bump(tile:Level.LevelTile, cx:Int, cy:Int)
	{
		if (tile.id == 4)
		{
			// var w = new Window(150, 50);
			// w.ready();
			// win.push(w);
			// winput.push(w);
		}
	}

	function mov_walk(mob:Mob, t:Float)
	{
		mob.ox = mob.sx * (1 - t);
		mob.oy = mob.sy * (1 - t);
	}

	function mov_bump(mob:Mob, t:Float)
	{
		var time = t < 0.5 ? t : 1 - t;
		mob.ox = mob.sx * time;
		mob.oy = mob.sy * time;
	}

	function update_pturn(frame:Frame)
	{
		updateBtnBuffer();

		pt = Math.min(pt + 0.128 * frame.tmod, 1);

		player.mov(player, pt);

		if (pt == 1)
		{
			_upd = update_game;
			player.ox = 0;
			player.oy = 0;
		}
	}

	function update_game(frame:Frame)
	{
		pausefollow = false;
		if (winput.length == 0)
		{
			updateBtnBuffer();
			doBtn(btn_buffer);
			btn_buffer = -1;
		}
	}

	function addMob(type:MobType, cx:Int, cy:Int)
	{
		var mob = new Mob(type, cx, cy);
		mobs.push(mob);
		game.render(Actors, mob.sprite);
		return mob;
	}

	function addFloat(txt:String, x:Float, y:Float, color:Int = 0xffffff)
	{
		var f = {
			txt: new h2d.Text(Assets.getFont(BitFantasy16)),
			x: x,
			y: y,
			ty: y - 24,
			t: 0.0
		};
		f.txt.filter = new PixelOutline();
		f.txt.text = txt;
		f.txt.textAlign = Center;
		f.txt.textColor = color;
		f.txt.x = x;
		f.txt.y = y;
		game.render(Actors, f.txt);
		floats.push(f);
	}

	function updateFloats(frame:Frame)
	{
		for (f in floats.iterator())
		{
			f.y += (f.ty - f.y) / 24;
			f.t += Math.pow(1, frame.tmod);
			if (f.t > 70)
			{
				f.txt.remove();
				floats.remove(f);
			}
		}
	}

	function drawFloats()
	{
		for (f in floats)
		{
			f.txt.y = f.y;
			f.txt.x = f.x;
		}
	}

	function updateBtnBuffer()
	{
		if (btn_buffer == -1)
		{
			btn_buffer = getBtn();
		}
	}

	function doBtn(btn:Int)
	{
		if (btn == -1)
			return;

		if (btn < 4)
		{
			moveMob(player, dirs[btn]);
			return;
		}
	}

	function getBtnBuffer()
	{
		if (btn_buffer == -1)
		{
			return getBtn();
		}
		return -1;
	}

	function getBtn()
	{
		for (i in 0...btns.length)
		{
			if (btns[i].isPressed())
			{
				return i;
			}
		}
		return -1;
	}

	function postupdate_game()
	{
		for (mob in mobs)
		{
			drawSprite(mob);
		}

		drawScroller();
	}

	public var pausefollow:Bool = false;

	function drawScroller()
	{
		if (pausefollow)
			return;
		var destx = (Const.VIEW_WID_2 - player.sprite.x) - game.layers.scroller.x;
		var desty = (Const.VIEW_HEI_2 - player.sprite.y) - game.layers.scroller.y;
		game.layers.scroller.x += destx * 0.2 * game.frame.tmod;
		game.layers.scroller.y += desty * 0.2 * game.frame.tmod;
		// bounds
		if (game.layers.scroller.x < Const.VIEW_WID - _lvl.width * Const.TILE_WID)
		{
			game.layers.scroller.x = Const.VIEW_WID - _lvl.width * Const.TILE_WID;
		}
		else if (game.layers.scroller.x > 0)
		{
			game.layers.scroller.x = 0;
		}
		if (game.layers.scroller.y < Const.VIEW_HEI - _lvl.height * Const.TILE_HEI)
		{
			game.layers.scroller.y = Const.VIEW_HEI - _lvl.height * Const.TILE_HEI;
		}
		else if (game.layers.scroller.y > 0)
		{
			game.layers.scroller.y = 0;
		}
	}

	function drawSprite(mob:Mob)
	{
		mob.sprite.x = Std.int(mob.cx * Const.TILE_WID + mob.offx + mob.ox);
		mob.sprite.y = Std.int(mob.cy * Const.TILE_HEI + mob.offx + mob.oy);
		mob.sprite.tile = getFrame(mob.ani);
		mob.sprite.colorAdd = Math.floor(mob.flash) % 8 < 4 ? mob.baseColor : mob.flashColor;
		mob.sprite.visible = mob.flash == 0 || Math.floor(mob.flash) % 8 > 4;
		mob.score_o.text = '${mob.score}';
		mob.score_o.x = mob.sprite.getSize().width * 0.5 + mob.sprite.tile.dx;
		mob.score_o.y = mob.sprite.tile.dy - 10;
	}

	function getFrame(ani:Array<h2d.Tile>)
	{
		return ani[Math.floor(t / 12) % ani.length];
	}

	override function update(frame:Frame)
	{
		super.update(frame);
		t += Math.pow(1, frame.tmod);

		updateWindows(frame);
		updateFloats(frame);

		for (mob in mobs.iterator())
		{
			mob.flash = Math.max(mob.flash - Math.pow(1, frame.tmod), 0);
			if (mob.dead && mob.flash == 0)
			{
				mobs.remove(mob);
				mob.sprite.remove();
			}
		}
		_upd(frame);
	}

	override function postupdate()
	{
		super.postupdate();
		_drw();
		drawWindows();
		drawFloats();
		game.layers.ysort(Actors);
	}
}

enum abstract MobType(Int)
{
	var Player;
	var Shrimp;
}

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
	public var dir(default, null):engine.utils.Direction;
	public var sprite(default, null):h2d.Bitmap;
	public var score_o(default, null):h2d.Text;
	public var ani:Array<h2d.Tile>;
	public var anims(default, null):Array<Array<h2d.Tile>>;

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

		ani = anims[2];
	}
}

class Window
{
	var wid:Int;
	var hei:Int;

	var o:h2d.Object;
	var t:h2d.Text;
	var btn:h2d.Bitmap;
	var btn_t:h2d.Text;

	public var destroyed = false;

	public function new(wid:Int, hei:Int)
	{
		this.wid = wid;
		this.hei = hei;
	}

	public function ready()
	{
		o = new h2d.Object();

		var bg = new h2d.ScaleGrid(Assets.getSprite(PopupPatch), 7, 7, 7, 7, o);
		bg.width = wid;
		bg.height = hei;

		t = new h2d.Text(Assets.getFont(CelticTime16), o);
		t.maxWidth = wid - 18;
		t.x = 9;
		t.y = 3;

		btn = new h2d.Bitmap(Assets.getSprite(WinSmallBtn), o);
		btn.x = wid - 25;
		btn.y = hei - 10;

		btn_t = new h2d.Text(Assets.getFont(CelticTime16), btn);
		btn_t.textAlign = Center;
		btn_t.x = btn.getSize().width * 0.5 + 1;
		btn_t.y = -1;
		btn_t.text = 'x';

		t.text = 'Finish with a score of 200 to win.';
		t.text = t.splitText(t.text);

		engine.Game.instance.render(Hud, o);
	}

	public function dispose()
	{
		o.remove();
	}

	public function update(frame:Frame)
	{
		if (GameAction.INTERACT.isPressed())
		{
			destroyed = true;
		}

		btn_t.text = GameAction.INTERACT.getName();
	}

	public function postupdate()
	{
		btn.y = hei - 9 - Math.ceil(Math.sin(engine.Game.instance.frame.elapsed * 10)) * 2;
	}
}
