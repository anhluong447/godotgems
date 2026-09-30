class_name PartyState
extends State
## Base for party member states: typed access to the member.

var member: PartyMember:
	get:
		return actor as PartyMember
