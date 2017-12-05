package mp;

import mp.Message;
import mp.Command;
import mp.MasterCommand;
import mp.MasterMessage;
import game.*;
import haxe.*;

import haxe.net.WebSocketServer;
import haxe.net.WebSocket;
import haxe.net.impl.WebSocketGeneric;

using Lambda;

class GameServer {
	static function main() {new GameServer();}

	//default values
	var port = 8888;
	var serverName = "Ludum dare";
	var masterAdress = "games.boorik.com";
	var masterPort = 9999;
	var adminPasword = "LDXLHAXESERV";

	var masterRefreshRate = 5.0; //refresh master server every 5 sec
	var clients:Array<Client> = [];
	var world:World;
	
	//game server sockets
	var ws:WebSocketServer;

	//master server connection
	var msc:WebSocket;
	var masterUpdateTime = .0;
	var mscError = false;
	public function new()
	{
		var args = Sys.args();
		if (args.length > 4)
		{
			Sys.println('args: [port] [masteradress] [masterport]');
			Sys.exit(1);
		}
		if(args.length > 0)
			port = Std.parseInt(args[0]);
		if (args.length > 1)
			serverName = args[1];
		if(args.length > 2)
			masterAdress = args[2];
		if (args.length > 3)
			masterPort = Std.parseInt(args[3]);
	
		
		log("GAME SERVER STARTED\nbuilt at " + BuildInfo.getBuildDate());

		var masterRefreshRate = 5.0; //refresh master server every 5 sec

		world = new World();

		//game server sockets
		ws = WebSocketServer.create('0.0.0.0', port, 5000, false);

		//master server connection
		msc = WebSocket.create('ws://$masterAdress:$masterPort');

		msc.onopen = function(){
			log('registering the game');
			msc.sendString(Serializer.run(Register(serverName, port, 0, world.maxPlayer)));
		}

		msc.onerror = function(msg:String){
			log('ERROR : issue with master server \n$msg');
			mscError = true;
		}

		msc.onclose = function(){
			log("ERROR : connection to master server lost");
		}
		
		msc.onmessageString = function(msg){
			var command:MasterMessage;
			try{
				command = Unserializer.run(msg);
			}
			catch(e:Dynamic)
			{
				log('ERROR : unexpected message: $msg');
				return;
			}
			switch(command)
			{
				case Registered :
					log("registered to master server");
					masterUpdateTime = Timer.stamp();

				case Updated :
					//log("master server updated");
					masterUpdateTime = Timer.stamp();
				
				default:
					log('ERROR : not supposed to recieve $command message');
			}
		}
		while (true) {
			try{
				if(!mscError)
				{
					try{
						msc.process();
					}
					catch(e:Dynamic)
					{
						log('ERROR : Unable to communicate with master server,\n$e');
						mscError = true;
					}
				}

				var websocket = ws.accept();
				if (websocket != null) 
				{
					clients.push(createNewClient(websocket));
				}
				
				var toRemove = [];
				for (handler in clients) {
					if (!handler.update()) {
						toRemove.push(handler);
					}
				}
				
				while (toRemove.length > 0)
					clients.remove(toRemove.pop());
					
				Sys.sleep(0.032);

				//keep master server in touch
				var elapsed = Timer.stamp() - masterUpdateTime;
				if(masterUpdateTime != .0 && (elapsed > masterRefreshRate))
				{
					//log("sending game status update...");
					masterUpdateTime = Timer.stamp();
					msc.sendString(Serializer.run(Update(world.playerNumber, world.maxPlayer)));
				}


				//game loop
				var state = world.update();

				// clean up the client-player association
				for(object in state.removed) {
					switch clients.find(function(c) return c.player != null && c.player.id == object.id) {
						case null: // hmm....
						case client: client.player = null;
					}
				}

				// broadcast the game state
				var msg = Serializer.run(State(state));
				for (client in clients)
				{
					if (client.player != null)
					{
						try {
							client.connection.sendString(msg);
						} catch (e:Dynamic) {}
					}
				}
		
			}
			catch (e:Dynamic) {
				trace('Error', e);
				trace(CallStack.exceptionStack());
			}
		}
	}
	static function log(str:String)
	{
		var date = Date.now();
		var dateStr = DateTools.format(date,"%Y-%m-%d %H:%M:%S");
		Sys.println('[$dateStr] $str');
	}

	function createNewClient(websocket:WebSocket):Client
	{
		var client = new Client(websocket);
		//websocket.onopen = onopen;
		websocket.onclose = function() {
			if(client.player != null)
				world.remove(client.player);
			clients.remove(client);
		};
		websocket.onerror = function(msg:String)
		{
			var host = cast(websocket,WebSocketGeneric).host;
			log('${host} $msg');
		};

		websocket.onmessageString = function(msg:String)
			{
				var command:Command;
				try{
					command = Unserializer.run(msg);
				}
				catch(e:Dynamic)
				{
					log('ERROR : unexpected message: $msg');
					return;
				}
				switch command {
					case Join(name):
						if(world.playerNumber < world.maxPlayer)
						{
							var peer = cast(websocket,WebSocketGeneric).socket.peer().host.toString();
							log('$name $peer joined the game');
							if(client.player == null)
								client.player = world.createPlayer(name);

							var msg = Serializer.run(Joined(client.player.id));
							client.connection.sendString(msg);
						}
						else
						{
							var msg = Serializer.run(Full);
							client.connection.sendString(msg);
						}

					case SetDirection(dir):
						if(client.player != null) client.player.dir = dir;

					case StartMove:
						if(client.player != null) client.player.speed = 3;

					case StopMove:
						if(client.player != null) client.player.speed = 0;
					
					case Ping:
						log("pong");
						var m = Serializer.run(Message.Pong);
						trace(m);
						client.connection.sendString(m);
						
					case DropTrap:
						if(client.player != null) world.dropTrap(client.player);

					case Adm(pw,cmd):
						if(pw == adminPasword)
							switch(cmd)
							{
								case ST:
									var s = world.getStats();
									var st = {
										c:0,
										p:s.p,
										bb:s.bb,
										ai:s.ai,
										coll:s.coll,
										t:s.t,
										miss:0,
										mass:0,
										ss:0
									};
									var m = Serializer.run(RST(st));
									client.connection.sendString(m);
							}
				}
			};
		return client;
	}
}

class Client {
	public var connection(default, null):WebSocket;
	public var player:Object;

	public function new(connection)
		this.connection = connection;

	public function update()
	{
		connection.process();
		return connection.readyState != Closed;
	}
}

/*
class Connection extends haxe.net.WebSocket
{
	public function send(m:String)
	{
		this.sendString(m);
	}
}
*/
