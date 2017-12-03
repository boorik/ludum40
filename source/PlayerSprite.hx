package;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * ...
 * @author vincent blanchet
 */
class PlayerSprite extends FlxSpriteGroup
{

	public var nameText:FlxText;
	public var body:flixel.FlxSprite;
	public function new(X:Int,Y:Int,name:String, color:Int) 
	{
		super(X,Y);
		nameText = new FlxText(0, 0, 0, name);
		nameText.x =   - (nameText.width - 32)/ 2;
		nameText.setSize(1, 1);
		add(nameText);
		//nameText.origin.set(nameText.width / 2, 0);
		body = new FlxSprite(X, 20);
		body.loadGraphic(AssetPaths.robot__png, true, 32, 64);
		body.animation.add("idle", [for (i in 0...4) i], 15);
		body.animation.add("stun", [for (i in 4...8)i], 15);
		body.animation.play("idle");
		body.setSize(1, 1);
		add(body);
		//origin.set(16, 64);
		setSize(32, 16);
		offset.set(0, 70);
		//updateHitbox();
		
	}	
}