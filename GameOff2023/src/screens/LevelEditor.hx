package screens;

import engine.Frame;
import hxd.res.Sound;
#if sys
import sys.FileSystem;
#end

class LevelEditor extends engine.Screen
{
	var entity_data:Array<String> = [
		"player", "door_fake", "door_real", "vase1", "vase2", "statue", "shrimp45", "shrimp10", "shrimp15", "shrimp25", "shrimp265", "shrimp55", "shrimp50",
		"shrimp100", "shrimp 500"
	];
	var tiles_data:Array<h2d.Tile>;
	var tiles_title:h2d.Text;
	var tiles_id:Int = 0;
	var tiles_bitmap:h2d.Bitmap;
	var selection:h2d.Object;
	var selection_x:Int = 0;
	var selection_y:Int = 0;

	// [y=>[x=>val]]
	var map_bitmaps:Map<Int, Map<Int, h2d.Bitmap>>;
	var map_labels:Map<Int, Map<Int, h2d.Text>>;
	var map_data:Map<Int, Map<Int, Int>>;
	var map_entities:Map<Int, Map<Int, Int>>;
	var layers:h2d.Layers;

	var entitymode:Bool = false;

	public function new() {}

	override function ready()
	{
		super.ready();

		map_data = [];
		map_entities = [];
		map_bitmaps = [];
		map_labels = [];

		tiles_data = Assets.getAnim(Env);
		tiles_bitmap = new h2d.Bitmap(null);
		tiles_title = new h2d.Text(Assets.getFont(CelticTime16));
		var s = new h2d.Graphics();
		s.lineStyle(1, 0xffffff);
		s.drawRect(0, 0, 32, 32);
		s.endFill();
		selection = s;

		layers = new h2d.Layers();

		tiles_bitmap.filter = new h2d.filter.Glow();
		tiles_bitmap.x = Const.VIEW_WID_2 - 16;
		tiles_bitmap.y = 16;

		tiles_title.textAlign = Center;
		tiles_title.x = Const.VIEW_WID_2;
		tiles_title.y = 0;

		game.render(Background, layers);
		game.render(Actors, selection);
		game.render(Actors, tiles_bitmap);
		game.render(Actors, tiles_title);

		updateTileId(0);

		load();

		game.window.addEventTarget(onWindowEvent);
	}

	function replaceVisualMap<T:h2d.Object>(map:Map<Int, Map<Int, T>>, x:Int, y:Int, val:T, layer:Int = -1)
	{
		var a = map.get(y);
		if (a == null)
		{
			map.set(y, a = [x => val]);
		}
		else
		{
			var v = a.get(x);
			if (v != null)
			{
				v.remove();
			}
			a.set(x, val);
		}
		layers.add(val, layer);
		val.x = x * Const.TILE_WID;
		val.y = y * Const.TILE_HEI;
	}

	function addToMap<T>(map:Map<Int, Map<Int, T>>, x:Int, y:Int, val:T)
	{
		var a = map.get(y);
		if (a == null)
		{
			map.set(y, a = []);
		}
		a.set(x, val);
	}

	function removeFromMap<T>(map:Map<Int, Map<Int, T>>, x:Int, y:Int)
	{
		var a = map.get(y);
		if (a == null)
		{
			return;
		}
		a.remove(x);
	}

	function removeVisualMap<T:h2d.Object>(map:Map<Int, Map<Int, T>>, x:Int, y:Int)
	{
		var a = map.get(y);
		if (a == null)
		{
			return;
		}
		var o = a.get(x);
		if (o == null)
		{
			return;
		}
		o.remove();
		a.remove(x);
	}

	override function dispose()
	{
		super.dispose();
		game.layers.clearAll();
		game.window.removeEventTarget(onWindowEvent);
	}

	function updateTileId(delta:Int, set:Int = -1)
	{
		tiles_id += delta;

		if (set >= 0)
		{
			tiles_id = set;
		}

		tiles_id = pirhana.extensions.IntExtension.clamp(tiles_id, 0, entitymode ? entity_data.length - 1 : tiles_data.length - 1);

		tiles_bitmap.visible = !entitymode;
		tiles_bitmap.tile = tiles_data[tiles_id];
		tiles_title.text = (entitymode ? entity_data[tiles_id] : tiles_data[tiles_id] + '');
	}

	function onWindowEvent(e:hxd.Event)
	{
		switch (e.kind)
		{
			case EWheel:
				updateTileId(pirhana.MathTools.sign(e.wheelDelta));
			case _:
		}
	}

	function load()
	{
		#if sys
		if (!FileSystem.exists('res/map.json'))
		{
			return;
		}
		var data = haxe.Json.parse(sys.io.File.getContent('res/map.json'));
		var tiles:Array<{x:Int, y:Int, val:Int}> = data.tiles;
		for (tile in tiles)
		{
			addToMap(map_data, tile.x, tile.y, tile.val);
			replaceVisualMap(map_bitmaps, tile.x, tile.y, new h2d.Bitmap(tiles_data[tile.val]), 0);
		}

		var ents:Array<
			{
				x:Int,
				y:Int,
				val:String,
				id:Int
			}> = data.entities;
		for (ent in ents)
		{
			addToMap(map_entities, ent.x, ent.y, ent.id);

			var t = new h2d.Text(Assets.getFont(CelticTime16));
			t.text = entity_data[ent.id];
			var p = new h2d.Graphics(t);
			p.beginFill(0xffffff);
			p.drawCircle(16, 16, 5, 10);
			p.endFill();
			replaceVisualMap(map_labels, ent.x, ent.y, t, 1);
		}
		#end
	}

	function save()
	{
		#if sys
		var data:Dynamic = {};

		for (y => col in map_data)
		{
			if (!col.keys().hasNext())
			{
				map_data.remove(y);
			}
		}

		var minx = 999999;
		var miny = 999999;
		var maxx = 0;
		var maxy = 0;

		for (y => col in map_data)
		{
			if (y < miny)
			{
				miny = y;
			}
			if (y > maxy)
			{
				maxy = y;
			}

			for (x => val in col)
			{
				if (x < minx)
				{
					minx = x;
				}
				if (x > maxx)
				{
					maxx = x;
				}
			}
		}

		data.tiles = [
			for (y => col in map_data)
				for (x => val in col)
					{x: x - minx, y: y - miny, val: val}
		];
		data.entities = [
			for (y => col in map_entities)
				for (x => val in col)
					{
						x: x - minx,
						y: y - miny,
						id: val,
						val: entity_data[val]
					}
		];
		data.mapwid = maxx - minx + 1;
		data.maphei = maxy - miny + 1;

		sys.io.File.saveContent('res/map.json', haxe.Json.stringify(data));
		#end
	}

	override function update(frame:Frame)
	{
		if (hxd.Key.isDown(hxd.Key.SHIFT))
		{
			if (hxd.Key.isPressed(hxd.Key.E))
			{
				game.screens.set(new screens.Game());
				return;
			}
			else if (hxd.Key.isPressed(hxd.Key.S))
			{
				save();
				return;
			}
		}

		if (hxd.Key.isPressed(hxd.Key.W))
		{
			selection_y -= 1;
		}
		if (hxd.Key.isPressed(hxd.Key.S))
		{
			selection_y += 1;
		}
		if (hxd.Key.isPressed(hxd.Key.A))
		{
			selection_x -= 1;
		}
		if (hxd.Key.isPressed(hxd.Key.D))
		{
			selection_x += 1;
		}
		if (hxd.Key.isPressed(hxd.Key.TAB))
		{
			entitymode = !entitymode;
			updateTileId(0);
		}
		if (hxd.Key.isPressed(hxd.Key.SPACE))
		{
			if (entitymode)
			{
				addToMap(map_entities, selection_x, selection_y, tiles_id);

				var t = new h2d.Text(Assets.getFont(CelticTime16));
				t.text = entity_data[tiles_id];
				var p = new h2d.Graphics(t);
				p.beginFill(0xffffff);
				p.drawCircle(16, 16, 5, 10);
				p.endFill();
				replaceVisualMap(map_labels, selection_x, selection_y, t, 1);
			}
			else
			{
				addToMap(map_data, selection_x, selection_y, tiles_id);
				replaceVisualMap(map_bitmaps, selection_x, selection_y, new h2d.Bitmap(tiles_data[tiles_id]), 0);
			}
		}
		if (hxd.Key.isPressed(hxd.Key.E))
		{
			if (entitymode)
			{
				removeFromMap(map_entities, selection_x, selection_y);
				removeVisualMap(map_labels, selection_x, selection_y);
			}
			else
			{
				removeFromMap(map_data, selection_x, selection_y);
				removeVisualMap(map_bitmaps, selection_x, selection_y);
			}
		}
		layers.x = Const.VIEW_WID_2 - 16 - selection_x * Const.TILE_WID;
		layers.y = Const.VIEW_HEI_2 - 16 - selection_y * Const.TILE_HEI;
		selection.x = Const.VIEW_WID_2 - 16;
		selection.y = Const.VIEW_HEI_2 - 16;

		super.update(frame);
	}

	override function postupdate()
	{
		super.postupdate();
	}
}
