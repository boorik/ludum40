package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxButtonPlus;
import flixel.math.FlxMath;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.util.FlxAxes;
import tools.UITools;


class MenuState extends FlxState
{
	var sec = 1.;
	var popText:flixel.text.FlxText;
	var pop = 7585238600;
	override public function create():Void
	{
		super.create();
		
		
		var superText = new FlxText(-300,100,0,'SUPER');
		superText.setFormat(40, flixel.util.FlxColor.BLACK);
		add(superText);
		
		FlxTween.tween(superText, {x:100}, 0.5);
		
		var titleText = new FlxText(FlxG.width,150,0,'CHILDCARE ASSISTANT');
		titleText.setFormat(40, flixel.util.FlxColor.BLACK);
		add(titleText);
		
		FlxTween.tween(titleText, {x:200}, 0.5);
		
		var alphaText = new FlxText(FlxG.width,200,0,'ALPHA 3');
		alphaText.setFormat(40, flixel.util.FlxColor.BLACK);
		add(alphaText);
		
		FlxTween.tween(alphaText, {x:500}, 1);

		popText = new FlxText(0,0,0,'Earth population : $pop');
		popText.setFormat(12, flixel.util.FlxColor.BLACK);
		popText.screenCenter();
        add(popText);
		
		trace(popText.y + 30);
		var t = new FlxText(0, popText.y + 30, 0, 'Children, the more you have, the worst it is');
		t.setFormat(12, flixel.util.FlxColor.BLACK);
		t.screenCenter(FlxAxes.X);
		add(t);

		var soloButton = UITools.getButton(0, FlxG.height - 110, 300, 50, "Play solo", playSolo);
		soloButton.screenCenter(flixel.util.FlxAxes.X);
		add(soloButton);

		var multiButton = UITools.getButton(0,FlxG.height - 55, 300, 50, "Play online", playMulti);
		multiButton.screenCenter(flixel.util.FlxAxes.X);
		add(multiButton);
	}

	function playSolo()
	{
		Globals.online = false;
		FlxG.switchState(new PlayState());
	}

	function playMulti()
	{
		Globals.online = true;
		FlxG.switchState(new ServerBrowserState());
	}

	override public function update(elapsed:Float):Void
	{
		sec -= elapsed;
		if (sec <= 0)
		{
			sec = 1;
			pop++;
			popText.text = 'Earth population : $pop';
		}
		#if !web
		if(FlxG.keys.justPressed.ESCAPE)
		{
			Sys.exit(0);
		}
		#end
		super.update(elapsed);
	}
}
