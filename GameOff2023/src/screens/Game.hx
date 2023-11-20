package screens;

import engine.Frame;
import engine.Screen;
import engine.utils.Direction;
import h3d.col.HeightMap;
import h3d.shader.GpuParticle;

/**
	NOTES:
	-- Slow movements due to enemy AI taking a second.
	-- enemy will kill you before you get to a location.
**/
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
		}>;

	var mobsDead:Array<{mob:Mob, dur:Float}>;
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

	var fadet:Float;
	var fade:h2d.Bitmap;

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

		fade = new h2d.Bitmap(h2d.Tile.fromColor(0x000000, Const.VIEW_WID, Const.VIEW_HEI));

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
		mobsDead = [];
		floats = [];
		player = addMob(Player, 5, 5);

		addMob(Shrimp, 11, 10);
		addMob(Shrimp, 8, 7);

		game.render(Hud, fade);
		fade.alpha = 1;
		fadet = 1;

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

	function isWalkable(cx:Int, cy:Int, mode:String)
	{
		if (!_lvl.inBounds(cx, cy))
		{
			return false;
		}
		if (_lvl.getTile(cx, cy).fget(Col))
		{
			return false;
		}

		var mob = getMob(cx, cy);
		if (mob != null)
		{
			if (mode == 'checkmob' || (mode == 'ignoreplayer' && mob != player))
			{
				return false;
			}
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

	function moveMob(mob:Mob, dir:Direction, mode:String = '')
	{
		mob.dir = dir;

		var dx = dir.dx;
		var dy = dir.dy;
		var destx = mob.cx + dx;
		var desty = mob.cy + dy;

		pt = 0;
		_upd = update_pturn;

		if (isWalkable(destx, desty, mode))
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
			// atker dies
			def.flash = 15;
			def.dead = true;
			atk.score += def.score;
			var x = def.cx * Const.TILE_WID + Const.TILE_WID_2;
			var y = def.cy * Const.TILE_HEI;
			addFloat('+${def.score}', x, y, 0xb0d07e);

			// kill the mob
			mobsDead.push({mob: def, dur: 10});
			mobs.remove(def);
		}
		else
		{
			def.flash = 15;
			def.dead = true;
			atk.score += def.score;
			var x = def.cx * Const.TILE_WID + Const.TILE_WID_2;
			var y = def.cy * Const.TILE_HEI + Const.TILE_HEI_2 - 5;
			addFloat('+${def.score}', x, y, 0xb0d07e);

			// kill the mob
			mobsDead.push({mob: def, dur: 10});
			mobs.remove(def);
		}
	}

	function checkEnd()
	{
		return player.dead;
	}

	var go_text:h2d.Text;

	function doGameOver()
	{
		_upd = update_gameover;
		_drw = postupdate_gameover;

		fadet = 0;

		go_text = new h2d.Text(Assets.getFont(CelticTime16));
		go_text.textAlign = Center;
		go_text.text = '';

		game.render(Hud, fade);
		game.render(Hud, go_text);
	}

	function update_gameover(frame:Frame)
	{
		if (fadet != 1)
		{
			fadet = Math.min(1, fadet + Math.pow(0.1, frame.tmod));
			return;
		}
		if (game.inputs.isAnyPressed())
		{
			cleanup();
			startgame();
			_upd = update_game;
			_drw = postupdate_game;
			go_text.remove();
		}
	}

	function cleanup()
	{
		for (mob in mobs)
		{
			mob.sprite.remove();
		}

		for (float in floats)
		{
			float.txt.remove();
		}
	}

	function postupdate_gameover()
	{
		go_text.text = 'You lost!\n\nYou have been hit by a mob\nwith a higher score than you.\n\n press any ';
		go_text.text += game.inputs.isGamepad ? 'button' : 'key';
		go_text.x = Const.VIEW_WID_2;
		go_text.y = Const.VIEW_HEI_2 - 40;
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
		// update_ai(frame);

		if (pt == 1)
		{
			player.ox = 0;
			player.oy = 0;

			if (checkEnd())
			{
				doGameOver();
			}
			else
			{
				pt = 0;
				doAI();
				_upd = update_ai;
			}
		}
	}

	function update_ai(frame:Frame)
	{
		pt = Math.min(pt + 0.128 * frame.tmod, 1);
		for (mob in mobs)
		{
			if (mob == player || mob.dead)
			{
				continue;
			}
			if (mob.mov != null)
			{
				mob.mov(mob, pt);
			}
		}

		if (pt == 1)
		{
			_upd = update_game;
			if (checkEnd())
			{
				doGameOver();
			}
		}
	}

	function update_game(frame:Frame)
	{
		if (fadet != 0)
		{
			fadet = Math.max(0, fadet - Math.pow(0.2, frame.tmod));
			trace(fadet);
			return;
		}
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
		game.render(Overlay, f.txt);
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
			moveMob(player, dirs[btn], 'checkmob');
			// doAI();
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

	function postupdateFade()
	{
		fade.alpha = fadet;
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
		mob.score_o.text = '${mob.score}';
		mob.score_o.x = mob.sprite.getSize().width * 0.5 + mob.sprite.tile.dx;
		mob.score_o.y = mob.sprite.tile.dy - 10;
	}

	function postupdateMobs()
	{
		for (mob in mobs)
		{
			mob.sprite.tile = getFrame(mob.ani);
		}
		for (d in mobsDead)
		{
			// since we only do 1 hits, only them can flash!
			d.mob.sprite.colorAdd = d.mob.flash == 0 ? d.mob.baseColor : d.mob.flashColor;
			d.mob.sprite.visible = Math.sin(game.frame.frames * 8) > 0 && d.dur > 0;
		}
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

		for (data in mobsDead.iterator())
		{
			var mob = data.mob;
			mob.flash = Math.max(mob.flash - Math.pow(1, frame.tmod), 0);
			data.dur = Math.max(data.dur - Math.pow(1, frame.tmod), 0);
			if (data.dur <= 0)
			{
				mobsDead.remove(data);
				mob.sprite.remove();
			}
		}

		_upd(frame);
	}

	override function postupdate()
	{
		super.postupdate();
		postupdateMobs();
		postupdateFade();
		_drw();
		drawWindows();
		drawFloats();
		game.layers.ysort(Actors);
	}

	// ===================================
	// pathfinding things
	// ===================================
	function doAI()
	{
		for (mob in mobs)
		{
			if (mob == player || mob.dead)
			{
				continue;
			}

			mob.resetMovement();

			if (dist(mob.cx, mob.cy, player.cx, player.cy) <= 1)
			{
				var dx = player.cx - mob.cx;
				var dy = player.cy - mob.cy;
				mob.dir = engine.utils.Direction.fromDeltas(dx, dy);

				mobbump(mob, dx, dy);
				hitmob(mob, player);
				// attack player if stronger
				// do nothing if weaker
				continue;
			}

			// gets the best direction
			var bdst = 999.0;
			var bdx = 0;
			var bdy = 0;

			for (i in 0...4)
			{
				var dx = dirx[i];
				var dy = diry[i];
				var dst = dist(mob.cx + dx, mob.cy + dy, player.cx, player.cy);

				if (isWalkable(mob.cx + dx, mob.cy + dy, 'checkmob') && dst < bdst)
				{
					bdst = dst;
					bdx = dx;
					bdy = dy;
				}
			}
			mobwalk(mob, bdx, bdy);
			mob.dir = engine.utils.Direction.fromDeltas(bdx, bdy);
		}
	}

	function dist(fx, fy, tx, ty)
	{
		return Math.sqrt((fx - tx) * (fx - tx) + (fy - ty) * (fy - ty));
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
