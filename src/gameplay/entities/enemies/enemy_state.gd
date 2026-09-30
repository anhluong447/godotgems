class_name EnemyState
extends State
## Base for enemy states: typed access to the enemy.

var enemy: Enemy:
	get:
		return actor as Enemy
