package
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	public class HttpLoader extends URLLoader
	{
		protected static var CHARSET:RegExp = /charset=([\w-]+)/i;
		public function HttpLoader(request:URLRequest=null)
		{
			super(request);
			dataFormat= URLLoaderDataFormat.BINARY;
			addEventListener(Event.COMPLETE, onLoader);
		}
		
		protected function onLoader(event:Event):void
		{
			removeEventListener(Event.COMPLETE, onLoader);
			var ba:ByteArray = this.data;
			var str:String = ba.toString();
			if(CHARSET.test(str)){
				var rs:Array = str.match(CHARSET);
				var charset:String = rs[1];
				str = ba.readMultiByte(ba.bytesAvailable,charset);
			}
			this.data =str;
		}
	}
}