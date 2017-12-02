package mp;

// sent from client to server
enum Command {
	Join(name:String);
	SetDirection(dir:Float);
	StartMove;
	StopMove;
	Ping;
}