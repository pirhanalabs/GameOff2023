class Const
{
	public static final TILE_WID = 32;
	public static final TILE_HEI = 32;
	public static final TILE_WID_2 = 16;
	public static final TILE_HEI_2 = 16;

	public static var VIEW_WID(get, null):Int;
	public static var VIEW_HEI(get, null):Int;
	public static var VIEW_WID_2(get, null):Float;
	public static var VIEW_HEI_2(get, null):Float;

	inline static function get_VIEW_WID()
	{
		return engine.Application.VIEW_WID;
	}

	inline static function get_VIEW_WID_2()
	{
		return engine.Application.VIEW_WID_2;
	}

	inline static function get_VIEW_HEI()
	{
		return engine.Application.VIEW_HEI;
	}

	inline static function get_VIEW_HEI_2()
	{
		return engine.Application.VIEW_HEI_2;
	}
}
