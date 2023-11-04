package screens;

import engine.Frame;
import pirhana.MathTools;

class Adventure extends engine.Screen
{
	var level:Level;

	var tiles:Array<h2d.Bitmap> = [];

	var boptimer:Float = 0;
	var player:h2d.Object;
	var playerAnim:h2d.Anim;
	var shadow:h2d.Bitmap;
	var playerx:Int = 4;
	var playery:Int = 4;
	var playerdirid:Int = 1;

	var playeranim = [3, 0, 2, 1];
	var dirx = [0, 0, -1, 1];
	var diry = [-1, 1, 0, 0];
	var actions = [
		GameAction.MOVE_UP,
		GameAction.MOVE_DOWN,
		GameAction.MOVE_LEFT,
		GameAction.MOVE_RIGHT
	];

	public function new()
	{
		level = new Level();
	}

	/** triggers when the screen is entered **/
	override function ready()
	{
		player = new h2d.Object();
		shadow = new h2d.Bitmap(Assets.getSprite(PlayerShadow), player);
		shadow.x = 16;
		shadow.y = 22;
		playerAnim = new h2d.Anim(Assets.getAnim(Player), player);
		playerAnim.pause = true;
		playerAnim.y = 16;
		playerAnim.x = 16;
		playerdirid = 1;
		game.render(Actors, player);

		level.each((x, y, tile) ->
		{
			var t = new h2d.Bitmap();
			t.x = x * 32;
			t.y = y * 32;
			tiles.push(t);
			game.render(Ground, t);
		});
		calculateVisibility();
		updateVisible();
	}

	private function calculateVisibility()
	{
		level.each((x, y, tile) ->
		{
			tile.visible = false;
		});

		var dx = dirx[playerdirid];
		var dy = diry[playerdirid];
		var posx = playerx;
		var posy = playery;
		var tile = level.getTile(posx, posy);

		do
		{
			tile = level.getTile(posx, posy);
			tile.visible = true;

			for (n in level.getNeighbors(posx, posy))
			{
				if (!tile.hasFlag(SeeThrough))
				{
					continue;
				}
				if (n.hasFlag(SeeThrough))
				{
					n.visible = true;
					for (nn in level.getNeighbors(n.x, n.y))
					{
						if (!nn.hasFlag(SeeThrough))
						{
							nn.visible = true;
						}
					}
				}
				else if (!n.hasFlag(SeeThrough))
				{
					n.visible = true;
				}
			}

			posx += dx;
			posy += dy;
		}
		while (tile != null && tile.hasFlag(SeeThrough));
	}

	private function updateVisible()
	{
		level.each((x, y, tile) ->
		{
			tiles[y * level.width + x].tile = Assets.getAnim(Env)[tile.getTileId()];
		});
	}

	private function moveTo(x:Int, y:Int)
	{
		if (level.getTile(x, y).hasFlag(Collision))
		{
			return false;
		}
		playerx = x;
		playery = y;
		boptimer = 0;
		return true;
	}

	private function move(dx:Int, dy:Int)
	{
		moveTo(playerx + dx, playery + dy);
	}

	private function updateTurn(frame:Frame)
	{
		// do
	}

	/** triggers every frame, used to update data **/
	override function update(frame:Frame)
	{
		boptimer += frame.dt;

		for (i in 0...4)
		{
			if (actions[i].isPressed())
			{
				playerdirid = i;
				playerAnim.currentFrame = playeranim[playerdirid];
				move(dirx[i], diry[i]);
				calculateVisibility();
			}
		}
	}

	/** triggers every frame, used to update visuals **/
	override function postupdate()
	{
		updateVisible();

		player.x = playerx * Const.TILE_WID;
		player.y = playery * Const.TILE_HEI;

		var range = MathTools.range(Math.cos(boptimer * 2), -1, 1, 1, 0);
		playerAnim.y = 16 - pirhana.Tween.lerp(0, 8, pirhana.Tween.easeOut(range));
		shadow.scaleX = 1 - pirhana.Tween.lerp(0, 0.25, pirhana.Tween.easeOut(range));
	}
}
