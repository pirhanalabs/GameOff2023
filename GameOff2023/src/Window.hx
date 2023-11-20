import engine.Frame;

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
