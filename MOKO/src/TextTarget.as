package 
{
	
	import mx.core.mx_internal;
	import mx.logging.targets.LineFormattedTarget;
	
	import spark.components.TextArea;
	
	use namespace mx_internal;
	
	public class TextTarget extends LineFormattedTarget
	{
		private var count:int = 0;
		private var textField:TextArea;
		public function TextTarget(textField:TextArea)
		{
			super();
			this.textField=textField;
		}
		
		override mx_internal function internalLog(message:String):void
		{
			Debug.log(message);
			if(count>50000){
				textField.text = '';
				count = 0;
			}
			count+=message.length;
			textField.appendText(message+"\n");
		}
	}
	
}
