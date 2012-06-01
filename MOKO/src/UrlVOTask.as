package 
{
	import com.raisedtech.queueprocess.SimpleTask;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	[Bindable]
	public class UrlVOTask  extends SimpleTask
	{
		protected static var logger:ILogger= Log.getLogger("UrlVOTask");
		public var urlvo:UrlVO;
		
		protected static function log(...arg):void{
			logger.debug(arg.join(" "));
		}
		
		public function UrlVOTask(url:UrlVO)
		{
			this.urlvo=url;
			_isAsynchronism=true;
		}
		
		override public function execute():void{
			var urlLoader:URLLoader = new HttpLoader();
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoader);
			urlLoader.addEventListener(Event.COMPLETE, onLoader);
			urlLoader.addEventListener(ProgressEvent.PROGRESS,onProgress);
			urlLoader.load(new URLRequest(this.urlvo.url));
		}
		
		protected function onLoader(event:Event):void
		{
			var urlLoader:URLLoader =  URLLoader(event.target);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onLoader);
			urlLoader.removeEventListener(Event.COMPLETE, onLoader);
			urlLoader.removeEventListener(ProgressEvent.PROGRESS,onProgress);
			if(event.type==Event.COMPLETE){
				this.urlvo.data =urlLoader.data;
			}
			this.urlvo.progress=1;
			this.complete();
		}
		
		protected function onProgress(event:ProgressEvent):void
		{
			this.urlvo.progress = Math.min(1,event.bytesLoaded/event.bytesTotal);
		}
		
	}
}