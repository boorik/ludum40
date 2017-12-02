package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

import game.*;
import game.Object;
using Lambda;

import haxe.*;
import haxe.ds.IntMap;
// import haxe.Serializer;
// import haxe.Unserializer;
import mp.Command;
import mp.Message;

class PlayState extends FlxState
{
	var world:World;
	var state:GameState;
	var connected = false;
	var id:Null<Int> = null;
	var touched:Bool;
	var ws:haxe.net.WebSocket;
	var wsError = false;
	var sprites:IntMap<FlxSprite>;
	var statusText:FlxText;
	
	//debug var
	var worldUpdateTime:Float;
	var worldTreat:Float;
	var stateUpdate:Float;

	//layers
	var entities:FlxGroup;
	var hud:HUD;
	
	var bottleCounter:flixel.text.FlxText;
	var comforterCounter:flixel.text.FlxText;
	var nappyCounter:flixel.text.FlxText;
	var overlayCamera:flixel.FlxCamera;
	var hudCam:flixel.FlxCamera;
	var deadzoneOverlay:flixel.FlxSprite;
	
	override public function create():Void
	{
		//debug
		FlxG.watch.add(this,'worldUpdateTime');
		FlxG.watch.add(this,'worldTreat');
		FlxG.watch.add(this, 'stateUpdate');
		
		FlxG.camera.zoom = 2;

		trace("built at " + BuildInfo.getBuildDate());

		statusText = new FlxText(0,0,300,"Connecting, please wait...");
		statusText.setFormat(20,flixel.util.FlxColor.WHITE);
		statusText.screenCenter();
		
		var floor = new FlxSprite(0, 0);
		floor.makeGraphic(1000, 1000, FlxColor.GRAY);
		add(floor);
		
		entities = new FlxGroup();
		add(entities);
		
		hud = new HUD();
		add(hud);

		sprites = new IntMap<FlxSprite>();
		if(Globals.online)
		{
			add(statusText);
			
			try{
				ws = haxe.net.WebSocket.create('ws://${Globals.game.host}:${Globals.game.port}');
			}
			catch(e:Dynamic)
			{
				Globals.online = false;
			}
			ws.onopen = function() ws.sendString(Serializer.run(Join('need impl')));
			ws.onmessageString = function(msg) {
				var msg:Message = Unserializer.run(msg);
				switch msg {
					case Joined(id): 
						trace('Game joined, player id: $id');
						this.id = id;
					case Full:
						trace('Unable to join, the game is full');
					case State(state): 
						this.state = state;
					default:
						trace('not supposed to get $msg');
				}
			}
			ws.onerror = function(msg:String){
				trace('Network error : $msg');
				showServerUnreachable();
			}
		}
		else
		{
			world = new World();
			id = world.createPlayer('ME').id;
		}
		
		super.create();
	}
	
	function addHud()
	{
		hudCam = new FlxCamera(0, 0, hud.width, hud.height);
		hudCam.zoom = 1; // For 1/2 zoom out.
		hudCam.follow(hud.background, FlxCameraFollowStyle.NO_DEAD_ZONE);
		hudCam.alpha = .5;
		FlxG.cameras.add(hudCam);
	}
	
	function drawDeadzone() 
	{
		deadzoneOverlay.fill(FlxColor.TRANSPARENT);
		var dz:FlxRect = FlxG.camera.deadzone;
		if (dz == null)
			return;

		var lineLength:Int = 20;
		var lineStyle:LineStyle = { color: FlxColor.WHITE, thickness: 3 };
		
		// adjust points slightly so lines will be visible when at screen edges
		dz.x += lineStyle.thickness / 2;
		dz.width -= lineStyle.thickness;
		dz.y += lineStyle.thickness / 2;
		dz.height -= lineStyle.thickness;
		
		// Left Up Corner
		deadzoneOverlay.drawLine(dz.left, dz.top, dz.left + lineLength, dz.top, lineStyle);
		deadzoneOverlay.drawLine(dz.left, dz.top, dz.left, dz.top + lineLength, lineStyle);
		// Right Up Corner
		deadzoneOverlay.drawLine(dz.right, dz.top, dz.right - lineLength, dz.top, lineStyle);
		deadzoneOverlay.drawLine(dz.right, dz.top, dz.right, dz.top + lineLength, lineStyle);
		// Bottom Left Corner
		deadzoneOverlay.drawLine(dz.left, dz.bottom, dz.left + lineLength, dz.bottom, lineStyle);
		deadzoneOverlay.drawLine(dz.left, dz.bottom, dz.left, dz.bottom - lineLength, lineStyle);
		// Bottom Right Corner
		deadzoneOverlay.drawLine(dz.right, dz.bottom, dz.right - lineLength, dz.bottom, lineStyle);
		deadzoneOverlay.drawLine(dz.right, dz.bottom, dz.right, dz.bottom - lineLength, lineStyle);
	}

	function showServerUnreachable()
	{
		statusText.text = "Server unreachable : Server is down, or port is not open. If you are running the server make sure that your router is well configured.";
		var backButton = tools.UITools.getButton(statusText.x,statusText.y+statusText.height,statusText.width,40,"Back",exit);
		add(backButton);
	}

	override public function update(elapsed:Float):Void
	{
		if(FlxG.keys.justPressed.ESCAPE)
			exit();
		
		var su = Timer.stamp();
		if(Globals.online)
		{
			if(!wsError)
			{
				try{
					ws.process();
				}catch(e:Dynamic)
				{
					trace(e);
					wsError = true;
				}
			}
			if(state == null)// not ready
			{
				super.update(elapsed);
				return;
			}  
		}
		else
		{
			var b = Timer.stamp();
			state = world.update();
			worldUpdateTime = Timer.stamp() - b;
		}

		// handle move
		var player = state.objects.find(function(o) return o.id == id);
		if(player != null) 
		{
			// move player
			var mid = new FlxPoint(FlxG.width/2,FlxG.height/2);
			if(FlxG.mouse.pressed)
			{

				var dir = Math.atan2(FlxG.mouse.getScreenPosition().y - mid.y, FlxG.mouse.getScreenPosition().x - mid.x);
				if(Globals.online)
				{
					if(player.speed == 0) 
						ws.sendString(Serializer.run(StartMove));
					ws.sendString(Serializer.run(SetDirection(dir)));
				}
				else
				{
					player.speed = 3;
					player.dir = dir;
				}
			} 
			else 
			{
				if(Globals.online)
				{
					if(player.speed != 0)
						ws.sendString(Serializer.run(StopMove));
				}
				else
				{
					player.speed = 0;
				}
			}			
		}
		var bo = Timer.stamp();
		for(object in state.objects) 
		{
			var s:FlxSprite = null;
			if(!sprites.exists(object.id))
			{
				switch(object.type)
				{
					case Player(pp), Ai(pp):
						trace(object);
						s = cast entities.recycle(FlxSprite);
						if(object.id == id)
						{
							trace("PLAYER FOUND");
							s.makeGraphic(Std.int(object.width), Std.int(object.height), FlxColor.RED);
							FlxG.camera.follow(s);
							addHud();
						}

						else
							s.makeGraphic(Std.int(object.width), Std.int(object.height), FlxColor.fromInt(object.color + 0xFF000000));
					
					case Collectible(ct):
						s = new CollectibleSprite(0, 0, ct);
						
					case Baby(pp):
						s = cast entities.recycle(BabySprite);
						
					case Wall:
						s = cast entities.recycle(FlxSprite);
						s.makeGraphic(Std.int(object.width), Std.int(object.height), FlxColor.BLACK);
				}	
				s.setPosition(object.x, object.y);
				entities.add(s);
				

				sprites.set(object.id,s);

			}
			else
			{
				s = sprites.get(object.id);
				s.setPosition(object.x, object.y);
				switch(object.type)
				{
					case Player(pp), Ai(pp):
						if (object.id == id)
						{
							//GUI update
							hud.updateVar(pp);
						}
					case Baby(bp):
						var bb:BabySprite = cast s;
						if (bp.need != null)
						{	
							
							if (bb.need == null)
							{
								bb.animation.play("crying");
								
								var bubble = new Bubble(bb.x, bb.y - 32);
								entities.add(bubble);
								bb.linkedObjects.push(bubble);
								var n = new CollectibleSprite(bb.x, bb.y - 32, bp.need);
								entities.add(n);
								bb.linkedObjects.push(n);
								bb.need = bp.need;
							}
						}
						else
						{
							if (bb.need != null)
							{
								bb.need = null;
								while (bb.linkedObjects.length > 0)
									entities.remove(bb.linkedObjects.pop());
								//FEEDBACK NEEDED BABY IS OK
								
							}
							if (object.speed == 0)
							{
								s.animation.play("idle");
							}
							else
								s.animation.play("moving");
						}
					default:
				}
				
				
				//lixel.tweens.FlxTween.tween(s,{x:object.x,y:object.y});
			}

		}
		worldTreat = Timer.stamp()-bo;
		for(object in state.removed)
		{
			if(sprites.exists(object.id))
			{
				trace('removing ${object.id}');
				var s = sprites.get(object.id);
				s.kill();
				entities.remove(s);
				sprites.remove(object.id);
			}else{
				trace('object ${object.id} not found');
			}
		}

		super.update(elapsed);
		stateUpdate = Timer.stamp() - su;
	}

	function exit()
	{
		FlxG.switchState(new MenuState());
	}

	override public function destroy()
	{
		trace('destroying PlayState');
		if(ws != null)
		{
			ws.close();
			ws = null;
		}
		super.destroy();
	}
}
