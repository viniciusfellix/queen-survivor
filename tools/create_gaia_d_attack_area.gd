@tool
extends EditorScript

func _run() -> void:
	var folder_path: String = "res://resources/combat/attack_areas"
	var save_path: String = folder_path + "/attack_area_gaia_initial_d.tres"

	var dir_error: Error = DirAccess.make_dir_recursive_absolute(folder_path)

	if dir_error != OK:
		push_error("Falha ao criar pasta: %s | Erro: %s" % [
			folder_path,
			str(dir_error)
		])
		return

	var attack_area: AttackAreaDefinition = AttackAreaDefinition.new()

	attack_area.id = "attack_area_gaia_initial_d"
	attack_area.enabled = true
	attack_area.local_offset = Vector2(160.0, 0.0)
	attack_area.local_rotation_degrees = 0.0

	attack_area.shape = CombatShapeDefinition.create_d_shape(
		240.0,
		300.0,
		24
	)

	var save_error: Error = ResourceSaver.save(attack_area, save_path)

	if save_error != OK:
		push_error("Falha ao salvar AttackAreaDefinition em: %s | Erro: %s" % [
			save_path,
			str(save_error)
		])
		return

	print("AttackAreaDefinition em D criado com sucesso: %s" % save_path)
