package tools;

import haxe.*;
import haxe.net.WebSocket;
import mp.Message;
import mp.Command;

class CLI
{
    static function main()
    {
        var args = Sys.args();

	    var serverAdress = "localhost";
	    var serverPort = 8888;
	    var adminPasword = "LDXLHAXESERV";

        var  msc = WebSocket.create('ws://$serverAdress:$serverPort');

		msc.onopen = function(){
			log('registering the game');
			msc.sendString(Serializer.run(Adm(adminPasword,ST)));
		}

		msc.onerror = function(msg:String){
			log('ERROR : issue with server \n$msg');
		}

		msc.onclose = function(){
			log("ERROR : connection to server lost");
		}
		
		msc.onmessageString = function(msg)
        {
			var command:Message = null;
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
                case RST(st):
                    log(Std.string(st));
				default :
					//log('ERROR : not supposed to recieve $command message');
			}

            Sys.exit(0);
		}
    }
	static function log(str:String)
	{
		var date = Date.now();
		var dateStr = DateTools.format(date,"%Y-%m-%d %H:%M:%S");
		Sys.println('[$dateStr] $str');
	}
}