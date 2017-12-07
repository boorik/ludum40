package game;
import game.GameState.GameStatus;
import game.Object.CollectibleType;
import haxe.Timer;


class World {
	
	//consts
	static inline var babyBaseSpeed = 2;
	static inline var GAME_TIME = 60.;
	
	
	//game status
	var status:GameStatus;
	var remainingTime:Float;
	
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
	var collectibleCount = 0;
	
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
	var removed:Array<Object>;
	
	
	public function new() {
		removed = [];
		
		size = {
			width: 1000,
			height: 1000,
		}

		for (i in 0...10) createAi();
		var enums = Type.allEnums(CollectibleType);
		for (i in 0...10) createCollectible(enums[Std.random(enums.length)]);
		for (i in 0...15) createBaby();
		//for (i in 0...5) createWall();
		
		lastUpdateTime = Timer.stamp();
		
		startGame();
	}
	
	function startGame()
	{

		
		startTime = Timer.stamp();
		remainingTime = GAME_TIME;
		status = RUNNING;
	}
	
	function stopGame()
	{
		remainingTime = 10;//time between two games
		status = ENDED;
	}

	public function insert(object:Object) {
		objects.push(object);
		return object;
	}

	public inline function remove(object:Object) {
		objects.remove(object);
		switch(object.type)
		{
			case Player(pp) :
				playerNumber--;
		
			case Collectible(ct) : 
				// replenish collectible
				collectibleCount--;
				if(collectibleCount < 10)
					createCollectible(ct);
				
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
				comforterCount:0,
				stun:0,
				trapCount:0
			}),
			color: 0xfffffff,
			width: 32,
			height:16,
			dir: Math.random() * Math.PI * 2,
			speed: 3,
			x: Std.random(size.width - 32),
			y: Std.random(size.height - 16),
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
				comforterCount:0,
				stun:0,
				trapCount:0
			}),
			color: Std.random(1 << 24),
			width: 32,
			height: 16,
			dir: Math.random() * Math.PI * 2,
			speed: 3,
			x: Std.random(size.width - 32),
			y: Std.random(size.height - 16),
		});
	}

	public function createCollectible(type:CollectibleType) {
		collectibleCount++;
		return insert({
			id: count++,
			type: Collectible(type),
			color: Std.random(1 << 24),
			width: 32,
			height: 32,
			dir: Math.random() * Math.PI * 2,
			speed: 0,
			x: Std.random(size.width - 32),
			y: Std.random(size.height - 32),
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
			x: Std.random(size.width - 32),
			y: Std.random(size.height - 32),
		});
	}
	
	public function createWall()
	{
		var w = (Std.random(2) == 1)? Std.random(470)+30 : 30;
		var h = (w == 30)? Std.random(470) + 30 : 30;
		return insert({
			id: count++,
			type: Wall,
			color: 0,
			width: w,
			height: h,
			dir: Math.random() * Math.PI * 2,
			speed: 0,
			x: Std.random(size.width),
			y: Std.random(size.height),
		});
	}
	
	public function dropTrap(player:game.Object):Object
	{
		switch (player.type)
		{
			case Player(pp), Ai(pp):
				if (pp.trapCount < 1)
					return null;
				else
					pp.trapCount--;
				
			default:
		}
		var px = player.x + Math.cos(player.dir + Math.PI ) * 40;
		var py = player.y + Math.sin(player.dir + Math.PI) * 40;
		
		if(px < 0)
			px = 0;
		else if (px + 32 > size.width)
			px = size.width - 32;

		if(py < 0)
			py = 0;
		else if(py + 32 > size.height)
			py = size.height - 32;

		return insert({
			id: count++,
			type: Trap,
			color: 0,
			width: 32,
			height: 32,
			dir: Math.random() * Math.PI * 2,
			speed: 0,
			x: px,
			y: py
		});
	}
	function reset()
	{
		for (object in objects)
		{
			switch(object.type)
			{
				case Ai(pp),Player(pp) :
					pp.score = 0;
					pp.nappyCount = 0;
					pp.comforterCount = 0;
					pp.bottleCount = 0;
					pp.stun = 0;
					pp.trapCount = 0;
				default:
			}
		}
	}	
	
	public function update():GameState
	{
		removed = [];
		elapsed = Timer.stamp() - lastUpdateTime;
		
		remainingTime -= elapsed;
		if (status == RUNNING && remainingTime <= 0)
		{
			stopGame();
		}
		else
		if (status == ENDED && remainingTime <= 0)
		{
			reset();
			startGame();
		}
		
		for (object in objects)
		{
			//AI
			switch(object.type)
			{
				case Player(pp):
					if (pp.stun > 0)
					{
						object.speed = 0;
						pp.stun -= elapsed;
					}
				case Ai(pp) :
					if (pp.stun > 0)
					{
						object.speed = 0;
						pp.stun -= elapsed;
					}
					else
					{
						if (Math.random() < 0.1) 
						{
							object.speed = 3;
							object.dir += Math.random() - 0.5;
						}
						if(pp.trapCount > 0 && Math.random() < 0.1)
						{
							dropTrap(object);
						}
					}
						
				case Baby(props) :

					if (props.need == null)
					{
						//do i start to cry?
						if (Math.random() < 0.001) 
						{
							var enums = Type.allEnums(CollectibleType);
							props.need = enums[Std.random(enums.length)];
							object.speed = 0;
						}
						else
						{
							//maybe walk
							if (Math.random() < 0.01)
							{
								object.dir += Math.random() - 0.5;
								object.speed = babyBaseSpeed;
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
				if (object.x + object.width > size.width)
				{
					object.x = size.width - object.width;
					object.dir = Math.random() * Math.PI * 2;
				}	
				if (object.y < 0)
				{
					object.y = 0;
					object.dir = Math.random() * Math.PI * 2;
				}
				else
				if (object.y + object.height > size.height)
				{
					object.y = size.height - object.height;
					object.dir = Math.random() * Math.PI * 2;
				}
			}
		}
		
		// detect collisions and make larger objects consume smaller objects
		
		
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
									if(removed.indexOf(other) == -1)
									{
										removed.push(other);
										switch(cType)
										{
											case Bottle:
												objectProps.bottleCount++;
											case Comforter:
												objectProps.comforterCount++;
											case Nappy:
												objectProps.nappyCount++;
										}
									}

									
								case Trap:
									objectProps.stun = 2.;
									if(removed.indexOf(other) == -1)
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
													objectProps.trapCount++;
												}
											case Comforter:
												if (objectProps.comforterCount > 0)
												{
													objectProps.comforterCount--;
													objectProps.score += 20;
													bp.need = null;
													objectProps.trapCount++;
												}
											case Nappy :
												if (objectProps.nappyCount > 0)
												{
													objectProps.nappyCount--;
													objectProps.score += 30;
													bp.need = null;
													objectProps.trapCount++;
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
		}

		lastUpdateTime = Timer.stamp();
		
		return {
			objects: objects,
			removed: removed,
			remainingTime:remainingTime,
			status:status
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
