package engine;

class Application extends hxd.App
{
	public static var FPS(default, null):Int;
	public static var VIEW_SCALE(get, null):Float;
	public static var VIEW_WID(default, null):Int;
	public static var VIEW_HEI(default, null):Int;
	public static var VIEW_WID_2(default, null):Float;
	public static var VIEW_HEI_2(default, null):Float;

	private inline static function get_VIEW_SCALE()
	{
		if (VIEW_WID > VIEW_HEI)
		{
			return Game.instance.app.s2d.viewportScaleY;
		}
		return Game.instance.app.s2d.viewportScaleX;
	}

	public static function exit()
	{
		#if sys
		Sys.exit(0);
		#end
	}

	private static var _instance:Application;

	private var game:Game;
	private var intscale:Bool;

	private function new(viewportw, viewporth, intscale = false, fps = 60)
	{
		if (_instance != null)
		{
			throw 'There can be only one instance of Application';
		}
		_instance = this;

		FPS = fps;
		VIEW_WID = viewportw;
		VIEW_HEI = viewporth;
		VIEW_WID_2 = VIEW_WID * 0.5;
		VIEW_HEI_2 = VIEW_HEI * 0.5;
		this.intscale = intscale;

		super();
	}

	override function init()
	{
		super.init();

		// initialize scalemode
		s2d.scaleMode = LetterBox(VIEW_WID, VIEW_HEI, intscale, Center, Center);

		_initEngine();

		game = Game.create(this);
		haxe.Timer.delay(function()
		{
			start();
		}, 1);
	}

	function _initEngine()
	{
		engine.backgroundColor = 0xff << 24 | 0x111133;

		#if hl
		hl.UI.closeConsole();
		hl.Api.setErrorHandler(onCrash);
		#end

		#if (hl && debug)
		hxd.Res.initLocal();
		#else
		hxd.Res.initEmbed();
		#end

		// fix an audio bug/ sound chipping
		haxe.MainLoop.add(() -> {});
		// initialize the sound manager to avoid freeze on first sound playback.
		hxd.snd.Manager.get();
		// ignore heavy sound manager init frame.
		hxd.Timer.skip();

		// framerate
		hxd.Timer.smoothFactor = 0.4;
		hxd.Timer.wantedFPS = FPS;
	}

	private function onCrash(err:Dynamic)
	{
		var title = 'Fatal Error';
		var msg = 'Error:${Std.string(err)}';
		var flags:haxe.EnumFlags<hl.UI.DialogFlags> = new haxe.EnumFlags();
		flags.set(IsError);

		hl.UI.dialog(title, msg, flags);

		hxd.System.exit();
	}

	private function start()
	{
		// override this in Main
	}

	override function update(dt:Float)
	{
		super.update(dt);
		game.update();
	}
}
