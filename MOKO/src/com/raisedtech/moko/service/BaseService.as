package com.raisedtech.moko.service  
{
	import com.adobe.serialization.json.JSONDecoder;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.Dictionary;
	
	import mx.logging.ILogger;
	import mx.logging.Log;

	public class BaseService
	{
		private static var _dic:Dictionary = new Dictionary();
		private static var log:ILogger= Log.getLogger("BaseService");
		protected var appUrl:String= null;
		
		public function BaseService(appUrl:String)
		{
			this.appUrl=appUrl;
		}
		
		public function send(url:String, data:Object, callback:Function):void{
			var req:URLRequest = new URLRequest();
			req.data = data;
			req.method = URLRequestMethod.POST;
			req.url = url;
			
			var loader:URLLoader = new URLLoader();
			if(null!=callback)
				_dic[loader]=callback;
			addEvenListeners(loader);
			loader.load(req);
		}
		
		private function addEvenListeners(target:IEventDispatcher):void{
			target.addEventListener(Event.COMPLETE, onLoadComplete);
			target.addEventListener(IOErrorEvent.IO_ERROR, onLoadIOError);
			target.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadSecurityError);
		}
		private function removeEvenListeners(target:IEventDispatcher):void{
			target.removeEventListener(Event.COMPLETE, onLoadComplete);
			target.removeEventListener(IOErrorEvent.IO_ERROR, onLoadIOError);
			target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadSecurityError);
		}
		
		protected function onLoadSecurityError(event:SecurityErrorEvent):void
		{
			var loader:URLLoader =  URLLoader(event.target);
			var callback:Function = _dic[loader];
			delete _dic[loader];
			removeEvenListeners(loader);
			if(null!=callback){
				callback(new Status());
			}
		}
		
		protected function onLoadIOError(event:IOErrorEvent):void
		{
			var loader:URLLoader =  URLLoader(event.target);
			var callback:Function = _dic[loader];
			delete _dic[loader];
			removeEvenListeners(loader);
			var s:Status = new Status();
			if(loader.data){
				s.message = "onLoadIOError:"+loader.data;
				log.error(s.message);
			}
			if(null!=callback){
				callback(s);
			}
		}
		
		protected function onLoadComplete(event:Event):void
		{
			var loader:URLLoader =  URLLoader(event.target);
			removeEvenListeners(loader);
			log.debug(loader.data);
			var s:Status = new Status();
			try
			{
				var data:Object = parseJSON(loader.data);
				for(var key:String in data){
				s[key] = data[key];
				}
				if(!s.message){
					s.message = loader.data;
				}
			} 
			catch(error:Error) 
			{
				s.message = "parseJSON Error:"+error.getStackTrace();
			}
			var callback:Function = _dic[loader];
			delete _dic[loader];
			if(null!=callback){
				callback(s);
			}
		}
		
		protected function parseJSON(json:String):Object{
			var decoder:JSONDecoder = new JSONDecoder(json,false);
			return decoder.getValue();
		}
		
		protected function genRequestUrl(name:String, method:String):String{
			return this.appUrl+name+"/"+method;
		}
	}
}