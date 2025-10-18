extends Node2D

@export var speed: float = 60.0        # pixels/sec upward
@export var segment_height: int = 512  # set this to your background chunk height in px

@onready var seg_a: Node2D = $SegmentA
@onready var seg_b: Node2D = $SegmentB

var offset: float = 0.0

func _ready() -> void:
	# Place B directly below A
	seg_b.position.y = seg_a.position.y + float(segment_height)

func _process(dt: float) -> void:
	offset -= speed * dt
	if offset <= -float(segment_height):
		offset += float(segment_height)
	# Move both segments
	seg_a.position.y = offset
	seg_b.position.y = offset + float(segment_height)
