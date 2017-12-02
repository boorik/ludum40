package;
import flixel.FlxSprite;

/**
 * ...
 * @author vincent blanchet
 */
class Bubble extends FlxSprite
{

	public function new(X:Float,Y:Float) 
	{
		super(X, Y);
		loadGraphic(AssetPaths.needbubble__png, true, 32, 32);
		animation.add("idle", [for (i in 0...4) i], 15);
		animation.play("idle");
	}
	
}