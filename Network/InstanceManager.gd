extends Node

class_name InstanceManager

var server_manager: Node
var logger: Node

# --------------------------------------------------
# SETUP
# --------------------------------------------------
func setup(sm: Node, logger_ref: Node):
	server_manager = sm
	logger = logger_ref
