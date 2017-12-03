package;
import flixel.FlxSprite;
import game.Object.CollectibleType;

/**
 * ...
 * @author vincent blanchet
 */
class DirtyNappySprite extends flixel.FlxSprite
{

	public function new(X:Float,Y:Float) 
	{
		super(X, Y);
				
		loadGraphic(AssetPaths.dirty_nappy__png, true, 32, 32);
				
		animation.add("idle", [for (i in 0...4) i], 8, true);
		animation.play("idle");
	}
	
}