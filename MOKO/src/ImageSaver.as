package
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class ImageSaver
	{
		public function ImageSaver()
		{
		}
		
		public static var user:String = "";
		
		public static function save(name:String, data:ByteArray):String{
			var file:File = File.desktopDirectory.resolvePath(user);
			if(!file.exists){
				file.createDirectory()
			}
			file=file.resolvePath(name);
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.WRITE);
			stream.writeBytes(data);
			stream.close();
			return file.nativePath;
		}
	}
}