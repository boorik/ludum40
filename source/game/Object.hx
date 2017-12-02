package game;

@:keep
enum ObjectType {
	Player;
	Ai;
	Food;
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