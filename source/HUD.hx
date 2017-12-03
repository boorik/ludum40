package;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import game.Object.PlayerProps;
import haxe.Timer;
import haxe.ds.StringMap;

/**
 * ...
 * @author vincent blanchet
 */
class HUD extends FlxGroup
{
	var bottleCounter:FlxText;
	var comforterCounter:FlxText;
	var nappyCounter:FlxText;
	var score:flixel.text.FlxText;
	var needUpdate:Bool;
	var scores : Array<PlayerProps>;// :StringMap<Int>;
	var ranking:flixel.text.FlxText;
	var needeedTimeForUpdate = 1.;
	var remainingBeforeUpdate = 0.;
	var announce:flixel.text.FlxText;
	
	public var background:flixel.FlxSprite;
	public var width = FlxG.width;
	public var height = FlxG.height;
	
	var x = 10000;
	var timerText:flixel.text.FlxText;
	var trapCounter:flixel.text.FlxText;
	public function new() 
	{
		super();
		
		//scores = new StringMap<Int>();
		scores = [];
		
		
		
		background = new FlxSprite(x, 0);
		background.makeGraphic(width, height, FlxColor.TRANSPARENT);
		add(background);
		
		
		score = new FlxText(x, 0, 0, "score : 0",20);
		add(score);
		
		var comforterIcon = new FlxSprite(x, 35);
		comforterIcon.loadGraphic(AssetPaths.comforter__png, true, 32, 32);
		comforterIcon.animation.add("none", [0], 1, true);
		comforterIcon.animation.play("none");
		//comforterIcon.scrollFactor.set(0, 0);
		add(comforterIcon);
		
		comforterCounter = new FlxText(x + 32, comforterIcon.y, 0, "0",20);
		//comforterCounter.scrollFactor.set(0, 0);
		add(comforterCounter);
		
		var nappyIcon = new FlxSprite(x, 70);
		nappyIcon.loadGraphic(AssetPaths.nappy__png, true, 32, 32);
		nappyIcon.animation.add("none", [0], 1, true);
		nappyIcon.animation.play("none");
		add(nappyIcon);
		
		nappyCounter = new FlxText(x+32, nappyIcon.y, 0, "0",20);
		add(nappyCounter);
		
		var bottleIcon = new FlxSprite(x, 105);
		bottleIcon.loadGraphic(AssetPaths.bottle__png, true, 32, 32);
		bottleIcon.animation.add("none", [0], 1, true);
		bottleIcon.animation.play("none");
		add(bottleIcon);
		
		bottleCounter = new FlxText(x+32, bottleIcon.y, 0, "0",20);
		add(bottleCounter);
		
		var trapIcon = new DirtyNappySprite(x,140);
		trapIcon.animation.add("none", [0], 1, true);
		trapIcon.animation.play("none");
		add(trapIcon);
		
		trapCounter = new FlxText(x+32, trapIcon.y, 0, "0",20);
		add(trapCounter);
		
		ranking = new FlxText(x+FlxG.width - 200, 0, 200, "Ranking");
		ranking.alignment = "right";
		//ranking.scrollFactor.set(0, 0);
		add(ranking);
		
		announce = new flixel.text.FlxText(x, -200, 0, "", 30);
		announce.setFormat(30,flixel.util.FlxColor.ORANGE);
		//announce.scrollFactor.set(0, 0);
		add(announce);
		
		
		timerText = new FlxText(x + 200, 0, 0, "99", 20);
	
		timerText.x = x + (FlxG.width - timerText.width) / 2;
		add(timerText);
	}
	
	public function showAnnounce(msg:String)
	{
		trace(msg);
		announce.text = msg;
		announce.x = x + (FlxG.width - announce.width) / 2;
		FlxTween.tween(announce, {y: 320}, .5, {onComplete:function(tw:FlxTween)
			{
				Timer.delay(function(){announce.y = -200; }, 500);
		}});
	}
	
	public function updateRanking(pp:PlayerProps)
	{
		var pps = getPPByName(pp.name);
		if (pps.length == 0)
		{
			scores.push(pp);
			needUpdate = true;
		}else
		{
			if (pps[0].score != pp.score)
			{
				pps[0].score = pp.score;
				needUpdate = true;
			}
		}
	}
	
	public function resetRanking()
	{
		scores = [];
	}
	
	public function setTime(t:Float)
	{
		timerText.text = Std.string(Std.int(t));
	}
	
	function getPPByName(name:String):Array<PlayerProps>
	{
		return scores.filter(function(pp:PlayerProps){ return pp.name == name; });
	}
	
	function printRanking()
	{
		scores.sort(function(a:PlayerProps, b:PlayerProps){
			if (a.score > b.score)
				return -1;
			if (a.score < b.score)
				return 1;
			return 0;
		});
		var st:String = "";
		for (i in 0...scores.length)
		{
			var s = scores[i];
			st += (i+1)+"   "+s.name+ "   " + s.score + "\n";
		}
		
		ranking.text = st;
		needUpdate = false;
	}
	
	public function updateVar(pp:PlayerProps)
	{
		bottleCounter.text = Std.string(pp.bottleCount);
		comforterCounter.text = Std.string(pp.comforterCount);
		nappyCounter.text = Std.string(pp.nappyCount);
		score.text = 'score: ${pp.score}';
		trapCounter.text = Std.string(pp.trapCount);
	}
	
	override public function update(elapsed:Float)
	{
		remainingBeforeUpdate -= elapsed;
		if (remainingBeforeUpdate <= 0)
		{
			remainingBeforeUpdate = needeedTimeForUpdate;
			printRanking();
		}
		super.update(elapsed);
	}

	
}