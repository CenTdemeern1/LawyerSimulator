extends AnimatedSprite

var t = 0

func _process(delta):
	t+=delta
	t=fmod(t,1)
	var x=sin(t*PI*2)
	var y=0.75+(0.25*x)
	self.scale.x=4/y
	self.scale.y=4*y
	speed_scale = 2-x
