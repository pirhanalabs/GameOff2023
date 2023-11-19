package engine.inputs;

/**
	Handles the input system of the game.
	At the moment it only handles a single gamepad at a time (singleplayer).
**/
class InputManager
{
	public var onDisconnect:Null<Void->Void>;
	public var onConnected:Null<Void->Void>;

	public var pad(default, null):hxd.Pad;

	private var enumBindings:Map<PadButton, Int>;

	public var isGamepad(get, never):Bool;

	private var _anyPadCheck = [
		PadButton.A, PadButton.B, PadButton.X, PadButton.Y, PadButton.LSTICK_PUSH, PadButton.RSTICK_PUSH, PadButton.LB, PadButton.LT, PadButton.RB,
		PadButton.RT, PadButton.START, PadButton.SELECT, PadButton.DPAD_DOWN, PadButton.DPAD_LEFT, PadButton.DPAD_RIGHT, PadButton.DPAD_UP
	];

	@:allow(engine.Game)
	public var padLastTouched(default, null):Bool = false;

	inline function get_isGamepad()
	{
		return pad.connected;
	}

	public function new()
	{
		pad = hxd.Pad.createDummy();
		updateEnumBindings();
		hxd.Pad.wait(_onPadConnected);
		Game.instance.window.addEventTarget(onEventTarget);
	}

	public function isAnyPadButtonPressed()
	{
		if (!pad.connected)
			return false;

		for (btn in _anyPadCheck)
		{
			if (pad.isPressed(getPadButtonValue(btn)))
			{
				return true;
			}
		}
		return false;
	}

	private function onEventTarget(e:hxd.Event)
	{
		switch (e.kind)
		{
			case EKeyUp, EKeyDown, EPush, ERelease:
				padLastTouched = false;
			case _:
		}
	}

	private function _onPadConnected(pad:hxd.Pad)
	{
		this.pad = pad;

		this.pad.onDisconnect = () ->
		{
			if (onDisconnect != null)
				onDisconnect();
		}

		if (onConnected != null)
		{
			onConnected();
		}

		updateEnumBindings();
	}

	private function updateEnumBindings()
	{
		enumBindings = new Map();

		enumBindings.set(PadButton.A, pad.config.A);
		enumBindings.set(PadButton.B, pad.config.B);
		enumBindings.set(PadButton.X, pad.config.X);
		enumBindings.set(PadButton.Y, pad.config.Y);

		enumBindings.set(PadButton.RB, pad.config.RB);
		enumBindings.set(PadButton.RT, pad.config.RT);
		enumBindings.set(PadButton.LB, pad.config.LB);
		enumBindings.set(PadButton.LT, pad.config.LT);

		enumBindings.set(PadButton.DPAD_UP, pad.config.dpadUp);
		enumBindings.set(PadButton.DPAD_DOWN, pad.config.dpadDown);
		enumBindings.set(PadButton.DPAD_RIGHT, pad.config.dpadRight);
		enumBindings.set(PadButton.DPAD_LEFT, pad.config.dpadLeft);

		enumBindings.set(PadButton.START, pad.config.start);
		enumBindings.set(PadButton.SELECT, pad.config.back);

		enumBindings.set(PadButton.LSTICK_PUSH, pad.config.analogClick);
		enumBindings.set(PadButton.RSTICK_PUSH, pad.config.ranalogClick);
	}

	public function getPadButtonValue(button:PadButton):Int
	{
		if (enumBindings.exists(button))
		{
			return enumBindings.get(button);
		}
		return -1;
	}

	/**
		Creates and returns a new input binding.
	**/
	public function createBinding(id:Int, key:Int, button:PadButton)
	{
		var binding = new InputBinding(this, id, key, button);
		return binding;
	}

	/**
		Returns weither or not the given input binding is pressed. 
		NOTE: This works only for keys and pressable buttons on gamepad.
	**/
	public function isPressed(binding:InputBinding)
	{
		// implement this
	}

	/**
		Returns weither or not the given input binding is down. 
		NOTE: This works only for keys and pressable buttons on gamepad.
	**/
	public function isDown(binding:InputBinding)
	{
		// implement this
	}

	/**
		Returns weither or not the given input binding is released. 
		NOTE: This works only for keys and pressable buttons on gamepad.
	**/
	public function isReleased(binding:InputBinding)
	{
		// implement this
	}
}
