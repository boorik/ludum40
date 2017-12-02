package game;
import game.Object.CollectibleType;
import haxe.Timer;


class World {
	// list of active game objects
	public var objects:Array<Object> = [];
	public var playerNumber(default,null) = 0;
	public var maxPlayer = 10;
	
	// objects spawns within this rectangle
	var size:{width:Int, height:Int};
	
	// counter for the object IDs
	var count:Int = 0;
	var AICount = 0;
	var babyCount = 0;
	
	//collision calculation helpers
	var w = .0;
	var h = .0;
	var dx = .0;
	var dy = .0;
	var wy = .0;
	var hx = .0;
	
	//timer
	var startTime = .0;
	var lastBabyTime = .0;
	var babyInterval = 5;
	var lastUpdateTime = .0;
	var elapsed = .0;
	
	public function new() {
		size = {
			width: 1000,
			height: 1000,
		}

		for (i in 0...10) createAi();
		var enums = Type.allEnums(CollectibleType);
		for (i in 0...10) createCollectible(enums[Std.random(enums.length)]);
		for (i in 0...10) createBaby();
		//for (i in 0...5)	createWall();
		
		lastUpdateTime = Timer.stamp();
	}

	public function insert(object:Object) {
		objects.push(object);
		return object;
	}

	public inline function remove(object:Object) {
		objects.remove(object);
		switch(object.type)
		{
			case Player(pp):
				playerNumber--;
			default:
		}
	}

	public function createPlayer(name:String) {
		playerNumber++;
		return insert({
			id: count++,
			type: Player({
				name:name,
				score:0,
				nappyCount:0,
				bottleCount:0,
				comforterCount:0
			}),
			color: 0xfffffff,
			width: 40,
			height:40,
			dir: Math.random() * Math.PI * 2,
			speed: 3,
			x: Std.random(size.width),
			y: Std.random(size.height),
			depth: 3,
		});
	}

	public function createAi() {
		AICount++;
		return insert({
			id: count++,
			type: Ai({
				name:'Robot $AICount',
				score:0,
				nappyCount:0,
				bottleCount:0,
				comforterCount:0
			}),
			color: Std.random(1 << 24),
			width: 40,
			height: 40,
			dir: Math.random() * Math.PI * 2,
			speed: 1,
			x: Std.random(size.width),
			y: Std.random(size.height),
			depth: 2,
		});
	}

	public function createCollectible(type:CollectibleType) {
		return insert({
			id: count++,
			type: Collectible(type),
			color: Std.random(1 << 24),
			width: 10,
			height: 10,
			dir: Math.random() * Math.PI * 2,
			speed: 0,
			x: Std.random(size.width),
			y: Std.random(size.height),
			depth: 1,
		});
	}
	
	public function createBaby() {
		babyCount++;
		return insert({
			id: count++,
			type: Baby({need:null,since:0}) ,
			color: Std.random(1 << 24),
			width: 32,
			height: 32,
			dir: Math.random() * Math.PI * 2,
			speed: 0,
			x: babyCount%10 * 100,
			y: Std.int(babyCount/9)*100+100,
			depth: 1,
		});
	}
	
	public function createWall()
	{
		var w = Std.random(490) + 10;
		return insert({
			id: count++,
			type: Wall,
			color: 0,
			width: w,
			height: Std.random(500-w)+10,
			dir: Math.random() * Math.PI * 2,
			speed: 0,
			x: Std.random(size.width),
			y: Std.random(size.height),
			depth: 1,
		});
	}

	public function update():GameState
	{
		elapsed = Timer.stamp() - lastUpdateTime;
		for (object in objects)
		{
			//AI
			switch(object.type)
			{
				case Ai(pp) :
					if (Math.random() < 0.1) 
						object.dir += Math.random() - 0.5;
						
				case Baby(props) :

					trace("BABY");
					if (props.need == null)
					{
						//do i start to cry?
						if (Math.random() < 0.001) 
						{
							var enums = Type.allEnums(CollectibleType);
							props.need = enums[Std.random(enums.length)];
							trace(props.need );
							object.speed = 0;
						}
						else
						{
							//maybe walk
							if (Math.random() < 0.01)
							{
								object.dir += Math.random() - 0.5;
								object.speed = 3;
							}
						}
					}
					else
					{
						props.since += elapsed;
						if(props.since > 10)
						{
							//bad thing to nearest player
						}
					}
				default:
			}
		
			if (object.speed != 0) 
			{
				
				
				// update object positions by their speed and direction
				object.x += Math.cos(object.dir) * object.speed;
				object.y += Math.sin(object.dir) * object.speed;
				
				if (object.x < 0)
				{
					object.x = 0;
					object.dir = Math.random() * Math.PI * 2;
				}	
				else
				if (object.x > size.width)
				{
					object.x = size.width;
					object.dir = Math.random() * Math.PI * 2;
				}	
				if (object.y < 0)
				{
					object.y = 0;
					object.dir = Math.random() * Math.PI * 2;
				}
				else
				if (object.y > size.height)
				{
					object.y = size.height;
					object.dir = Math.random() * Math.PI * 2;
				}
			}
		}
		
		// detect collisions and make larger objects consume smaller objects
		var removed = [];
		
		for (object in objects) 
		{
			for (other in objects) 
			{
				if (object.id == other.id)
					continue;
				
				//source Minkowski addition
				w = .5 * (object.width + other.width);
				h = .5 * (object.height + other.height);
				dx = object.x - other.x;
				dy = object.y - other.y;
				
				if (Math.abs(dx) <= w && Math.abs(dy) <= h)
				{
					//collision
					switch(object.type)
					{
						case Player(objectProps),Ai(objectProps):
							switch(other.type)
							{
								case Player(otherProps),Ai(otherProps):
									//calculate collision side for separation
									wy = w * dy;
									hx = h * dx;
									
									if (wy > hx)
									{
										if (wy > -hx)
										{
											//collision at the top
											object.y -= Math.sin(object.dir) * object.speed;
											
										}
										else
										{
											//collision on the left
											object.x -= Math.cos(object.dir) * object.speed;
										}
									}
									else
									{
										if (wy > - hx)
										{
											//right
											object.x -= Math.cos(object.dir) * object.speed;
											
										}
										else
										{
											//bottom
											object.y -= Math.sin(object.dir) * object.speed;
										}
									}
								case Collectible(cType):
									switch(cType)
									{
										case Bottle:
											objectProps.bottleCount++;
										case Comforter:
											objectProps.comforterCount++;
										case Nappy:
											objectProps.nappyCount++;
									}
									removed.push(other);
									
								case Baby(bp):
									//need to check if baby need something
									separate(object);
									if (bp.need != null)
										switch(bp.need)
										{
											case Bottle:
												if (objectProps.bottleCount > 0)
												{
													objectProps.bottleCount--;
													objectProps.score += 10;
													bp.need = null;
												}
											case Comforter:
												if (objectProps.comforterCount > 0)
												{
													objectProps.comforterCount--;
													objectProps.score += 20;
													bp.need = null;
												}
											case Nappy :
												if (objectProps.nappyCount > 0)
												{
													objectProps.nappyCount--;
													objectProps.score += 30;
													bp.need = null;
												}
										}
									
								case Wall:
									separate(object);
									
							}
						default:
					}
					
				}
			}
		}
		
		for(object in removed) {
			
			// actually remove the objects
			remove(object);
			
			switch(object.type)
			{
				case Player(pp) :
					playerNumber--;
			
				case Collectible(ct) : 
					// replenish collectible
					createCollectible(ct);
					
				default:
			}
			
		}

		lastUpdateTime = Timer.stamp();
		
		return {
			objects: objects,
			removed: removed,
		}
	}
	
	function separate(object:Object)
	{
		wy = w * dy;
		hx = h * dx;
		
		if (wy > hx)
		{
			if (wy > -hx)
			{
				//collision at the top
				object.y -= Math.sin(object.dir) * object.speed;
				
			}
			else
			{
				//collision on the left
				object.x -= Math.cos(object.dir) * object.speed;
			}
		}
		else
		{
			if (wy > - hx)
			{
				//right
				object.x -= Math.cos(object.dir) * object.speed;
				
			}
			else
			{
				//bottom
				object.y -= Math.sin(object.dir) * object.speed;
			}
		}
	}
}
