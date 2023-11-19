import engine.Game;
import engine.inputs.InputBinding;
import engine.inputs.PadButton;

typedef Input = InputBinding;

class GameAction
{
	public static var NONE(default, null):Input;
	public static var MOVE_UP(default, null):Input;
	public static var MOVE_DOWN(default, null):Input;
	public static var MOVE_LEFT(default, null):Input;
	public static var MOVE_RIGHT(default, null):Input;
	public static var INTERACT(default, null):Input;
	public static var CANCEL(default, null):Input;

	public static var INPUT_LIST(default, null):Array<Input>;

	private static var _instance:GameAction;

	public function new()
	{
		if (_instance != null)
		{
			return;
		}
		_instance = this;

		NONE = Game.instance.inputs.createBinding(-1, -1, PadButton.None);
		MOVE_UP = Game.instance.inputs.createBinding(0, hxd.Key.W, PadButton.DPAD_UP);
		MOVE_LEFT = Game.instance.inputs.createBinding(1, hxd.Key.A, PadButton.DPAD_LEFT);
		MOVE_DOWN = Game.instance.inputs.createBinding(2, hxd.Key.S, PadButton.DPAD_DOWN);
		MOVE_RIGHT = Game.instance.inputs.createBinding(3, hxd.Key.D, PadButton.DPAD_RIGHT);
		INTERACT = Game.instance.inputs.createBinding(4, hxd.Key.X, PadButton.A);
		CANCEL = Game.instance.inputs.createBinding(4, hxd.Key.C, PadButton.B);

		INPUT_LIST = [MOVE_UP, MOVE_DOWN, MOVE_LEFT, MOVE_RIGHT, INTERACT];
	}
}
