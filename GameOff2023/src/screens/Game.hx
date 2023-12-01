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
	var shrimpCount:Int = 0;
	var shrimpCountMax:Int = 0;
	var shrimpLabel:h2d.Text;

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
	var baits:Array<Mob>;
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
		GameAction.MOVE_RIGHT,
		GameAction.INTERACT
	];

	var win:Array<Window> = [];
	var winput:Array<Window> = [];
	var distmap:pirhana.Grid2D<Int>;

	var fadet:Float;
	var fade:h2d.Bitmap;

	var wait:Float = 0; // do
	var skipai = false;

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
		game.audio.playMusic(Assets.getMusic(MainTheme));
	}

	function startgame()
	{
		// load data
		var data = haxe.Json.parse(hxd.Res.map_json.entry.getText());
		var ents:Array<
			{
				x:Int,
				y:Int,
				id:Int,
				val:String,
			}> = data.entities;
		var ttiles:Array<{x:Int, y:Int, val:Int}> = data.tiles;

		_lvl = new Level(data.mapwid, data.maphei);

		for (t in ttiles)
		{
			_lvl.getTile(t.x, t.y).id = t.val;
		}

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
			var b = new h2d.Bitmap(Assets.getAnim(Env)[t.id]);
			b.x = t.x * Const.TILE_WID;
			b.y = t.y * Const.TILE_HEI;
			tiles.push(b);
			game.render(Ground, b);
		});

		mobs = [];
		baits = [];
		mobsDead = [];
		floats = [];
		fog = new pirhana.Grid2D(_lvl.width, _lvl.height, (x, y) -> 1);

		for (ent in ents)
		{
			switch (ent.val)
			{
				case 'player':
					player = addMob(Player, ent.x, ent.y);
				case 'vase1':
					addMob(Vase1, ent.x, ent.y);
				case 'vase2':
					addMob(Vase2, ent.x, ent.y);
				case _:
					if (StringTools.contains(ent.val, 'shrimp'))
					{
						var s = Std.parseInt(StringTools.replace(ent.val, 'shrimp', ''));
						var m = addMob(Shrimp, ent.x, ent.y);
						m.score = s;
						shrimpCountMax++;
					}
			}
		}

		pausefollow = false;
		drawScroller(1);

		shrimpLabel = new h2d.Text(Assets.getFont(BitFantasy16));
		// shrimpLabel.scale(2);
		shrimpLabel.text = '${shrimpCount}/${shrimpCountMax} Shrimps';
		shrimpLabel.x = 10;
		shrimpLabel.y = 5;
		game.render(Hud, shrimpLabel);

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

	function placeBait()
	{
		if (player.score == 0)
		{
			return;
		}
		if (!isWalkable(player.cx + player.dir.dx, player.cy + player.dir.dy, "checkmob"))
		{
			return;
		}
		var h = player.score * 0.5;
		var s = h;
		if (h % 1 != 0)
		{
			h = Math.floor(h);
			s = Math.ceil(s);
		}
		var m = addMob(Bait, player.cx + player.dir.dx, player.cy + player.dir.dy);
		m.score = Math.floor(s);
		player.score = Math.floor(h);
		baits.push(m);
		game.audio.playSfx(Assets.getSfx(BaitHurt));

		skipai = false;
		doAI();
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
			game.audio.playSfx(mob.move);
		}
		else
		{
			pausefollow = true;
			mobbump(mob, dx, dy);
			skipai = true;

			var other = getMob(destx, desty);
			if (other == null)
			{
				var t = _lvl.getTile(destx, desty);
				if (t.fget(Bmp))
				{
					trigger_bump(t, destx, desty);
					skipai = false;
				}
			}
			else
			{
				skipai = false;
				if (other.score <= mob.score && other.type == Shrimp)
				{
					shrimpCount++;
				}
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
		if (atk.score < def.score && def.dangerous)
		{
			// atker dies
			atk.flash = 15;
			atk.dead = true;
			def.score += atk.score;
			var x = atk.cx * Const.TILE_WID + Const.TILE_WID_2;
			var y = atk.cy * Const.TILE_HEI;
			addFloat('+${atk.score}', x, y, 0xb0d07e);

			// kill the mob
			game.audio.playSfx(atk.hurt);
			mobsDead.push({mob: atk, dur: 10});
			mobs.remove(atk);
			baits.remove(atk);
		}
		else
		{
			// def dies
			def.flash = 15;
			def.dead = true;
			atk.score += def.score;
			game.audio.playSfx(def.hurt);
			var x = def.cx * Const.TILE_WID + Const.TILE_WID_2;
			var y = def.cy * Const.TILE_HEI + Const.TILE_HEI_2 - 5;
			addFloat('+${def.score}', x, y, 0xb0d07e);

			// kill the mob
			mobsDead.push({mob: def, dur: 10});
			mobs.remove(def);
			baits.remove(def);
		}
	}

	function checkEnd()
	{
		return player.dead || shrimpCount == shrimpCountMax;
	}

	var go_text:h2d.Text;
	var winner:Bool = false;

	function doGameOver()
	{
		_upd = update_gameover;
		_drw = postupdate_gameover;

		winner = shrimpCount == shrimpCountMax;

		fadet = 0;

		wait = 10;

		game.audio.playMusic(Assets.getMusic(GameOver));

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
			if (winner)
			{
				game.screens.set(new Title());
			}
			else
			{
				cleanup();
				startgame();
				_upd = update_game;
				_drw = postupdate_game;
				go_text.remove();
			}
			game.audio.playSfx(Assets.getSfx(Confirm));
		}
	}

	function cleanup()
	{
		shrimpLabel.remove();
		shrimpCount = 0;
		shrimpCountMax = 0;

		for (mob in mobs)
		{
			mob.sprite.remove();
		}

		for (bait in baits)
		{
			bait.sprite.remove();
		}

		for (float in floats)
		{
			float.txt.remove();
		}
	}

	function postupdate_gameover()
	{
		go_text.visible = fadet == 1;

		if (!winner)
		{
			go_text.text = 'You lost!\n\nYou have been hit by a mob\nwith a higher score than you.\n\nYou can place shrimp baits by pressing ${GameAction.INTERACT.getName()}\n\n press any ';
			go_text.text += game.inputs.isGamepad ? 'button' : 'key';
			go_text.text += ' to continue';
		}
		else
		{
			go_text.text = 'Congratulation!\n\nThe Order of Shrimp Hunters salute your brilliant service.\nShrimps will no longer be a threat in this region.';
			go_text.text += '\n\nPress any';
			go_text.text += game.inputs.isGamepad ? 'button' : 'key';
			go_text.text += ' to continue';
		}

		go_text.x = Const.VIEW_WID_2;
		go_text.y = Const.VIEW_HEI_2 - 60;
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

		if (pt == 1)
		{
			player.ox = 0;
			player.oy = 0;
			pt = 0;
			_upd = update_game;

			astar(player.cx, player.cy);
			if (checkEnd())
			{
				doGameOver();
			}
			else
			{
				if (!skipai)
				{
					doAI();
				}
			}
			skipai = false;
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
		if (btn == 4)
		{
			placeBait();
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
		var desty = (Const.VIEW_HEI_2 - player.sprite.y) - game.layers.scroller.y + 32;
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

		if (mob.sprite.tile != null)
		{
			mob.scorebg.x = mob.sprite.getSize().width * 0.5 + mob.sprite.tile.dx;
			mob.scorebg.y = mob.sprite.tile.dy - 8;
		}
		else
		{
			mob.scorebg.x = mob.sprite.getSize().width * 0.5;
			mob.scorebg.y = -8;
		}

		mob.score_o.text = '${mob.score}';
		// mob.score_o.x = mob.sprite.getSize().width * 0.5 + mob.sprite.tile.dx;
		// mob.score_o.y = mob.sprite.tile.dy - 10;
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
		#if debug
		if (hxd.Key.isDown(hxd.Key.SHIFT) && hxd.Key.isPressed(hxd.Key.E))
		{
			game.screens.set(new screens.LevelEditor());
			return;
		}
		#end

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

	override function dispose()
	{
		super.dispose();
		game.layers.scroller.x = 0;
		game.layers.scroller.y = 0;
		game.layers.clearAll();
	}

	override function postupdate()
	{
		super.postupdate();
		postupdateMobs();
		postupdateFade();
		_drw();
		drawWindows();
		drawFloats();

		// tile things
		_lvl.each((x, y, tile) ->
		{
			var t = tiles[y * _lvl.width + x];
			t.visible = fog.get(x, y) == 0;
			t.tile = getFrame(tile.ani);

			var mob = getMob(x, y);
			if (mob != null)
			{
				mob.sprite.visible = fog.get(x, y) == 0;
			}
		});

		game.layers.ysort(Actors);
	}

	function chasebait(mob:Mob)
	{
		if (mob.target != null && mob.target.type == Bait)
			return false;

		for (bait in baits)
		{
			if (cansee(bait, mob, mob.los))
			{
				mob.target = bait;
				mob.targetx = bait.cx;
				mob.targety = bait.cy;
				return true;
			}
		}
		return false;
	}

	function ai_wait(mob:Mob)
	{
		if (chasebait(mob))
		{
			mob.task = ai_attack;
			var f = addFloat('baited!', mob.cx * Const.TILE_WID + Const.TILE_WID_2, mob.cy * Const.TILE_HEI, 0xf6c65e);
			game.audio.playSfx(Assets.getSfx(ShrimpAlert));
			mob.runaway = false;
			return true;
		}

		if (cansee(player, mob, mob.los))
		{
			mob.task = ai_attack;
			mob.target = player;
			mob.targetx = player.cx;
			mob.targety = player.cy;
			mob.runaway = player.score > mob.score;
			var f = addFloat(mob.runaway ? 'scared!' : 'hungry!', mob.cx * Const.TILE_WID + Const.TILE_WID_2, mob.cy * Const.TILE_HEI, 0xf6c65e);
			game.audio.playSfx(Assets.getSfx(ShrimpAlert));
			return true;
		}
		return false;
	}

	function ai_attack(mob:Mob)
	{
		// chase bait if one comes in view
		if (chasebait(mob))
		{
			mob.task = ai_attack;
			var f = addFloat('baited!', mob.cx * Const.TILE_WID + Const.TILE_WID_2, mob.cy * Const.TILE_HEI, 0xf6c65e);
			game.audio.playSfx(Assets.getSfx(ShrimpAlert));
			mob.runaway = false;
			return true;
		}

		if (mob.target.dead)
		{
			mob.target = null;
			mob.task = ai_wait;
			ai_wait(mob);
			return false;
		}

		if (dist(mob.cx, mob.cy, mob.target.cx, mob.target.cy) <= 1 && (mob.target.type == Bait || mob.target.score < mob.score))
		{
			var dx = mob.target.cx - mob.cx;
			var dy = mob.target.cy - mob.cy;
			mob.dir = engine.utils.Direction.fromDeltas(dx, dy);
			mobbump(mob, dx, dy);
			hitmob(mob, mob.target);
			mob.task = ai_wait;
			mob.target = null;
			return true;
		}

		if (mob.cx == mob.targetx && mob.cy == mob.targety)
		{
			mob.task = ai_wait;
			addFloat('?', mob.cx * Const.TILE_WID + Const.TILE_WID_2, mob.cy * Const.TILE_HEI, 0xf6c65e);
			game.audio.playSfx(Assets.getSfx(ShrimpAlert));
			return false;
		}

		if (mob.runaway && (dist(mob.cx, mob.cy, mob.target.cx, mob.target.cy) > mob.los + 1 && !cansee(mob.target, mob, mob.los)))
		{
			mob.task = ai_wait;
			addFloat('?', mob.cx * Const.TILE_WID + Const.TILE_WID_2, mob.cy * Const.TILE_HEI, 0xf6c65e);
			game.audio.playSfx(Assets.getSfx(ShrimpAlert));
			return false;
		}

		var runaway = mob.target.score > mob.score;

		if (mob.runaway != runaway)
		{
			mob.runaway = runaway;
			addFloat(mob.runaway ? 'scared!' : 'hungry!', mob.cx * Const.TILE_WID + Const.TILE_WID_2, mob.cy * Const.TILE_HEI, 0xf6c65e);
			game.audio.playSfx(Assets.getSfx(ShrimpAlert));
			return false;
		}
		runaway ? astar(mob.target.cx, mob.target.cy) : astar(mob.targetx, mob.targety);
		var bdst = runaway ? -999 : 999.0;
		var bdx = 0;
		var bdy = 0;
		var candidates = [];

		for (i in 0...4)
		{
			var dx = dirx[i];
			var dy = diry[i];

			if (isWalkable(mob.cx + dx, mob.cy + dy, ''))
			{
				var dst = distmap.get(mob.cx + dx, mob.cy + dy);
				var cond = runaway ? dst > bdst : dst < bdst;

				if (cond)
				{
					candidates = [];
					bdst = dst;
				}
				if (dst == bdst)
				{
					candidates.push({dx: dx, dy: dy});
				}
			}
		}
		// this makes the mob wait rather than take undesireable directions
		for (cand in candidates.iterator())
		{
			var mob = getMob(mob.cx + cand.dx, mob.cy + cand.dy);

			if (mob != null)
			{
				candidates.remove(cand);
			}
		}
		if (candidates.length > 0)
		{
			var cand = pirhana.MathTools.pick(candidates);
			mobwalk(mob, cand.dx, cand.dy);
			game.audio.playSfx(mob.move);
			mob.dir = engine.utils.Direction.fromDeltas(bdx, bdy);
			if (cansee(player, mob, mob.los))
			{
				mob.targetx = mob.target.cx;
				mob.targety = mob.target.cy;
			}
			return true;
		}
		else if (!cansee(mob.target, mob))
		{
			mob.task = ai_wait;
			addFloat('?', mob.cx * Const.TILE_WID + Const.TILE_WID_2, mob.cy * Const.TILE_HEI, 0xf6c65e);
			game.audio.playSfx(Assets.getSfx(ShrimpAlert));
			return false;
		}
		return false;
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
			if (mob.task != null)
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
		// bresenham
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
			if (fog.get(x, y) > 0 && los(cx, cy, x, y) && dist(cx, cy, x, y) <= player.los)
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
		if (dist(mob1.cx, mob1.cy, mob2.cx, mob2.cy) <= sight)
		{
			return los(mob1.cx, mob1.cy, mob2.cx, mob2.cy);
		}
		return false;
	}

	function astar(cx:Int, cy:Int)
	{
		var candidates = [];
		var newcands = [];
		var step = 0;

		distmap = new pirhana.Grid2D(_lvl.width, _lvl.height, (x, y) -> -1);
		distmap.set(cx, cy, step);

		candidates.push({x: cx, y: cy});

		while (candidates.length > 0)
		{
			step++;
			newcands = [];
			for (c in candidates)
			{
				for (i in 0...4)
				{
					var dx = c.x + dirx[i];
					var dy = c.y + diry[i];
					if (_lvl.inBounds(dx, dy) && distmap.get(dx, dy) == -1)
					{
						distmap.set(dx, dy, step);

						if (isWalkable(dx, dy, ""))
						{
							newcands.push({x: dx, y: dy});
						}
					}
				}
			}
			candidates = newcands;
		}
	}
}
