extends Ability

# const grappleMaterial := preload("./GrapplePlaceholderMaterial.tres")
const grappleProgressCurve := preload("./GrappleProgressCurve.tres")
@onready var pathNode: Path3D = $GrapplePath

var lookedAtNode: GrappleableObject = null
var grappledNode: GrappleableObject = null
var isGrappling: bool = false

const grappleReachSpeed: float = 3.0
var grappleReachProgress: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	initGrapple()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if isGrappling:
		var wandPos = cameraNode.to_global(Vector3(0.794, 0.189, -0.584))
		var startPoint = wandPos
		var endPoint = grappledNode.global_transform.origin
		var dist = grappleProgressCurve.sample(grappleReachProgress)
		pathNode.curve.set_point_position(0, startPoint)
		pathNode.curve.set_point_position(1, startPoint.lerp(endPoint,dist))

func _physics_process(delta):
	if isGrappling:
		updateGrapple(delta)
	else:
		checkLookedAtNode()


func checkLookedAtNode():
	if rayCastNode and rayCastNode.is_colliding():
		var collidedNode = rayCastNode.get_collider()
		if collidedNode is GrappleableObject:
			if lookedAtNode != null: lookedAtNode.on_look_away()
			lookedAtNode = collidedNode
			lookedAtNode.on_look_at()
	else:
		if lookedAtNode != null:
			lookedAtNode.on_look_away()
			lookedAtNode = null

func initGrapple():
	pathNode.curve = Curve3D.new()
	pathNode.curve.add_point(Vector3(0, -100, 0))
	pathNode.curve.add_point(Vector3(0, -100, 0))

func startGrapple():
	if lookedAtNode != null and not isGrappling:
		setGemColor(Color(1,0,0))
		grappledNode = lookedAtNode
		isGrappling = true
		grappleReachProgress = 0.0

func endGrapple():
	if lookedAtNode != null and isGrappling:
		resetGemColor()
		pathNode.curve.set_point_position(0, Vector3(0, -100, 0))
		pathNode.curve.set_point_position(1, Vector3(0, -100, 0))
		isGrappling = false
		grappleReachProgress = 0.0

func updateGrapple(delta):
	if isGrappling:
		if grappleReachProgress >= 1.0:
			grappleReachProgress = 1.0
			
			# apply player physics
			var offset = (grappledNode.global_transform.origin - playerNode.global_transform.origin)
			var direction = offset.normalized()
			var strength = clampf(offset.length() - 3, 0, 20)

			playerNode.velocity += direction * strength * 20 * delta
			playerNode.velocity += Vector3(0, -5, 0) * delta # reduce gravity
		else:
			grappleReachProgress += delta * grappleReachSpeed;
