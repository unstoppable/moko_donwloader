package 
{
	[Bindable]
	public class UrlVO 
	{
		public var name:String;
		public var url:String;
		public var data:String;
		public var loading:Boolean=false;
		public var progress:Number=0;
		
		public function UrlVO(u:String='')
		{
			this.url = u;
		}
	}
}