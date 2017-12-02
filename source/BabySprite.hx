package;
import flixel.FlxSprite;
import game.Object.CollectibleType;

/**
 * ...
 * @author vincent blanchet
 */
class BabySprite extends flixel.FlxSprite
{
	public var bubble:FlxSprite;
	public function new(X:Float,Y:Float) 
	{
		super(X, Y);
		
		loadGraphic(AssetPaths.baby__png, true, 32, 32);
		animation.add("idle", [for (i in 0...4) i],15);
		animation.add("crying", [for (i in 4...8) i],15);
		animation.add("moving", [for (i in 8...12) i],15);
		animation.play("idle");
	}
	
}