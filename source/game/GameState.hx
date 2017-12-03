package game;

typedef GameState = {
	objects:Array<Object>,
	removed:Array<Object>,
	status:GameStatus,
	remainingTime:Float
}

enum GameStatus 
{
	RUNNING;
	ENDED;	
}