package;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

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
	
	public var background:flixel.FlxSprite;
	public var width = 200;
	public var height = 130;
	public function new() 
	{
		super();
		
		background = new FlxSprite(10000, 0);
		background.makeGraphic(width, height, FlxColor.BLACK);
		add(background);
		
		var bottleIcon = new FlxSprite(0, 0);
		bottleIcon.loadGraphic(AssetPaths.bottle__png, true, 32, 32);
		bottleIcon.animation.add("none", [0], 1, true);
		bottleIcon.animation.play("none");
		bottleIcon.scrollFactor.set(0, 0);
		add(bottleIcon);
		
		bottleCounter = new FlxText(32, 0, 0, "0",20);
		bottleCounter.scrollFactor.set(0, 0);
		add(bottleCounter);
		
		var comforterIcon = new FlxSprite(0, 35);
		comforterIcon.loadGraphic(AssetPaths.comforter__png, true, 32, 32);
		comforterIcon.animation.add("none", [0], 1, true);
		comforterIcon.animation.play("none");
		comforterIcon.scrollFactor.set(0, 0);
		add(comforterIcon);
		
		comforterCounter = new FlxText(32, comforterIcon.y, 0, "0",20);
		comforterCounter.scrollFactor.set(0, 0);
		add(comforterCounter);
		
		var nappyIcon = new FlxSprite(0, 70);
		nappyIcon.loadGraphic(AssetPaths.nappy__png, true, 32, 32);
		nappyIcon.animation.add("none", [0], 1, true);
		nappyIcon.animation.play("none");
		nappyIcon.scrollFactor.set(0, 0);
		add(nappyIcon);
		
		nappyCounter = new FlxText(32, nappyIcon.y, 0, "0",20);
		nappyCounter.scrollFactor.set(0, 0);
		add(nappyCounter);
		
		score = new FlxText(0, 105, 0, "score : 0",20);
		score.scrollFactor.set(0, 0);
		add(score);
		
	}
	
	public function updateVar(pp:game.Object.PlayerProps)
	{
		bottleCounter.text = Std.string(pp.bottleCount);
		comforterCounter.text = Std.string(pp.comforterCount);
		nappyCounter.text = Std.string(pp.nappyCount);
		score.text = 'score: ${pp.score}';
	}

	
}