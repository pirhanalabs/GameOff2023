import engine.Game;
import engine.inputs.InputBinding;
import engine.inputs.PadButton;

class GameAction
{
	public static var MOVE_UP:InputBinding;
	public static var MOVE_DOWN:InputBinding;
	public static var MOVE_LEFT:InputBinding;
	public static var MOVE_RIGHT:InputBinding;

	private static var _instance:GameAction;

	public function new()
	{
		if (_instance != null)
		{
			return;
		}
		_instance = this;

		MOVE_UP = Game.instance.inputs.createBinding(0, hxd.Key.W, PadButton.DPAD_UP);
		MOVE_DOWN = Game.instance.inputs.createBinding(1, hxd.Key.W, PadButton.DPAD_DOWN);
		MOVE_LEFT = Game.instance.inputs.createBinding(2, hxd.Key.W, PadButton.DPAD_LEFT);
		MOVE_RIGHT = Game.instance.inputs.createBinding(3, hxd.Key.W, PadButton.DPAD_RIGHT);
	}
}
