package engine;

import engine.inputs.InputManager;

class Game
{
	public static var instance(default, null):Game;

	public static function create(app:hxd.App)
	{
		if (instance == null)
		{
			new Game(app);
		}
		return instance;
	}

	public var app(default, null):hxd.App;
	public var layers(default, null):RenderLayerManager;
	public var screens(default, null):ScreenManager;
	public var inputs(default, null):InputManager;
	public var camera(default, null):Camera;
	public var frame(default, null):Frame;
	public var window(get, null):hxd.Window;
	public var audio(default, null):AudioManager;

	private final function new(app:hxd.App)
	{
		instance = this;
		this.app = app;
		layers = new RenderLayerManager();
		screens = new ScreenManager();
		inputs = new InputManager();
		frame = new Frame();
		camera = new Camera();
		audio = new AudioManager();
		app.s2d.addChild(layers.ob);
	}

	public function render(layer:RenderLayerManager.RenderLayerType, ob:h2d.Object)
	{
		layers.render(layer, ob);
	}

	@:allow(engine.Application)
	private function update()
	{
		frame.update();
		screens.current.update(frame);
		screens.current.postupdate();
		camera.update(frame);

		// this should maybe just be put inside inputs.update(frame)
		if (inputs.isAnyPadButtonPressed())
		{
			inputs.padLastTouched = true;
		}
		inputs.keyPressedLastFrame = false;
	}

	inline function get_window()
	{
		return hxd.Window.getInstance();
	}
}
