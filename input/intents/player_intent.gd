class_name PlayerIntent
extends RefCounted
## Base class for device-independent player commands.
##
## Input schemes turn raw device input into intents; gameplay (the
## PlayerController) only ever sees intents, never devices.
