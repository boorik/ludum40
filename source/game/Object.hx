package game;

@:keep
enum ObjectType {
	Player(props:PlayerProps);
	Ai(props:PlayerProps);
	Baby(props:BabyProps);
	Collectible(type:CollectibleType);
	Wall;
	Trap;
}

enum CollectibleType
{
	Nappy;
	Bottle;
	Comforter;
}

typedef PlayerProps = {
	name:String,
	score:Int,
	nappyCount:Int,
	comforterCount:Int,
	bottleCount:Int,
	trapCount:Int,
	stun:Float
}

typedef BabyProps = {
	need : Null<CollectibleType>,
	since : Float
}
	

typedef Object = {
	id:Int,
	type:ObjectType,
	color:Int,
	width:Float,
	height:Float,
	dir:Float,
	speed:Float,
	x:Float,
	y:Float,
}