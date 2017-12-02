package game;


class World {
	// list of active game objects
	public var objects:Array<Object> = [];
	public var playerNumber(default,null) = 0;
	public var maxPlayer = 10;
	
	// objects spawns within this rectangle
	var size:{width:Int, height:Int};
	
	// counter for the object IDs
	var count:Int = 0;
	
	//collision calculation helpers
	var w = .0;
	var h = .0;
	var dx = .0;
	var dy = .0;
	var wy = .0;
	var hx = .0;
	

	public function new() {
		size = {
			width: 2000,
			height: 2000,
		}

		for(i in 0...10) createAi();
		for(i in 0...50) createFood();
	}

	public function insert(object:Object) {
		objects.push(object);
		return object;
	}

	public inline function remove(object:Object) {
		objects.remove(object);
		if(object.type == Player)
			playerNumber--;
	}

	public function createPlayer() {
		playerNumber++;
		return insert({
			id: count++,
			type: Player,
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
		return insert({
			id: count++,
			type: Ai,
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

	public function createFood() {
		return insert({
			id: count++,
			type: Food,
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

	public function update():GameState {
		
		for(object in objects) if(object.speed != 0) {
			
			// randomize AI direction
			if(object.type == Ai && Math.random() < 0.1) object.dir += Math.random() - 0.5;
			
			// update object positions by their speed and direction
			object.x += Math.cos(object.dir) * object.speed;
			object.y += Math.sin(object.dir) * object.speed;
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
						case Player,Ai:
							switch(other.type)
							{
								case Player,Ai:
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
								case Food:
									removed.push(other);
							}
						case Food:
					}
					
				}
				
				/*
				if(object.size > other.size) {
					var dx = object.x - other.x;
					var dy = object.y - other.y;
					
					// distance < radius
					if(dx * dx + dy * dy < object.size * object.size) {
						// we don't want to modify the array we are iterating
						removed.push(other);
						
						// size increases after consuming the target
						object.size += other.size * 0.1;
					}
				}
				*/
			}
		}
		
		for(object in removed) {
			
			// actually remove the objects
			remove(object);
			
			switch(object.type)
			{
				case Player :
					playerNumber--;
			
				case Food : 
					// replenish food
					createFood();
					
				default:
			}
			
		}

		return {
			objects: objects,
			removed: removed,
		}
	}
}
