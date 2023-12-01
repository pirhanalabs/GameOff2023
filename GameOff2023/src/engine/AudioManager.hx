package engine;

class AudioManager
{
	public var master_vol_mod(default, null):Float = 1;
	public var master_mus_mod(default, null):Float = 1;
	public var master_sfx_mod:Float = 1;

	public var manager:hxd.snd.Manager;

	private var music:hxd.snd.Channel;

	public function new()
	{
		manager = hxd.snd.Manager.get();
	}

	public function playSfx(sfx:hxd.res.Sound, vol:Float = 1)
	{
		if (sfx == null)
			return;
		var c = manager.play(sfx);
		c.volume = vol * master_sfx_mod;
	}

	public function playMusic(music:hxd.res.Sound)
	{
		if (music == null)
			return;
		if (this.music != null)
		{
			this.music.stop();
		}
		this.music = manager.play(music);
		this.music.volume = master_mus_mod;
		this.music.loop = true;
	}

	inline function set_master_vol_mod(val:Float)
	{
		if (music != null)
		{
			music.volume = master_mus_mod;
		}
		return master_vol_mod = val;
	}

	inline function set_master_mus_mod(val:Float)
	{
		if (music != null)
		{
			music.volume = master_mus_mod;
		}
		return master_mus_mod = val;
	}
}
