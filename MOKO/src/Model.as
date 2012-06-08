package
{
	import mx.collections.ArrayCollection;

	[Bindable]
	public class Model
	{
		public function Model()
		{
		}

		private static var _model:Model;

		public static function getModel():Model
		{
			if (!_model)
			{
				_model=new Model();
			}
			return _model;
		}

		public var server:Server=new Server();

		public var list:ArrayCollection=new ArrayCollection();

		public static function getList():void
		{
			getModel().server.list(Model.onData);
		}

		public static function save(name:String, url:String,logo:String):void
		{
			getModel().server.save(name, url,logo, Model.onData);
		}


		public static function thumbup(id:String):void
		{
			getModel().server.thumbup(id, Model.onData);
		}

		private static function onData(s:Status):void
		{
			if (s.success)
			{
				getModel().list.source=s.data;

			}
		}
	}
}
