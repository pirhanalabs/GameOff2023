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

	private final function new(app:hxd.App)
	{
		instance = this;
		this.app = app;
		layers = new RenderLayerManager();
		screens = new ScreenManager();
		inputs = new InputManager();
		frame = new Frame();
		camera = new Camera();
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
	}

	inline function get_window()
	{
		return hxd.Window.getInstance();
	}
}
