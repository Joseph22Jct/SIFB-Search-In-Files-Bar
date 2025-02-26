@tool
extends MarginContainer

class_name SIFB_ControlNode

signal request_search(search: String, WholeWords: bool, MatchCase:bool, 
						F_GDFileType:bool, F_GDShaderFileType:bool, F_TxtFileType:bool, F_JSONFileType:bool, 
						F_BuiltInScript:bool, F_IncludeAddons:bool, SearchLimit:int)
						
@onready var WholeWordsCheckBox : CheckBox = $"VBoxContainer/Search Bar/HBoxContainer/WholeWords"
@onready var MatchCaseCheckBox : CheckBox = $"VBoxContainer/Search Bar/HBoxContainer/MatchCase"
@onready var F_GDFileTypeCheckBox : CheckBox = $VBoxContainer/Filters/HBoxContainer/HBoxContainer/GDFileType
@onready var F_GDShaderFileTypeCheckBox : CheckBox =$VBoxContainer/Filters/HBoxContainer/HBoxContainer/GDShaderFileType
@onready var F_TxtFileTypeCheckBox : CheckBox = $VBoxContainer/Filters/HBoxContainer/HBoxContainer/TxtFileType
@onready var F_JSONFileTypeCheckBox : CheckBox =$VBoxContainer/Filters/HBoxContainer/HBoxContainer/JSONFileType
@onready var F_BuiltInScriptCheckBox : CheckBox = $VBoxContainer/Filters/HBoxContainer/HBoxContainer/BuiltInScript
@onready var F_IncludeAddonsCheckBox : CheckBox = $VBoxContainer/Filters/HBoxContainer/HBoxContainer/IncludeAddon
@onready var SearchButton : Button = $"VBoxContainer/Search Bar/HBoxContainer/SearchButton"
@onready var SearchLineEdit : LineEdit = $"VBoxContainer/Search Bar/HBoxContainer/MarginContainer/SearchLineEdit"
@onready var ResultList : VBoxContainer = $VBoxContainer/Results/PanelContainer/ScrollContainer/ResultList
@onready var NoResultLabel : Label = $VBoxContainer/Results/PanelContainer/ScrollContainer/ResultList/NoResult
@onready var SearchLimit : SpinBox = $VBoxContainer/Filters/HBoxContainer/HBoxContainer2/SpinBox 


var ResultBase = preload("res://addons/SIFB/result_base.tscn")

var PooledResultObjects : Array[SIFB_ResultBase] = []
var ResultStructs : Array[SIFB_ResultStruct] = []

var initialNoResultColor: Color = Color("404857")
var highlightNoResultColor: Color = Color("3d5468")

func _ready():
	await get_tree().process_frame
	SearchButton.pressed.connect(Search)

func _input(event):
	if(event.is_action_pressed("ui_accept")):
		if(SearchLineEdit.has_focus()):
			Search()
			
	
func Search():
	
	request_search.emit(SearchLineEdit.text, WholeWordsCheckBox.button_pressed, MatchCaseCheckBox.button_pressed,
					F_GDFileTypeCheckBox.button_pressed,F_GDShaderFileTypeCheckBox.button_pressed,
					F_TxtFileTypeCheckBox.button_pressed,F_JSONFileTypeCheckBox.button_pressed,
					F_BuiltInScriptCheckBox.button_pressed, F_IncludeAddonsCheckBox.button_pressed, SearchLimit.value)
	pass
	
func CreateResults(results: Array[SIFB_ResultStruct]):
	#print("Size of Results: ",results.size())
	if(len(results) == 0):
		NoResultLabel.visible = true
		var tween = get_tree().create_tween()
		tween.tween_property(NoResultLabel,"modulate",highlightNoResultColor, 0.03)
		tween.tween_property(NoResultLabel,"modulate",initialNoResultColor, 0.3)
		
	else: NoResultLabel.visible = false
	
	if(results.size() > PooledResultObjects.size()):
		for index in range(results.size()-PooledResultObjects.size()):
			var cnode : SIFB_ResultBase = ResultBase.instantiate()
			PooledResultObjects.append(cnode)
			cnode.visible = false
			ResultList.add_child(cnode)
			if(len(PooledResultObjects)==1):
				PooledResultObjects[0].resultButton.focus_neighbor_top = SearchLimit.get_path()
			else:
				PooledResultObjects[-1].resultButton.focus_neighbor_top = PooledResultObjects[-2].resultButton.get_path()
		pass
	for index in range(len(PooledResultObjects)):
		if(index < results.size()):
			PooledResultObjects[index].visible = true
			PooledResultObjects[index].SetUpResult(results[index])
			pass
		else:
			PooledResultObjects[index].visible = false
	if(results.size()>0):
		PooledResultObjects[0].call_deferred("grab_focus")
	ResultStructs = results
	
	
	
