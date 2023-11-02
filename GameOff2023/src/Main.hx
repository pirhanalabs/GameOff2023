class Main extends engine.Application
{
	public static function main()
	{
		new Main(480, 270, true, 60);
	}

	override function start()
	{
		super.start();
		new GameAction(); // initialize the game actions
	}
}
