package screens;

import engine.Frame;

class Title extends engine.Screen
{
	var bg:h2d.Bitmap;
	var press:h2d.Text;

	public function new() {}

	override function ready()
	{
		super.ready();

		haxe.Timer.delay(() -> game.audio.playMusic(Assets.getMusic(Title)), 250);

		bg = new h2d.Bitmap(Assets.getSprite(TitleBg));
		bg.x = Const.VIEW_WID_2;
		bg.y = Const.VIEW_HEI_2;
		bg.scaleX = 3;
		bg.scaleY = 3;

		press = new h2d.Text(Assets.getFont(CelticTime16));
		press.textAlign = Center;
		press.text = '- press ${GameAction.INTERACT.getName()} to begin -';
		press.y = 210;
		press.x = 90;

		game.render(Background, bg);
		game.render(Background, press);
	}

	override function update(frame:Frame)
	{
		super.update(frame);

		bg.scaleX = Math.max(bg.scaleX - (bg.scaleX - 1) * 0.2 * frame.tmod, 1);
		bg.scaleY = Math.max(bg.scaleY - (bg.scaleY - 1) * 0.2 * frame.tmod, 1);

		if (GameAction.INTERACT.isPressed())
		{
			game.screens.set(new Game());
			game.audio.playSfx(Assets.getSfx(MenuBtn));
		}
	}

	override function postupdate()
	{
		super.postupdate();
	}

	override function dispose()
	{
		super.dispose();
		game.layers.clearAll();
	}
}
