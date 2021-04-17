extends Control

var stack = []
var netimer = 0
var nelength = 0#.025
var waittimer = 0
var waitlength = 0
var charn = 0
var previous_char = ""
var escape = false
var comment = false
var command = false
var cmd = []
var tb : String
export(String, FILE, "*.tbe") var textbox_file = "res://text.tbe"
var tbf = File.new()
var skip_next_newline = false
var reading_header = true
var eof = false
var waiting_for_user = false

func read_out_tbf():
	tbf.open(textbox_file,File.READ)
	tb = tbf.get_as_text()
	tbf.close()
	clear()
	stack=[]
	charn=0
	waittimer=0
	waitlength=0
	previous_char = ""
	escape = false
	comment = false
	command = false
	cmd = []
	skip_next_newline = false
	waiting_for_user = false
	$TalkingIndicator/Talking.show()
	$TalkingIndicator/Continue.hide()
	eof=false
	reading_header=true

func _ready():
	read_out_tbf()

func playsoundeffect(name):
	$SFX.stream=DB.sfx[name]
	$SFX.play()

func type(t):
	if !reading_header:
		$Text.append_bbcode(t)

func typeescape(t):
	if escape:
		type(t)
		escape = false
		return false
	return true

func clear():
	$Text.clear()

func look_for_sequence(name):
	return tb.find("[seq "+name+"]")

func jump_to_sequence(name):
	var n = look_for_sequence(name)
	charn=n

func set_text_color(c):
	type("[color="+c+"]")

func return_with_stack():
	if len(stack)>0:
		charn=stack.pop_back()
	else:
		eof=true

func talk_sound():
	if !$Talking.playing:
		$Talking.play()

func set_talk_sound(name):
	$Talking.stream=DB.sfx[name]

func wait(seconds):
	waittimer=0
	waitlength=seconds

func execute_command():
	if cmd[0]=="meta":
		if cmd[1]=="startsequence":
			if reading_header:
				jump_to_sequence(cmd[2])
				reading_header=false
	if cmd[0]=="text":
		if cmd[1]=="speed":
			nelength = float(cmd[2])
		if cmd[1]=="color":
			set_text_color(cmd[2])
	if cmd[0]=="sfx":
		playsoundeffect(cmd[1])
	if cmd[0]=="jmp":
		jump_to_sequence(cmd[1])
	if cmd[0]=="jsr":
		stack.append(charn)
		jump_to_sequence(cmd[1])
	if cmd[0]=="end":
		return_with_stack()
	if cmd[0]=="p":
		waiting_for_user = true
	if cmd[0]=="talk":
		if cmd[1]=="sound":
			set_talk_sound(cmd[2])
	if cmd[0]=="continue":
		clear()
	if cmd[0]=="wait":
		wait(float(cmd[1]))


func parse_tb(t):
	if t == "\n":
		escape=false
		comment=false
		if !skip_next_newline:
			type(t)
		skip_next_newline = false
	elif comment:
		return false
	elif t=="\\":
		if typeescape(t):
			escape = true
			return false
	elif command:
		if t == " ":
			cmd.append("")
		elif t == "]":
			execute_command()
			command=false
			comment=true
			skip_next_newline = true
		else:
			cmd[-1]+=t
		return false
	elif t=="[":
		command = true
		cmd = [""]
	elif t=="#":
		if typeescape(t):
			comment = true
			if previous_char=="\n" or previous_char=="":
				skip_next_newline = true
			return false
	else:
		type(t)
		return true

func _process(delta):
	if Input.is_action_just_pressed("debug-reload"):
		read_out_tbf()
	if waiting_for_user or eof:
		$TalkingIndicator/Talking.hide()
		$TalkingIndicator/Continue.show()
		if Input.is_action_just_pressed("proceed"):
			waiting_for_user=false
			$TalkingIndicator/Talking.show()
			$TalkingIndicator/Continue.hide()
			$Continue.play()
			clear()
	else:
		netimer += delta
		if waittimer < waitlength:
			waittimer+=delta
	while netimer >= nelength and waittimer >= waitlength:
		if waittimer >= waitlength:
			if waitlength!=0:
				waittimer=0
				waitlength=0
				netimer=0
				break
		if charn>=len(tb) or eof or waiting_for_user:
			break
		var ch = tb[charn]
		var p = parse_tb(ch)
		previous_char = ch
		charn+=1
		if p:
			netimer -= nelength
			talk_sound()
