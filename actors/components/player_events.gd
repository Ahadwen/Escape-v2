class_name PlayerEvents
extends Node
## Gameplay events about the player that card effects react to (beyond the
## signals on health and abilities themselves).

signal crystal_used
signal ace_used(card: CardData)
signal level_started
signal safehouse_entered
signal card_picked_up(card: CardData)
