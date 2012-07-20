package com.raisedtech.moko.service
{
	import flash.net.URLVariables;
	
	import mx.logging.ILogger;
	import mx.logging.Log;

	[Bindable]
	public class Server extends BaseService
	{
		private static var log:ILogger=Log.getLogger("Server");
		public static const NAME:String="moko"

		public function Server()
		{
			super('http://www.raisedtech.com/iphone-ipa-png/');
		}

		public function list(callback:Function):void
		{
			this.doRequest("list", callback);
		}

		public function thumbup(id:String, callback:Function):void
		{
			this.doRequest("thumbup", callback, {id: id});
		}

		public function save(name:String, url:String,logo:String, callback:Function):void
		{
			this.doRequest("save", callback, {name: name, url: url,logo:logo});
		}

		protected function doRequest(method:String, callback:Function, params:Object=null):void
		{
			var url:String=genRequestUrl(NAME, method);
			log.debug("url={0}", url);
			var data:URLVariables=new URLVariables();
			for (var key:String in params)
			{
				log.debug("{0}={1}", key,params[key]);
				data[key]=params[key];
			}
			this.send(url, data, callback);
			
		}

	}
}
