class Main extends engine.Application
{
	public static function main()
	{
		new Main(480, 270, false, 60);
	}

	override function start()
	{
		super.start();
		engine.backgroundColor = 0x000000;
		Assets.initialize();
		new GameAction(); // initialize the game actions
		game.screens.set(new screens.Game());
	}
}
