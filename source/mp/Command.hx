package mp;

// sent from client to server
enum Command {
	Join(name:String);
	SetDirection(dir:Float);
	StartMove;
	StopMove;
	DropTrap;
	Adm(pw:String,cmd:AdmCmd);
	Ping;
}

enum AdmCmd{
	ST;//statistics
}