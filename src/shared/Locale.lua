local Locale = {}
local text = {
	title = { "ГАРАЖ НАХОДОК", "STRANGE FINDS GARAGE" },
	subtitle = {
		"ДАЙ ЗАБЫТЫМ ВЕЩАМ ВТОРОЙ ШАНС",
		"GIVE FORGOTTEN THINGS A SECOND CHANCE",
	},
	coins = { "МОНЕТЫ", "COINS" },
	parts = { "ДЕТАЛИ", "PARTS" },
	storage = { "СКЛАД", "STORAGE" },
	workbench = { "Верстак", "Workbench" },
	shop = { "Магазин", "Shop" },
	catalog = { "Коллекция", "Collection" },
	close = { "Закрыть", "Close" },
	empty = {
		"Пока пусто. Найди контейнер на острове и сдай груз у своего гаража.",
		"Nothing here yet. Search a container, then unload at your garage.",
	},
	select = { "Выбрать", "Select" },
	clean = { "Очистить", "Clean" },
	replace = { "Заменить деталь", "Replace part" },
	power = { "Проверить питание", "Test power" },
	finish = { "Завершить действие", "Complete action" },
	sell = { "Продать", "Sell" },
	dismantle = { "Разобрать", "Dismantle" },
	advance = {
		"Завершить задание / получить предмет",
		"Complete task / receive item",
	},
	buyPart = { "Купить деталь • 10", "Buy part • 10" },
	storageUpgrade = { "Расширить склад", "Expand storage" },
	benchUpgrade = { "Улучшить верстак", "Upgrade workbench" },
	toolsUpgrade = { "Инструменты • 250", "Tools • 250" },
	cargo = { "ГРУЗ", "CARGO" },
	unload = { "Сдать груз", "Unload cargo" },
	prototype = { "ПРОТОТИП • 4 ПРЕДМЕТА", "PROTOTYPE • 4 FINDS" },
	mock = {
		"Studio: тестовые данные не сохраняются между запусками",
		"Studio: test data resets between play sessions",
	},
	critical = {
		"Сохранение временно недоступно. Изменения прогресса приостановлены.",
		"Saving is temporarily unavailable. Progress changes are paused.",
	},
	too_far = {
		"Подойди ближе к своему верстаку, магазину или зоне сдачи.",
		"Move closer to your workbench, shop, or unloading zone.",
	},
	cargo_full = {
		"Руки заняты. Сначала сдай груз в гараже.",
		"Your hands are full. Unload at your garage first.",
	},
	storage_full = {
		"Склад заполнен. Продай или разбери предмет.",
		"Storage is full. Sell or dismantle an item.",
	},
	not_enough_parts = {
		"Не хватает деталей. Купи их в магазине или разбери находку.",
		"Not enough parts. Buy some or dismantle a find.",
	},
	not_enough_coins = { "Не хватает монет.", "Not enough coins." },
	quest_not_ready = {
		"Сначала выполни текущее задание.",
		"Complete the current task first.",
	},
	tutorial_restore_first = {
		"Этот учебный предмет сначала нужно восстановить.",
		"Restore this training item first.",
	},
	too_soon = { "Действие ещё выполняется.", "The action is still in progress." },
	repair_busy = {
		"Сначала закончи текущий ремонт.",
		"Finish your current repair first.",
	},
	invalid_item = {
		"Этот предмет сейчас недоступен для действия.",
		"This item is not available for that action.",
	},
	no_cargo = { "Груза нет.", "No cargo to unload." },
	deposited = { "Находка доставлена в гараж!", "Find delivered to your garage!" },
	already_owned = {
		"Уже приобретено или достигнут максимум.",
		"Already owned or at maximum level.",
	},
	save_unavailable = {
		"Дождись восстановления сохранений.",
		"Please wait for saving to recover.",
	},
	profile_unavailable = {
		"Прогресс ещё загружается.",
		"Your progress is still loading.",
	},
	toycar = { "Игрушечная машинка", "Toy car" },
	lamp = { "Настольная лампа", "Desk lamp" },
	fan = { "Вентилятор", "Fan" },
	radio = { "Радиоприёмник", "Radio" },
	train = { "Игрушечный поезд", "Toy train" },
	battery = { "Аккумулятор", "Battery" },
	robot = { "Игрушечный робот", "Toy robot" },
	helicopter = { "Вертолёт", "Toy helicopter" },
	generator = { "Генератор", "Generator" },
	meter = { "Измерительный прибор", "Meter" },
	q1 = {
		"01  Найди личный контейнер перед гаражом. Сдай машинку и восстанови её на верстаке.",
		"01  Search your personal container outside the garage. Unload and restore the toy car.",
	},
	q2 = {
		"02  Получи лампу кнопкой задания на верстаке. Восстанови и продай её.",
		"02  Receive the lamp using the task button. Restore and sell it.",
	},
	q3 = {
		"03  Разбери учебный вентилятор. Разборка даёт детали, но не запись в каталоге.",
		"03  Dismantle the training fan. Dismantling gives parts, not a collection entry.",
	},
	q4 = {
		"04  Купи одну деталь. На верстаке получи второй вентилятор и восстанови его.",
		"04  Buy one part. Receive a second fan at the workbench and restore it.",
	},
	q5 = {
		"05  Получи радио и восстанови его. Зарегистрируй машинку, лампу, вентилятор и радио.",
		"05  Receive and restore the radio. Register the car, lamp, fan, and radio.",
	},
	q6 = {
		"Прототип пройден! Исследуй маршрут, собирай находки и проверь удобство ремонта. Следующий этап — ночь и транспорт.",
		"Prototype complete! Explore, collect, and check how repair feels. Night and transport are the next milestone.",
	},
	loading = { "Загружаем твой гараж…", "Loading your garage…" },
}

function Locale.get(key, language)
	local pair = text[key]
	if pair then
		return pair[language == "ru" and 1 or 2]
	end
	if string.sub(key, 1, 6) == "found_" then
		return (language == "ru" and "Найдено: " or "Found: ")
			.. Locale.get(string.sub(key, 7), language)
	end
	return key
end

return Locale
