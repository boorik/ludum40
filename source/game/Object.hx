package game;

@:keep
enum ObjectType {
	Player(props:PlayerProps);
	Ai(props:PlayerProps);
	Baby(props:BabyProps);
	Collectible(type:CollectibleType);
	Wall;
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
	bottleCount:Int
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
	depth:Float,
	x:Float,
	y:Float,
}