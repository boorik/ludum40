package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxTiledSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import game.GameState.GameStatus;

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
	var lastStatus = ENDED;
	
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
	
	var explosionsEmitters:FlxTypedGroup<FlxEmitter>;
	
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
		
		var floor = new FlxTiledSprite(AssetPaths.world_0__png, 1000, 1000);
		add(floor);
		
		explosionsEmitters = new FlxTypedGroup<FlxEmitter>();
		add(explosionsEmitters);
		
		entities = new FlxGroup();
		add(entities);
		
		hud = new HUD();
		add(hud);
		addHudCam();
		

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
	
	function addHudCam()
	{
		hudCam = new FlxCamera(0, 0, hud.width, hud.height);
		hudCam.zoom = 1; // For 1/2 zoom out.
		hudCam.follow(hud.background, FlxCameraFollowStyle.NO_DEAD_ZONE);
		//hudCam.alpha = .5;
		FlxG.cameras.add(hudCam);
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
		
		switch(state.status)
		{
			case RUNNING :
				if (lastStatus != RUNNING)
				{
					hud.resetRanking();
					hud.showAnnounce("GAME STARTED!!!!");
				}
				lastStatus = RUNNING;
				
			case ENDED :
				if (lastStatus != ENDED)
				{
					hud.showAnnounce("GAME OVER");
				}
				lastStatus = ENDED;
		}
		hud.setTime(state.remainingTime);

		// handle move
		handlePlayerInput();
		
		var bo = Timer.stamp();
		for(object in state.objects) 
		{
			var s:FlxSprite = null;
			if(!sprites.exists(object.id))
			{
				spawnObject(object);
			}
			else
			{
				s = sprites.get(object.id);
				s.setPosition(object.x, object.y);
				switch(object.type)
				{
					case Player(pp), Ai(pp):
						var pSprite:PlayerSprite = cast s;
						if (object.id == id)
						{
							//GUI update
							hud.updateVar(pp);
						}
						hud.updateRanking(pp);
						
						if (pp.stun > 0 )
						{
							if (pSprite.body.animation.name == "idle")
								shitExplosion(pSprite.x, pSprite.y);
								
							pSprite.body.animation.play("stun");
						}
						else
							pSprite.body.animation.play("idle");
								
						
						
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
								var n = new CollectibleSprite(bb.x, bb.y - 31, bp.need);
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
									bb.linkedObjects.pop().kill();
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
				//trace('removing ${object.id}');
				var s = sprites.get(object.id);
				s.kill();
				//entities.remove(s);
				sprites.remove(object.id);
			}else{
				trace('object ${object.id} not found');
			}
		}
		super.update(elapsed);
		try{
		entities.sort(cast FlxSort.byY, FlxSort.ASCENDING);
		}catch (e:Dynamic)
		{
			trace(entities.toString());
		}
		stateUpdate = Timer.stamp() - su;
	}
	
	function shitExplosion(X:Float,Y:Float)
	{
		var explosionEmitter:FlxEmitter = explosionsEmitters.getFirstAvailable(FlxEmitter);
		if (explosionEmitter == null)
		{
			explosionEmitter = new FlxEmitter();
			explosionEmitter.makeParticles(5, 5, FlxColor.BROWN);
			explosionEmitter.lifespan.set(0.1, 0.5);
			explosionEmitter.speed.set(100,300);
		}
		explosionEmitter.setPosition(X, Y);
		explosionsEmitters.add(explosionEmitter);
		explosionEmitter.start();
	}
	
	inline function handlePlayerInput()
	{
		var player = state.objects.find(function(o) return o.id == id);
		if(player != null) 
		{
			if (FlxG.keys.justPressed.SPACE)
			{
				if (Globals.online)
				{
					ws.sendString(Serializer.run(DropTrap));
				}else
					world.dropTrap(player);
			}
			
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
	}
	
	inline function spawnObject(object:Object)
	{
		var s:flixel.FlxSprite;
		switch(object.type)
		{
			case Player(pp), Ai(pp):
				var ps:PlayerSprite = null;
				
				if(object.id == id)
				{
					trace("PLAYER FOUND");
					ps = new PlayerSprite(0, 0, "ME", 0xFF0000);
					FlxG.camera.follow(ps,1);
					//addHudCam();
				}
				else	
					ps = new PlayerSprite(0, 0, pp.name,object.color);
					
				//entities.add(ps.nameText);
				s = ps;
			
			case Collectible(ct):
				s = new CollectibleSprite(0, 0, ct);
				
			case Baby(pp):
				s = cast entities.recycle(BabySprite);
				
			case Wall:
				s = cast entities.recycle(FlxSprite);
				s.makeGraphic(Std.int(object.width), Std.int(object.height), FlxColor.BLACK);
				
			case Trap:
				s = cast entities.recycle(DirtyNappySprite);
		}	
		s.setPosition(object.x, object.y);
		entities.add(s);
		

		sprites.set(object.id,s);

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
