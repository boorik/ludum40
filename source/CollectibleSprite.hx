package;
import flixel.FlxSprite;
import game.Object.CollectibleType;

/**
 * ...
 * @author vincent blanchet
 */
class CollectibleSprite extends flixel.FlxSprite
{

	public function new(X:Float,Y:Float,type:CollectibleType) 
	{
		super(X, Y);
		
		switch(type)
		{
			case Bottle :
				loadGraphic(AssetPaths.bottle__png, true, 32, 32);
				
			case Comforter:
				loadGraphic(AssetPaths.comforter__png, true, 32, 32);
				
			case Nappy:
				loadGraphic(AssetPaths.nappy__png, true, 32, 32);
		}
		animation.add("idle", [for (i in 0...4) i], 15, true);
		animation.play("idle");
	}
	
}