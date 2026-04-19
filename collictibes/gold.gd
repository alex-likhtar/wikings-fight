extends Area2D

func _on_body_entered(body):
	# Проверяем, что вошедший объект принадлежит к группе игрока [cite: 56]
	if body.is_in_group("player"):
		var tween = get_tree().create_tween()
		var tween1 = get_tree().create_tween()
		# Анимация взлета и исчезновения [cite: 56]
		tween.tween_property(self , "position", position - Vector2(0, 25), 0.3)
		tween1.tween_property(self , "modulate:a", 0, 0.3)
		# Удаляем монету после анимации [cite: 56]
		tween.tween_callback(queue_free)
		# Добавляем золото в переменную игрока [cite: 29, 56]
		if "gold" in body:
			body.gold += 1
