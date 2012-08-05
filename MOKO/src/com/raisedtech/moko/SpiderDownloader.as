package com.raisedtech.moko
{
	import com.raisedtech.queueprocess.QueueProcessor;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.FlexEvent;
	
	import spark.events.IndexChangeEvent;
	import com.raisedtech.moko.model.Model;
	import com.raisedtech.moko.model.UrlVO;
	import com.raisedtech.moko.model.UrlVOTask;
	import com.raisedtech.moko.helper.HttpLoader;
	import com.raisedtech.moko.helper.ImageSaver;
	import com.raisedtech.moko.model.PhotoDownloadTask;

	[Event(name="connect", type="flash.events.Event")]
	[Event(name="close", type="flash.events.Event")]
	public class SpiderDownloader extends EventDispatcher
	{

		public static var CATEGORY:RegExp=/title="(.+)" href="(\/post\/\w+\/category\/\d+\/1\.html)"/ig;
		public static var ALBUM:RegExp=/title="(.+)" href="(\/post\/\d+\.html)"/ig;
		public static var ALBUM1:RegExp=/href="(\/post\/\d+\.html)" title="([^\n\r"]+)"/ig;
		public static var PHOTO:RegExp=/src2="(.+\.jpg)"/ig;
		public static var NAME:RegExp=/<title>(.*)'s/i;
		public static var IMGUSERLOGO:RegExp=/<img id="imgUserLogo".*src="([^"]+)"/i;

		public function SpiderDownloader(target:IEventDispatcher=null)
		{
			super(target);
		}

		[Bindable]
		public var viewIndex:int=0;

		private static var vardd:*;
		[Bindable]
		public var loading:Boolean=false;
		[Bindable]
		public var user:String="aishangzhen";
		[Bindable]
		public var info:String="Hello~";
		private var _progress:Number=0;
		[Bindable]
		public var categorys:ArrayCollection=new ArrayCollection();
		private var queueReadAlbums:QueueProcessor=new QueueProcessor();
		private var queueDownloadPhotos:QueueProcessor=new QueueProcessor();
		[Bindable]
		public var albums:ArrayCollection=new ArrayCollection();
		private var queueReadPhotos:QueueProcessor=new QueueProcessor();
		[Bindable]
		public var photos:ArrayCollection=new ArrayCollection();

		[Bindable]
		public function get progress():Number
		{
			return _progress;
		}

		public function set progress(value:Number):void
		{
			if (value <= 0 || isNaN(value) || !isFinite(value))
			{
				value=0.01;
			}
			_progress=value;
		}

		protected function onProgress(event:ProgressEvent):void
		{
			progress=event.bytesLoaded / event.bytesTotal;
		}

		//////////////////////////////////////////////////////////////////////////////////////////////
		public function start():void
		{
			if (loading)
			{
				loading=false;
				queueReadAlbums.stop();
				queueDownloadPhotos.stop();
				queueReadPhotos.stop();
				info="已停止";
				this.dispatchEvent(new Event(Event.CLOSE));
				return;
			}
			this.dispatchEvent(new Event(Event.CONNECT));
			
			loading=true;
			//http://www.moko.cc/post/aishangzhen/list.html
			var url:String="http://www.moko.cc/post/" + user + "/list.html";
			ImageSaver.user=user;
			var so:SharedObject=SharedObject.getLocal("user");
			so.data.user=user;
			so.flush();
			so.close();

			trace('load url:' + url);
			info="正在读取" + url;
			var loader:HttpLoader=new HttpLoader();
			loader.addEventListener(Event.COMPLETE, onReadCategorysComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onReadCategorysComplete);
			loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.load(new URLRequest(url));
		}

		protected function onReadCategorysComplete(event:Event):void
		{
			if (!loading)
				return;
			viewIndex=0;
			var loader:HttpLoader=HttpLoader(event.target);
			loader.removeEventListener(Event.COMPLETE, onReadCategorysComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onReadCategorysComplete);
			loader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			if (event.type == Event.COMPLETE)
			{
				categorys.removeAll();
				var source:String=loader.data;
				var tempName:Array=NAME.exec(source);
				if (tempName)
				{
					var tempLogo:Array=IMGUSERLOGO.exec(source);
					var logo:String="";
					if (tempLogo)
					{
						logo=tempLogo[1];
					}
					Model.save(tempName[1], "http://www.moko.cc/post/" + user + "/list.html", logo);
				}

				var temp:Array=CATEGORY.exec(source);
				var arr:Array=[];
				while (temp != null)
				{
					if (-1 == arr.indexOf(temp[2]))
					{
						arr.push(temp[2]);
						for (var i:int = 1; i < 6; i++) 
						{
							var vo:UrlVO=new UrlVO();
							vo.name=temp[1];
							vo.url="http://www.moko.cc" + temp[2].replace("1.html",i+".html");
							categorys.addItem(vo);
						}
						
					}
					temp=CATEGORY.exec(source);
				}
				;
				info=("一共有类别" + arr.length + "个");
				if (arr.length)
				{
					setTimeout(doReadAlbums, 500, categorys.source);
				}
			}
			else
			{
				info=event.toString();
			}
		}

		//////////////////////////////////////////////////////////////////////////////////////////////

		private function doReadAlbums(categorys:Array):void
		{
			if (!loading)
				return;
			progress=0;
			queueReadAlbums.stop();
			queueReadAlbums.removeEventListener(Event.COMPLETE, queueReadAlbumsComplete);
			queueReadAlbums.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			queueReadAlbums=new QueueProcessor();
			queueReadAlbums.addEventListener(Event.COMPLETE, queueReadAlbumsComplete);
			queueReadAlbums.addEventListener(ProgressEvent.PROGRESS, onProgress);
			for each (var i:UrlVO in categorys)
			{
				queueReadAlbums.addTask(new UrlVOTask(i));
			}
			queueReadAlbums.execute();
		}

		protected function queueReadAlbumsComplete(event:Event):void
		{
			if (!loading)
				return;
			viewIndex=1;
			var data:String='';
			for each (var i:UrlVO in categorys.source)
			{
				data+=i.data;
			}
			albums.removeAll();
			albums.disableAutoUpdate();

			var arr:Array=matchAlbums(data);
			if (arr.length == 0)
			{
				arr=matchAlbums1(data);
			}
			info=("一共有专辑" + arr.length + "个");
			if (arr.length)
			{
				setTimeout(doReadPhotos, 500, albums.source);
			}
			albums.refresh();
		}

		private function matchAlbums(data:String):Array
		{
			var temp:Array=ALBUM.exec(data);
			var arr:Array=[];
			while (temp != null)
			{
				if (-1 == arr.indexOf(temp[2]))
				{
					arr.push(temp[2]);
					var vo:UrlVO=new UrlVO();
					vo.name=temp[1].replace(/[\\\/:\*\?"<>\|]+/g, '');
					vo.url="http://www.moko.cc" + temp[2];
					albums.addItem(vo);
				}
				temp=ALBUM.exec(data);
			}
			;
			return arr;
		}

		private function matchAlbums1(data:String):Array
		{
			var temp:Array=ALBUM1.exec(data);
			var arr:Array=[];
			while (temp != null)
			{
				if (-1 == arr.indexOf(temp[1]))
				{
					arr.push(temp[1]);
					var vo:UrlVO=new UrlVO();
					vo.name=temp[2].replace(/[\\\/:\*\?"<>\|]+/g, '');
					vo.url="http://www.moko.cc" + temp[1];
					albums.addItem(vo);
				}
				temp=ALBUM1.exec(data);
			}
			return arr;
		}

		//////////////////////////////////////////////////////////////////////////////////////////////

		private function doReadPhotos(categorys:Array):void
		{
			if (!loading)
				return;
			progress=0;
			queueReadPhotos.stop();
			queueReadPhotos.removeEventListener(Event.COMPLETE, queueReadPhotosComplete);
			queueReadPhotos.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			queueReadPhotos=new QueueProcessor();
			queueReadPhotos.addEventListener(Event.COMPLETE, queueReadPhotosComplete);
			queueReadPhotos.addEventListener(ProgressEvent.PROGRESS, onProgress);
			for each (var i:UrlVO in categorys)
			{
				queueReadPhotos.addTask(new UrlVOTask(i));
			}
			queueReadPhotos.execute();
		}

		protected function queueReadPhotosComplete(event:Event):void
		{
			if (!loading)
				return;
			viewIndex=2;
			photos.removeAll();
			photos.disableAutoUpdate();
			for each (var i:UrlVO in albums.source)
			{
				var temp:Array=PHOTO.exec(i.data);
				var arr:Array=[];
				while (temp != null)
				{
					var u:String=temp[1];
					if (-1 == arr.indexOf(u))
					{
						arr.push(u);
						var vo:UrlVO=new UrlVO();
						vo.url=u;
						vo.name=i.name + '_' + arr.length + ".jpg";
						photos.addItem(vo);
					}
					temp=PHOTO.exec(i.data);
				}
				;
			}
			info=("一共有照片" + arr.length + "个");
			if (arr.length)
			{
				setTimeout(doDownloadPhotos, 1000, photos.source);
			}
			photos.refresh();
		}

		//////////////////////////////////////////////////////////////////////////////////////////////
		private function doDownloadPhotos(photos:Array):void
		{
			if (!loading)
				return;
			info=("正在下载照片" + photos.length + ", 照片正在保存到桌面");
			progress=0;
			queueDownloadPhotos.stop();
			queueDownloadPhotos.removeEventListener(Event.COMPLETE, queueDownloadPhotosComplete);
			queueDownloadPhotos.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			queueDownloadPhotos=new QueueProcessor();
			queueDownloadPhotos.addEventListener(Event.COMPLETE, queueDownloadPhotosComplete);
			queueDownloadPhotos.addEventListener(ProgressEvent.PROGRESS, onProgress);
			for each (var i:UrlVO in photos)
			{
				queueDownloadPhotos.addTask(new PhotoDownloadTask(i));
			}
			queueDownloadPhotos.execute();

		}

		protected function queueDownloadPhotosComplete(event:Event):void
		{
			if (!loading)
				return;
			info=("下载照片完成");
			loading=false;
			Alert.show("下载照片完成! 照片已保存到桌面！");
			this.dispatchEvent(new Event(Event.CLOSE));
		}

	}
}
