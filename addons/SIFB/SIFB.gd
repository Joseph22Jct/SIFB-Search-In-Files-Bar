@tool
extends EditorPlugin

class_name SIFB_Plugin

var ScriptEditorInstance : ScriptEditor
var FileSystemDockInstance : FileSystemDock
var EditorFileSystemInstance : EditorFileSystem

var NodeBase = preload("res://addons/SIFB/SIFB.tscn")
var NodeInstance:SIFB_ControlNode
var fileExtensionsThatCanBeLooked = [".gd", ".gdshader", ".txt", ".json", ".tscn"]
var openingShortcut : Shortcut = Shortcut.new()
var searchShortcut : Shortcut = Shortcut.new()

var SearchCharacterLimit = 60

var RelevantFiles = {}

signal SearchResults(results: Array[SIFB_ResultStruct])

func _enter_tree():
	ScriptEditorInstance = EditorInterface.get_script_editor()
	FileSystemDockInstance = EditorInterface.get_file_system_dock()
	EditorFileSystemInstance = EditorInterface.get_resource_filesystem()
	NodeInstance = NodeBase.instantiate()
	
	LoadSavedShortcuts()
	add_control_to_bottom_panel(NodeInstance, "Search In Files", openingShortcut)
	await get_tree().process_frame
	NodeInstance.SIFB_Base = self
	NodeInstance.request_search.connect(ProcessSearch)
	connect("SearchResults", NodeInstance.CreateResults)
	InitializeDirectories()
	EditorFileSystemInstance.filesystem_changed.connect(InitializeDirectories)
	
	
	
func _exit_tree():
	remove_control_from_bottom_panel(NodeInstance)
	NodeInstance.queue_free()

func _input(event):
			
	if(searchShortcut.matches_event(event)):
		if(event.is_pressed()):
			if(!NodeInstance.SearchLineEdit.has_focus()):
				var codeHighlighted : String = ScriptEditorInstance.get_current_editor().get_base_editor().get_selected_text()
				if( codeHighlighted != ""):
					NodeInstance.SearchLineEdit.text = codeHighlighted.substr(0,SearchCharacterLimit)
				NodeInstance.SearchLineEdit.grab_focus()
				NodeInstance.SearchLineEdit.select_all()
			else:
				var scripts = ScriptEditorInstance.get_open_scripts()
				if(len(scripts)<=0):
					return
				else:
					EditorInterface.edit_script(ScriptEditorInstance.get_current_script(), -1,0,true)
					

func InitializeDirectories():
	
	var directory_queue = ["res://"]
	RelevantFiles = {}
	for extension in fileExtensionsThatCanBeLooked:
		RelevantFiles[extension]= []
	RelevantFiles["node"] = []
	
	while directory_queue.size()!=0:
		var currentDirectory = DirAccess.open(directory_queue[0])
		if currentDirectory:
			currentDirectory.list_dir_begin()
			var currentFileName = currentDirectory.get_next()
			while currentFileName!="":
				if(currentDirectory.current_is_dir()):
					if(currentFileName!=".godot"):
						directory_queue.append(directory_queue[0]+currentFileName+"/")
						#print("Found directory: "+ directory_queue[0]+currentFileName)
				else:
					for extension:String in fileExtensionsThatCanBeLooked:
						if(currentFileName.to_lower().ends_with(extension.to_lower()) && extension!=".tscn"):
							RelevantFiles[extension].append(directory_queue[0]+currentFileName)
							break;
						elif(currentFileName.to_lower().ends_with(".tscn") && extension == ".tscn"):
							var resource : PackedScene = load(directory_queue[0]+currentFileName)
							var localscene : Node = resource.instantiate()
							var queue_to_check : Array[Node] = [localscene]
							while len(queue_to_check)!=0:
								queue_to_check.append_array(queue_to_check[0].get_children()) 
								var script :Script= queue_to_check[0].get_script()
								if(script!=null):
									if(script.resource_path.contains("::")): ##this works, yay!
										if !(script in RelevantFiles[extension]):
											RelevantFiles[extension].append(script)
											RelevantFiles["node"].append(queue_to_check[0])
								queue_to_check.pop_at(0)
							pass
							queue_to_check = []
							
				currentFileName = currentDirectory.get_next()
		else:
			printerr("An error occurred when trying to access the path.")
		directory_queue.pop_at(0)
	
	#print(RelevantFiles)

func ProcessSearch(search: String, WholeWords: bool, MatchCase:bool, 
						F_GDFileType:bool, F_GDShaderFileType:bool, F_TxtFileType:bool, F_JSONFileType:bool, 
						F_BuiltInScript:bool, F_IncludeAddons:bool, SearchLimit: int):
	#print("Search for: '", search, "' started. WW:", WholeWords, ". MC:",MatchCase,". F_GD:",F_GDFileType,
		  #". F_txt:",F_TxtFileType,". F_JSON:",F_JSONFileType,
		  #". F_GDS:",F_GDShaderFileType,". F_BIS:",F_BuiltInScript,". F_IA:",F_IncludeAddons
		  #, ". Search Limit: ",SearchLimit)
	
	if(!F_GDFileType && !F_GDShaderFileType && !F_TxtFileType && 
		!F_JSONFileType && !F_BuiltInScript):
		F_GDFileType= true
		F_GDShaderFileType=true
		F_TxtFileType=true
		F_JSONFileType=true
		F_BuiltInScript=true
	
	var fileExtensionsToLookFor = []
	if(F_GDFileType): fileExtensionsToLookFor.append(".gd")
	if(F_GDShaderFileType): fileExtensionsToLookFor.append(".gdshader")
	if(F_TxtFileType): fileExtensionsToLookFor.append(".txt")
	if(F_JSONFileType): fileExtensionsToLookFor.append(".json")
	if(F_BuiltInScript): fileExtensionsToLookFor.append(".tscn")
	
	var Results : Array[SIFB_ResultStruct] = []
	
	for extension in fileExtensionsToLookFor:
		if(extension!= ".tscn"):
			for filepath:String in RelevantFiles[extension]:
				
				if(filepath.begins_with("res://addons/")):
					if(!F_IncludeAddons):
						continue
				var FileTextStrings : PackedStringArray = FileAccess.get_file_as_string(filepath).split("\n")
				for lineNo in range(len(FileTextStrings)):
					var charsIgnored = 0
					var charSearch
					if(MatchCase): charSearch = FileTextStrings[lineNo].find(search, charsIgnored)
					else: charSearch = FileTextStrings[lineNo].findn(search, charsIgnored)
					charsIgnored = charSearch
					while charSearch!=-1:
						if(search.to_lower() in FileTextStrings[lineNo].to_lower()):
							if(SearchLimit<=Results.size()):
								SearchResults.emit(Results)
								return
							var skipAppend = false
							if(WholeWords): 
								if(charSearch>0):
									var asciiival = FileTextStrings[lineNo][charSearch-1].to_ascii_buffer()[0]
									if( (asciiival >= 65 and asciiival <= 90) or (asciiival >= 97 and asciiival <= 122)):
										skipAppend = true
								if(charSearch+len(search)<len(FileTextStrings[lineNo])):
									var asciiival = FileTextStrings[lineNo][charSearch+len(search)].to_ascii_buffer()[0]
									if( (asciiival >= 65 and asciiival <= 90) or (asciiival >= 97 and asciiival <= 122)):
										skipAppend = true
							if(!skipAppend):
								print("Result given: ", charSearch, " ", FileTextStrings[lineNo])
								Results.append(GenerateResult(FileTextStrings,lineNo, charSearch, search,filepath))
						charsIgnored = charSearch+len(search)
						if(MatchCase): charSearch = FileTextStrings[lineNo].find(search, charsIgnored)
						else: charSearch = FileTextStrings[lineNo].findn(search, charsIgnored)
						
		elif(extension == ".tscn"):
			for instance : int in range(len(RelevantFiles[extension])):
				var script = RelevantFiles[extension][instance]
				var node = RelevantFiles["node"][instance]
				var filePath =	script.resource_path.substr(0, script.resource_path.find("::")) 
				if(script.resource_path.begins_with("res://addons/")):
					if(!F_IncludeAddons):
						continue
				var FileTextStrings : PackedStringArray = script.source_code.split("\n")
				for lineNo in range(len(FileTextStrings)):
						var charsIgnored = 0
						var charSearch
						if(MatchCase): charSearch = FileTextStrings[lineNo].find(search, charsIgnored)
						else: charSearch = FileTextStrings[lineNo].findn(search, charsIgnored)
						while charSearch!=-1:
							if(search.to_lower() in FileTextStrings[lineNo].to_lower()):
								if(SearchLimit<=Results.size()):
									SearchResults.emit(Results)
									return
								var skipAppend = false
								if(WholeWords): 
									if(charSearch>0):
										var asciiival = FileTextStrings[lineNo][charSearch-1].to_ascii_buffer()[0]
										if( (asciiival >= 65 and asciiival <= 90) or (asciiival >= 97 and asciiival <= 122)):
											skipAppend = true
									if(charSearch+len(search)<len(FileTextStrings[lineNo])):
										var asciiival = FileTextStrings[lineNo][charSearch+len(search)].to_ascii_buffer()[0]
										if( (asciiival >= 65 and asciiival <= 90) or (asciiival >= 97 and asciiival <= 122)):
											skipAppend = true
								if(!skipAppend):
									Results.append(GenerateResult(FileTextStrings,lineNo, charSearch, search,filePath, script, node))
							charsIgnored = charSearch+len(search)
							if(MatchCase): charSearch = FileTextStrings[lineNo].find(search, charsIgnored)
							else: charSearch = FileTextStrings[lineNo].findn(search, charsIgnored)
				pass
	
	SearchResults.emit(Results)


func GenerateResult(file_string : PackedStringArray, foundResultAtLine : int, foundAtChar: int ,
		search_keyword : String, filepath: String, script:Script = null, node :Node = null) -> SIFB_ResultStruct:
	
	var toReturn : SIFB_ResultStruct = SIFB_ResultStruct.new()
	
	if(foundResultAtLine>=1):
		toReturn.prevLine = file_string[foundResultAtLine-1]
	
	if(foundResultAtLine+1<file_string.size()):
		toReturn.afterLine = file_string[foundResultAtLine+1]
		
	var curLine = file_string[foundResultAtLine]
	
	toReturn.curLinePreviousKey = curLine.substr(0,foundAtChar)
	toReturn.curLineKey = curLine.substr(foundAtChar,len(search_keyword))
	toReturn.curLineAfterKey = curLine.substr(foundAtChar+len(search_keyword))
	
	toReturn.lineNumber = foundResultAtLine+1
	toReturn.charFound = foundAtChar
	toReturn.filePath = filepath
	toReturn.fileName = filepath.get_file()
	
	toReturn.scriptAssigned = script
	toReturn.nodewithScript = node

	#print("Generated Result at ",toReturn.fileName ,": \n",toReturn.prevLine,"\n",
	#toReturn.curLinePreviousKey, toReturn.curLineKey,toReturn.curLineAfterKey,"\n", toReturn.afterLine,
	#"\n",toReturn.lineNumber,": ", toReturn.fileName, ", char:", toReturn.charFound)
	
	return toReturn
	
	
func SaveNewShortcuts():
	var OSEvent : InputEventKey= openingShortcut.events[0]	
	var SSEvent : InputEventKey= searchShortcut.events[0]	 
	var ToSave : Dictionary = {}
	ToSave["OpeningShortcut"] = {}
	ToSave["OpeningShortcut"]["Ctrl"] = OSEvent.ctrl_pressed
	ToSave["OpeningShortcut"]["Shift"] = OSEvent.shift_pressed
	ToSave["OpeningShortcut"]["Alt"] = OSEvent.alt_pressed
	ToSave["OpeningShortcut"]["Keycode"] = OSEvent.keycode
	ToSave["SearchShortcut"] = {}
	ToSave["SearchShortcut"]["Ctrl"] = SSEvent.ctrl_pressed
	ToSave["SearchShortcut"]["Shift"] = SSEvent.shift_pressed
	ToSave["SearchShortcut"]["Alt"] = SSEvent.alt_pressed
	ToSave["SearchShortcut"]["Keycode"] = SSEvent.keycode
	
	var save_file =FileAccess.open("res://addons/SIFB/config.json",FileAccess.WRITE)
	var data = JSON.stringify(ToSave)
	save_file.store_line(data)
	
func LoadSavedShortcuts():
	openingShortcut.events.append(InputEventKey.new())
	searchShortcut.events.append(InputEventKey.new())
	if(not FileAccess.file_exists("res://addons/SIFB/config.json")):
		openingShortcut.events[0].ctrl_pressed = true
		openingShortcut.events[0].shift_pressed = true
		openingShortcut.events[0].keycode = 71 ## G
		searchShortcut.events[0].ctrl_pressed = true
		searchShortcut.events[0].keycode = 71 ## G
		return
	
	var save_file = FileAccess.open("res://addons/SIFB/config.json", FileAccess.READ)
	var json_string = save_file.get_line()
	var json = JSON.new()
	json.parse(json_string)
	var shortcutData = json.data
	var toAssign :InputEventKey = InputEventKey.new()
	toAssign.ctrl_pressed = shortcutData["OpeningShortcut"]["Ctrl"]
	toAssign.shift_pressed = shortcutData["OpeningShortcut"]["Shift"]
	toAssign.alt_pressed = shortcutData["OpeningShortcut"]["Alt"]
	toAssign.keycode = shortcutData["OpeningShortcut"]["Keycode"]
	openingShortcut.events[0]=toAssign
	
	var toAssign2 = InputEventKey.new()
	toAssign2.ctrl_pressed = shortcutData["SearchShortcut"]["Ctrl"]
	toAssign2.shift_pressed = shortcutData["SearchShortcut"]["Shift"]
	toAssign2.alt_pressed = shortcutData["SearchShortcut"]["Alt"]
	toAssign2.keycode = shortcutData["SearchShortcut"]["Keycode"]
	searchShortcut.events[0]=toAssign2
