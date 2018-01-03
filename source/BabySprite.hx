package;
import flixel.FlxSprite;
import game.Object.CollectibleType;

/**
 * ...
 * @author vincent blanchet
 */
class BabySprite extends flixel.group.FlxSpriteGroup
{
	public var linkedObjects:Array<FlxSprite> = [];
	public var need(default,set):Null<CollectibleType>;
	public var body:FlxSprite;
	var bubble:Bubble;
	var collectible:FlxSprite;
	public function new(X:Float,Y:Float) 
	{
		super(X, Y);
		
		body = new FlxSprite(0,0);
		body.loadGraphic(AssetPaths.baby__png, true, 32, 32);
		body.animation.add("idle", [for (i in 0...4) i],15);
		body.animation.add("crying", [for (i in 4...8) i],15);
		body.animation.add("moving", [for (i in 8...12) i],15);
		body.animation.play("idle");

		add(body);

		setSize(32,32);
	}

	function set_need(value:Null<CollectibleType>):Null<CollectibleType>
	{
		if(value != null)
		{
			body.animation.play("crying");
			
			bubble = cast recycle(Bubble);
			bubble.setPosition(0,- 32);
			add(bubble);

			collectible = switch(value)
			{
				case Nappy :
					recycle(NappySprite);
				case Comforter :
					recycle(ComforterSprite);
				case Bottle :
					recycle(BottleSprite);
			}
			collectible.setPosition(0, - 31);
			add(collectible);
		}
		else if(value == null && this.need != null)
		{
			bubble.exists = false;
			collectible.exists = false;
		}

		return this.need = value;
	}

	override public function destroy()
	{
		body.destroy();
		body = null;
		if(bubble != null)
		{
			bubble.destroy();
			bubble = null;
		}

		if(collectible != null)
		{
			collectible.destroy();
			collectible = null;
		}
		super.destroy();
	}
	
}