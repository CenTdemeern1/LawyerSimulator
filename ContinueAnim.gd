extends AnimatedSprite

var t = 0
var tw = false

func _ready():
	playing = true
	tw = get_child_count()!=0
	if tw:
		$Continue2.playing = true

func _process(delta):
	t+=delta
	t=fmod(t,1)
	var x=sin(t*PI*2)
	var y=0.75+(0.25*x)
	self.scale.x=4/y
	self.scale.y=4*y
	speed_scale = 2-x
	if tw:
		$Continue2.speed_scale=2-x
