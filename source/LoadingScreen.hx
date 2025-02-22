import haxe.crypto.Md5;
import haxe.Exception;
import openfl.utils.Assets;
import hscript.Interp;
import sys.thread.Thread;
import sys.io.File;
import sys.FileSystem;
import lime.system.System;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

typedef LoadingShit =
{
	var name:String;
	var func:Void->Void;
}

class LoadingScreen extends FlxState
{
	var loadSections:Array<LoadingShit> = [];
	var step:Int = 0;
	var loadingText:FlxText;
	var switchin:Bool = false;
	var bg:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();

	var w = 775;
	var h = 550;

	public override function create()
	{
		super.create();

		var md5 = null;

		// can't put this into main cause of conflicting headers shit (thank you hxcpp)
		HeaderCompilationBypass.darkMode();
		HeaderCompilationBypass.addFileAssoc();

		var loadingThingy = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK, true);
		loadingThingy.pixels.lock();
		var color1 = FlxColor.fromRGB(0, 66, 119);
		var color2 = FlxColor.fromRGB(86, 0, 151);
		for (x in 0...loadingThingy.pixels.width)
		{
			for (y in 0...loadingThingy.pixels.height)
			{
				loadingThingy.pixels.setPixel32(x, y,
					FlxColor.fromRGB(Std.int(FlxMath.remapToRange(((y / loadingThingy.pixels.height) * 1), 0, 1, color1.red, color2.red)),
						Std.int(FlxMath.remapToRange(((y / loadingThingy.pixels.height) * 1), 0, 1, color1.green, color2.green)),
						Std.int(FlxMath.remapToRange(((y / loadingThingy.pixels.height) * 1), 0, 1, color1.blue, color2.blue))));
			}
		}
		loadingThingy.pixels.unlock();
		add(loadingThingy);

		var bgLol = new FlxSprite(FlxG.width, FlxG.height);
		bgLol.loadGraphic(Paths.image("loading/bg", "preload"));
		bgLol.antialiasing = true;
		bg.add(bgLol);

		/*for(x in 0...Math.ceil(FlxG.width / w)+1) {
			for(y in 0...(Math.ceil(FlxG.height / h)+1)) {
				// bg pattern
				var pattern = new FlxSprite(x * w, y * h);
				pattern.loadGraphic(Paths.image("loading/bgpattern", "preload"));
				pattern.antialiasing = true;
				bg.add(pattern);
			}
		}*/
		add(bg);

		var loading = new FlxSprite().loadGraphic(Paths.image("loading/loading"));
		loading.scale.set(0.85, 0.85);
		loading.updateHitbox();
		loading.y = FlxG.height - (loading.height * 0.85);
		loading.screenCenter(X);
		loading.antialiasing = true;
		add(loading);

		loadingText = new FlxText(0, 0, FlxG.width, "Loading...", 32);
		loadingText.setFormat(Paths.font("vcr.ttf"), Std.int(32), FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		loadingText.y = FlxG.height - (loadingText.height * 1.5);
		loadingText.screenCenter(X);
		loadingText.antialiasing = true;
		add(loadingText);

		var logoBl = new FlxSprite(-150, -25);
		logoBl.frames = Paths.getSparrowAtlas('ui/logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		logoBl.screenCenter(X);
		add(logoBl);

		loadSections.push({
			"name": "Loading Save Data",
			"func": saveData
		});
		loadSections.push({
			"name": "Finishing Loading",
			"func": additionalSetup
		});

		FlxG.autoPause = false;

		#if sys
		Thread.create(function()
		{
			for (k => s in loadSections)
			{
				loadingText.text = '${s.name}... (${Std.string(Math.floor((k / loadSections.length) * 100))}%)';
				trace(loadingText.text);
				s.func();
			}
			switchin = true;
		});
		#end
	}

	var aborted = false;

	public override function update(elapsed:Float)
	{
		bg.x -= w * elapsed / 4;
		bg.x %= w;
		bg.y -= h * elapsed / 4;
		bg.y %= h;
		super.update(elapsed);

		#if !sys
		if (switchin || aborted)
			return;

		if (step < 0)
		{
			loadingText.text = loadSections[0].name + "... (0%)";
			step = 0;
			return;
		}
		if (step >= loadSections.length)
		{
			switchin = true;
			FlxG.autoPause = true;
			var e = new TitleState();
			trace(e);
			FlxG.switchState(e);
		}
		else
		{
			loadSections[step].func();
			step++;
			if (aborted)
				return;
			if (step >= loadSections.length)
			{
				loadingText.text = "Loading Complete ! (100%)";
			}
			else
			{
				loadingText.text = loadSections[step].name + "... (" + Std.string(Math.round((step / loadSections.length) * 100)) + "%)";
			}
			loadingText.screenCenter(X);
		}
		#end
	}

	public function saveData()
	{
		FlxG.save.bind(Settings.save_bind_name, Settings.save_bind_path);
		Settings.loadDefault();

		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;
		// FlxG.bitmap.spareFromCache.push(diamond);

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.5, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(0, 0, FlxG.width, FlxG.height));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.35, new FlxPoint(0, 1), {asset: diamond, width: 32, height: 32},
			new FlxRect(0, 0, FlxG.width, FlxG.height));
	}

	public function additionalSetup()
	{
		// FLXCOLOR
		Interp.setRedirects["Int"] = function(obj:Dynamic, name:String, val:Dynamic):Dynamic
		{
			var c:FlxColor = obj;
			switch (name)
			{
				case "alpha":
					c.alpha = val;
				case "alphaFloat":
					c.alphaFloat = val;
				case "black":
					c.black = val;
				case "blue":
					c.blue = val;
				case "blueFloat":
					c.blueFloat = val;
				case "brightness":
					c.brightness = val;
				case "cyan":
					c.cyan = val;
				case "green":
					c.green = val;
				case "greenFloat":
					c.greenFloat = val;
				case "hue":
					c.hue = val;
				case "lightness":
					c.lightness = val;
				case "magenta":
					c.magenta = val;
				case "red":
					c.red = val;
				case "redFloat":
					c.redFloat = val;
				case "saturation":
					c.saturation = val;
				case "yellow":
					c.yellow = val;
			}
			obj = c;
			return c;
		}
		Interp.getRedirects["Int"] = function(obj:Dynamic, name:String):Dynamic
		{
			var c:FlxColor = obj;
			switch (name)
			{
				case "alpha":
					return c.alpha;
				case "alphaFloat":
					return c.alphaFloat;
				case "black":
					return c.black;
				case "blue":
					return c.blue;
				case "blueFloat":
					return c.blueFloat;
				case "brightness":
					return c.brightness;
				case "cyan":
					return c.cyan;
				case "green":
					return c.green;
				case "greenFloat":
					return c.greenFloat;
				case "hue":
					return c.hue;
				case "lightness":
					return c.lightness;
				case "magenta":
					return c.magenta;
				case "red":
					return c.red;
				case "redFloat":
					return c.redFloat;
				case "saturation":
					return c.saturation;
				case "yellow":
					return c.yellow;
			}
			return null;
		}

		FlxG.fixedTimestep = false;
		PlayerSettings.init();
	}
}
