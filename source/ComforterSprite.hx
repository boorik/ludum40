package;

class ComforterSprite extends flixel.FlxSprite
{
    public function new(X:Float,Y:Float)
    {
        super(X,Y);
		loadGraphic(AssetPaths.comforter__png, true, 32, 32);
		animation.add("idle", [for (i in 0...4) i], 15, true);
		animation.play("idle");
    }
}