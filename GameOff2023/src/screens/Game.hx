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
//

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

	/**
		0 => light
		1 => fog
	**/
	var fog:pirhana.Grid2D<Int>;

	var player:Mob;

	var dirx = [0, 0, -1, 1, 1, 1, -1, -1];
	var diry = [-1, 1, 0, 0, -1, 1, 1, -1];
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

	var wait:Float = 0;

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

		// tile cleanup
		if (tiles != null)
		{
			for (tile in tiles)
			{
				tile.remove();
			}
		}
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
		fog = new pirhana.Grid2D(_lvl.width, _lvl.height, (x, y) -> 1);

		pausefollow = false;
		player = addMob(Player, 5, 5);
		drawScroller(1);

		addMob(Shrimp, 11, 10);
		addMob(Shrimp, 8, 7);

		game.render(Hud, fade);
		fade.alpha = 1;
		fadet = 1;

		unfog(player.cx, player.cy);

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
		// types
		// sight = check for sight
		// ignoreplayer = checkmob but ignore player
		// checkmob = mobs block path

		if (!_lvl.inBounds(cx, cy))
		{
			return false;
		}
		if (mode == 'sight')
		{
			return !_lvl.getTile(cx, cy).fget(BlockSight);
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

	// player only
	function moveMob(mob:Mob, dir:Direction, mode:String = '')
	{
		mob.dir = dir;

		var dx = dir.dx;
		var dy = dir.dy;
		var destx = mob.cx + dx;
		var desty = mob.cy + dy;

		pt = 0;
		_upd = update_pturn;

		if (isWalkable(destx, desty, "checkmob"))
		{
			mobwalk(mob, dx, dy);
			pt = 0;
			_upd = update_pturn;
		}
		else
		{
			pausefollow = true;
			mobbump(mob, dx, dy);
			pt = 0;
			_upd = update_pturn;

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
		unfog(player.cx, player.cy);
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

		wait = 10;

		go_text = new h2d.Text(Assets.getFont(CelticTime16));
		go_text.textAlign = Center;
		go_text.text = '';
		go_text.visible = false;

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
		go_text.visible = fadet == 1;
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

	function mov_walk(mob:Mob)
	{
		mob.ox = mob.sx * (1 - pt);
		mob.oy = mob.sy * (1 - pt);
	}

	function mov_bump(mob:Mob)
	{
		var time = pt < 0.5 ? pt : 1 - pt;
		mob.ox = mob.sx * time;
		mob.oy = mob.sy * time;
	}

	function update_pturn(frame:Frame)
	{
		updateBtnBuffer();

		pt = Math.min(pt + 0.125 * frame.tmod, 1);

		if (player.mov != null)
		{
			player.mov(player);
		}

		// update_ai(frame);

		if (pt == 1)
		{
			player.ox = 0;
			player.oy = 0;
			pt = 0;
			_upd = update_game;

			if (checkEnd())
			{
				doGameOver();
			}
			else
			{
				doAI();
			}
		}
	}

	function update_ai(frame:Frame)
	{
		pt = Math.min(pt + 0.2 * frame.tmod, 1);
		for (mob in mobs)
		{
			if (mob == player || mob.dead)
			{
				continue;
			}
			if (mob.mov != null)
			{
				mob.mov(mob);
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
		switch (type)
		{
			case Shrimp:
				mob.task = ai_wait;
			case _:
		}
		mobs.push(mob);
		game.render(Actors, mob.sprite);
		return mob;
	}

	function addFloat(txt:String, x:Float, y:Float, color:Int = 0xffffff)
	{
		var f = {
			txt: new h2d.Text(Assets.getFont(CelticTime16)),
			x: x,
			y: y,
			ty: y - 20,
			t: 0.0
		};
		f.txt.filter = new PixelOutline(0, 1, false);
		f.txt.text = txt;
		f.txt.textAlign = Center;
		f.txt.textColor = color;
		f.txt.x = x;
		f.txt.y = y;
		game.render(Overlay, f.txt);
		floats.push(f);
		return f;
	}

	function updateFloats(frame:Frame)
	{
		for (f in floats.iterator())
		{
			f.y += (f.ty - f.y) / 20;
			f.t += Math.pow(1, frame.tmod);
			if (f.t > 50)
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

	function drawScroller(mult = 0.2)
	{
		if (pausefollow)
			return;
		var destx = (Const.VIEW_WID_2 - player.sprite.x) - game.layers.scroller.x;
		var desty = (Const.VIEW_HEI_2 - player.sprite.y) - game.layers.scroller.y;
		game.layers.scroller.x += destx * mult * game.frame.tmod;
		game.layers.scroller.y += desty * mult * game.frame.tmod;
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

		if (wait > 0)
		{
			wait -= Math.pow(1, frame.tmod);
			return;
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

		// fog
		_lvl.each((x, y, tile) ->
		{
			tiles[y * _lvl.width + x].visible = fog.get(x, y) == 0;
			var mob = getMob(x, y);
			if (mob != null)
			{
				mob.sprite.visible = fog.get(x, y) == 0;
			}
		});

		game.layers.ysort(Actors);
	}

	function ai_wait(mob:Mob)
	{
		if (cansee(player, mob, mob.los))
		{
			mob.task = ai_attack;
			mob.targetx = player.cx;
			mob.targety = player.cy;
			var f = addFloat('!', mob.cx * Const.TILE_WID + Const.TILE_WID_2, mob.cy * Const.TILE_HEI, 0xf6c65e);
			f.txt.scale(2);
			return true;
		}
		return false;
	}

	function ai_attack(mob:Mob)
	{
		// attack block
		// todo:
		// attack player if stronger
		// do nothing if weakers
		if (dist(mob.cx, mob.cy, player.cx, player.cy) <= 1)
		{
			var dx = player.cx - mob.cx;
			var dy = player.cy - mob.cy;
			mob.dir = engine.utils.Direction.fromDeltas(dx, dy);
			mobbump(mob, dx, dy);
			hitmob(mob, player);
			return true;
		}

		if (cansee(player, mob, mob.los))
		{
			mob.targetx = player.cx;
			mob.targety = player.cy;
		}

		if (mob.cx == mob.targetx && mob.cy == mob.targety)
		{
			mob.task = ai_wait;
			addFloat('?', mob.cx * Const.TILE_WID + Const.TILE_WID_2, mob.cy * Const.TILE_HEI, 0xf6c65e);
			return true;
		}

		// move block
		// gets the best direction
		var bdst = 999.0;
		var bdx = 0;
		var bdy = 0;

		for (i in 0...4)
		{
			var dx = dirx[i];
			var dy = diry[i];
			var dst = dist(mob.cx + dx, mob.cy + dy, mob.targetx, mob.targety);

			if (isWalkable(mob.cx + dx, mob.cy + dy, 'checkmob') && dst < bdst)
			{
				bdst = dst;
				bdx = dx;
				bdy = dy;
			}
		}
		mobwalk(mob, bdx, bdy);
		// reaquire target?
		mob.dir = engine.utils.Direction.fromDeltas(bdx, bdy);
		return true;
	}

	function doAI()
	{
		var moving = false;

		for (mob in mobs)
		{
			if (mob == player || mob.dead)
			{
				continue;
			}

			mob.resetMovement();
			moving = mob.task(mob) || moving;
		}

		if (moving)
		{
			pt = 0;
			_upd = update_ai;
		}
	}

	function dist(fx, fy, tx, ty)
	{
		return Math.sqrt((fx - tx) * (fx - tx) + (fy - ty) * (fy - ty));
	}

	function los(x1, y1, x2, y2)
	{
		var sx = 0;
		var sy = 0;
		var dx = 0;
		var dy = 0;

		if (dist(x1, y1, x2, y2) == 1)
			return true;

		sx = x1 < x2 ? 1 : -1;
		sy = y1 < y2 ? 1 : -1;
		dx = x1 < x2 ? x2 - x1 : x1 - x2;
		dy = y1 < y2 ? y2 - y1 : y1 - y2;

		var err = dx - dy;
		var e2 = 0.0;

		while (!(x1 == x2 && y1 == y2))
		{
			if (!isWalkable(x1, y1, "sight"))
				return false;
			e2 = err + err;
			// first = false;
			if (e2 > -dy)
			{
				err -= dy;
				x1 += sx;
			}
			if (e2 < dx)
			{
				err += dx;
				y1 += sy;
			}
		}

		return true;
	}

	function unfog(cx:Int, cy:Int)
	{
		// for (y in 0...fog.hei)
		// {
		// 	for (x in 0...fog.wid)
		// 	{
		// 		fog.set(x, y, 1);
		// 	}
		// }

		_lvl.each((x, y, tile) ->
		{
			if (fog.get(x, y) > 0 && los(x, y, cx, cy) && dist(cx, cy, x, y) < player.los)
			{
				unfogtile(x, y);
			}
		});
	}

	function unfogtile(cx:Int, cy:Int)
	{
		fog.set(cx, cy, 0);
		if (isWalkable(cx, cy, 'sight'))
		{
			for (i in 0...4)
			{
				var dx = dirx[i];
				var dy = diry[i];
				if (!isWalkable(cx + dx, cy + dy, "sight"))
				{
					fog.set(cx + dx, cy + dy, 0);
				}
			}
		}
	}

	function cansee(mob1:Mob, mob2:Mob, sight:Int = 99)
	{
		if (dist(mob1.cx, mob1.cy, mob2.cx, mob2.cy) < sight)
		{
			return los(mob1.cx, mob1.cy, mob2.cx, mob2.cy);
		}
		return false;
	}
}
