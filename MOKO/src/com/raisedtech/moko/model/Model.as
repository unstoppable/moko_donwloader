package com.raisedtech.moko.model
{
	import com.raisedtech.moko.SpiderDownloader;
	import com.raisedtech.moko.service.Server;
	import com.raisedtech.moko.service.Status;
	
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
		
		public var downloader:SpiderDownloader = new SpiderDownloader();

		public var server:Server=new Server();

		public var list:ArrayCollection=new ArrayCollection();
		
		public var loading:Boolean=true;

		public static function getList():void
		{
			getModel().loading=true;
			getModel().server.list(Model.onData);
		}

		public static function save(name:String, url:String,logo:String, update:Boolean=true):void
		{
			getModel().loading=true;
			getModel().server.save(name, url,logo, update?Model.onData:null);
		}


		public static function thumbup(id:String):void
		{
			getModel().loading=true;
			getModel().server.thumbup(id, Model.onData);
		}

		private static function onData(s:Status):void
		{
			getModel().loading=false;
			if (s.success)
			{
				getModel().list.source=s.data;

			}
		}
		
		
	}
}
