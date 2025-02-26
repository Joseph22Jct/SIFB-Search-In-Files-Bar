@tool
extends PanelContainer

class_name SIFB_ResultBase

@onready var resultButton : Button  = $MarginContainer/Button
@onready var resultFileNameLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/file
@onready var resultFilePathLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/path
@onready var resultFileLineLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/LineNo
@onready var nodeInfo : HBoxContainer = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/nodeInfo
@onready var nodeName : Label = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/nodeInfo/NodeName
@onready var nodeTexture : TextureRect = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/nodeInfo/TextureRect
@onready var prevLineLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/prevLine
@onready var prevLineNumberLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/number
@onready var postLineLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/postLine
@onready var postLineNumberLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/number
@onready var prevKeyLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer3/MarginContainer/HBoxContainer/prekLine
@onready var KeyLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer3/MarginContainer/HBoxContainer/kLine
@onready var KeyNumberLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer3/number
@onready var postKeyLabel : Label = $MarginContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer3/MarginContainer/HBoxContainer/postkLine
@onready var PreKeyContainer  = $MarginContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer
@onready var PostKeyContainer  = $MarginContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2


var lineFound : int = 0
var charFound : int = 0
var scriptAssigned : Script = null
var filePath : String = ""
var nodeAttached : Node = null

func _ready():
	resultButton.pressed.connect(onButtonPress)
	
func grab_focus():
	resultButton.grab_focus()
	
func SetUpResult(struct : SIFB_ResultStruct):
	resultFileNameLabel.text = struct.filePath.get_file()
	resultFilePathLabel.text = struct.filePath.get_base_dir()+"/"
	resultFileLineLabel.text = " - Line: "+ str(struct.lineNumber)
	
	nodeInfo.visible = false
	PreKeyContainer.visible = true
	PostKeyContainer.visible = true
	
	if(struct.prevLine == ""): prevLineLabel.visible = false
	else: prevLineLabel.visible = true
	if(struct.afterLine == ""): postLineLabel.visible = false
	else: postLineLabel.visible = true
	prevLineLabel.text = struct.prevLine
	postLineLabel.text = struct.afterLine
	
	prevKeyLabel.text = struct.curLinePreviousKey
	postKeyLabel.text = struct.curLineAfterKey
	KeyLabel.text = struct.curLineKey
	KeyNumberLabel.text = str(struct.lineNumber)+": "
	postLineNumberLabel.text = str(struct.lineNumber+1)+": "
	prevLineNumberLabel.text = str(struct.lineNumber-1)+": "
	
	if(struct.prevLine.strip_edges(true,true) == ""):
		PreKeyContainer.visible = false
	if(struct.afterLine.strip_edges(true,true) == ""):
		PostKeyContainer.visible = false
	
	lineFound = struct.lineNumber
	charFound = struct.charFound
	scriptAssigned = struct.scriptAssigned
	filePath = struct.filePath
	nodeAttached = struct.nodewithScript
	
	if(nodeAttached!=null):
		nodeInfo.visible = true
		nodeName.text = " "+ nodeAttached.name
		nodeTexture.texture = get_theme_icon(nodeAttached.get_class(), "EditorIcons")
		
	pass
	
func onButtonPress():
	
	if(scriptAssigned!=null):
		EditorInterface.open_scene_from_path(filePath)
		EditorInterface.edit_script(scriptAssigned, lineFound,charFound,true)
	else:
		EditorInterface.edit_script(load(filePath), lineFound,charFound,true)
