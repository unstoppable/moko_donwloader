package
{
	import com.adobe.serialization.json.JSONEncoder;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.Dictionary;
	
	import mx.utils.Base64Encoder;

	public class Tracker
	{
		private static var _instance:Tracker;
		private var _dic:Dictionary = new Dictionary();
		private var _arr:Array =[];
		private var _type:String;
		private var _url:String;
		private var _errorCount:int=0;
		private var _enabled:Boolean;
		public function Tracker(url:String,type:String, enabled:Boolean=true)
		{
			_type=type;
			_url=url;
			_enabled=enabled;
			startup();
		}
		
		private function startup():void
		{
			try
			{
				var encoder:JSONEncoder=new JSONEncoder(getInfo());
				addQueue("Info",encoder.getString());
				addQueue("Count",getUsedCount().toString());
				addQueue("OS",Capabilities.os);
				if(ExternalInterface.available){
					addQueue("StartUp",ExternalInterface.call("location.href.toString"));
					addQueue("userAgent",ExternalInterface.call("navigator.userAgent.toString"));
				}
				this.flush();
			} 
			catch(error:Error) 
			{
				Debug.log([this,error]);
			} 
			
		}
		
		public static function initTracker(url:String,type:String):void{
			if(!_instance)
				_instance = new Tracker(url,type);
		}
		
		public static function track(name:String,params:*=''):void{
			if(_instance)
				_instance.addQueue(name,params?params.toString():'');
			//_instance.doTrack(name,params?params.toString():'');
		}
		
		public static function flush(callback:Function=null):void{
			if(_instance){
				_instance.flush(callback);
			}
		}
		
		public function addQueue(name:String,params:String):void{
			Debug.log([this,"addQueue",name,params]);
			var data:Object = {};
			data.name = name;
			data.type = _type;
			data.params = params;
			_arr.push(data);
			if(_arr.length>=5){
				flush();
			}
		}
		
		
		private function flush(callback:Function=null):void
		{
			if(!_enabled){
				_arr = [];
				return;
			}
			try
			{
				if(_errorCount>1){
					if(callback!=null)
						callback();
					return;
				}
				Debug.log([this,"flush, record length="+_arr.length]);
				if(!_url||!_type||!_arr.length){
					Debug.error([this,"flush",'(_url,_type,name)=(',_url,_type,")"]);
					
					if(callback!=null)
						callback();
					return;
				}
				//encode data
				var encoder:JSONEncoder=new JSONEncoder(_arr);
				var str:String = encoder.getString();
				var base64:Base64Encoder = new Base64Encoder();
				base64.encodeUTFBytes(str);
				str = base64.drain();
				_arr = [];
				
				
				//send request
				var data:URLVariables = new URLVariables();
				data.data = str;
				var req:URLRequest = new URLRequest(_url);
				req.method = URLRequestMethod.POST;
				req.data = data;
				var loader:URLLoader = new URLLoader();
				if(callback!=null)
					_dic[loader] = callback;
				loader.addEventListener(IOErrorEvent.IO_ERROR, onComplete);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				loader.addEventListener(Event.COMPLETE, onComplete);
				loader.load(req);
			} 
			catch(error:Error) 
			{
				Debug.log([this,error]);
				if(callback!=null)
					callback();
			}
			
		}
		
		protected function onSecurityError(event:SecurityErrorEvent):void
		{
			Debug.error([this,"onSecurityError",event]);
			_errorCount = int.MAX_VALUE;
		}
		
		protected function onComplete(event:Event):void
		{
			var loader:URLLoader = URLLoader(event.target);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onComplete);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onComplete);
			loader.removeEventListener(Event.COMPLETE, onComplete);
			if(_dic[loader]&&_dic[loader] is Function){
				var callback:Function = _dic[loader];
				delete _dic[loader];
				callback();
			}
			if(Event.COMPLETE!=event.type){
				_errorCount++;
			}
		}
		
		protected function getInfo():*{
			var obj:* ={};
			obj.avHardwareDisable = Capabilities.avHardwareDisable;
			obj.cpuArchitecture = Capabilities.cpuArchitecture;
			obj.hasAudio = Capabilities.hasAudio;
			obj.hasTLS  = Capabilities.hasTLS ;
			obj.isDebugger  = Capabilities.isDebugger ;
			obj.language  = Capabilities.language ;
			obj.manufacturer  = Capabilities.manufacturer ;
			obj.maxLevelIDC  = Capabilities.maxLevelIDC ;
			obj.pixelAspectRatio  = Capabilities.pixelAspectRatio ;
			obj.playerType  = Capabilities.playerType ;
			obj.screenColor  = Capabilities.screenColor ;
			obj.screenDPI  = Capabilities.screenDPI ;
			obj.resolutionX  = Capabilities.screenResolutionX ;
			obj.resolutionY  = Capabilities.screenResolutionY ;
			obj.s32Bit= Capabilities.supports32BitProcesses ;
			obj.s64Bit= Capabilities.supports64BitProcesses ;
			obj.version  = Capabilities.version ;
			return obj;
		}
		
		protected function getUsedCount():int{
			var so:SharedObject = SharedObject.getLocal('info');
			var rs:int = so.data['count']?so.data['count']:0;
			so.data['count'] = rs+1;
			so.flush();
			return rs;
		}
	}
}

