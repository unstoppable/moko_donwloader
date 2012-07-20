package com.raisedtech.moko.model
{
	import com.raisedtech.moko.SpiderDownloader;
	
	import flash.events.Event;

	public class NewGirlUrlVOTask extends UrlVOTask
	{
		public function NewGirlUrlVOTask( url:UrlVO)
		{
			super(url);
		}
		
		override protected function complete():void
		{
			if(this.urlvo.data){
				var source:String=this.urlvo.data;
				var tempName:Array=SpiderDownloader.NAME.exec(source);
				if (tempName)
				{
					var tempLogo:Array=SpiderDownloader.IMGUSERLOGO.exec(source);
					var logo:String="";
					if (tempLogo)
					{
						logo=tempLogo[1];
					}
					Model.save(tempName[1], "http://www.moko.cc/post/" + urlvo.name + "/list.html", logo,false);
				}
			}
			
			super.complete();
		}
		
		
	}
}