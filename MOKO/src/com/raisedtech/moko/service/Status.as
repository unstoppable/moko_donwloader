package com.raisedtech.moko.service 
{
	dynamic public class Status
	{
		public var status:int = 401;
		public var message:String = "Sorry, Operation Failed, Please try again later";
		
		public function Status()
		{
		}
		
		public function get success():Boolean{
			return status==200;
		}
	}
}