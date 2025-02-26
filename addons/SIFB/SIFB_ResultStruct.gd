extends Node

class_name SIFB_ResultStruct

var prevLine :String = ""
var curLinePreviousKey :String = ""
var curLineKey :String = ""
var curLineAfterKey :String = ""
var afterLine :String = ""

var fileName : String= ""
var lineNumber: int = 0
var charFound : int = 0
var filePath:String = ""

var scriptAssigned: Script = null
var nodewithScript : Node = null

var builtInScriptNode: Node = null
