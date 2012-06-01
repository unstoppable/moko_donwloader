package 
{
	import com.raisedtech.queueprocess.SimpleTask;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import flash.net.URLRequestHeader;
	
	[Bindable]
	public class PhotoDownloadTask  extends SimpleTask
	{
		protected static var logger:ILogger= Log.getLogger("PhotoDownloadTask");
		public var urlvo:UrlVO;
		
		protected static function log(...arg):void{
			logger.debug(arg.join(" "));
		}
		
		public function PhotoDownloadTask(url:UrlVO)
		{
			this.urlvo=url;
			_isAsynchronism=true;
		}
		
		override public function execute():void{
			var req:URLRequest = new URLRequest(this.urlvo.url);
			req.requestHeaders = [new URLRequestHeader("Referer", "http://www.moko.cc")];
				
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoader);
			urlLoader.addEventListener(Event.COMPLETE, onLoader);
			urlLoader.addEventListener(ProgressEvent.PROGRESS,onProgress);
			urlLoader.dataFormat=URLLoaderDataFormat.BINARY;
			urlLoader.load(req);
		}
		
		protected function onLoader(event:Event):void
		{
			var urlLoader:URLLoader =  URLLoader(event.target);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onLoader);
			urlLoader.removeEventListener(Event.COMPLETE, onLoader);
			urlLoader.removeEventListener(ProgressEvent.PROGRESS,onProgress);
			if(event.type==Event.COMPLETE){
				this.urlvo.data = ImageSaver.save(urlvo.name,urlLoader.data);
			}else{
				trace(event+"\t\t"+urlLoader.data);
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