var defender_stats
var attacker_stats

func resolve_fight(attacker, defender):
	attacker_stats = attacker.get_stats()
	defender_stats = defender.get_stats()
		
	defender_stats.life = defender_stats.life - attacker_stats.attack
	defender.set_stats(defender_stats)
	defender.show_floating_damage(attacker_stats.attack)
	
	attacker_stats.ap = attacker_stats.ap - attacker_stats.attack_ap
	attacker_stats.attacks_number = attacker_stats.attacks_number - 1
	attacker.set_stats(attacker_stats)
	
	#handle
	if (defender_stats.life <= 0):
		attacker.score_kill()
		return true
	else:
		return false

func resolve_defend(attacker, defender):
	attacker_stats = attacker.get_stats()
	defender_stats = defender.get_stats()

	attacker_stats.life = attacker_stats.life - defender_stats.attack
	attacker.set_stats(attacker_stats)
	attacker.show_floating_damage(defender_stats.attack)
	
	defender_stats.ap = 0
	defender.set_stats(defender_stats)

	#handle
	if (attacker_stats.life <= 0):
		defender.score_kill()
		return true
	else:
		return false

func can_attack(attacker, defender):
	return attacker.can_attack_unit_type(defender) && attacker.can_attack()

func can_defend(defender, attacker):
	return defender.can_attack_unit_type(attacker) && defender.can_defend()
	