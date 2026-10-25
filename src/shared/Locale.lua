local Locale = {}
local text = {
	cart_waiting = {
		"Тележка ждёт перед гаражом. Подойди к ней, чтобы повести за собой.",
		"Your cart is outside the garage. Approach it to start pulling it.",
	},
	spawn_blocked = {
		"Освободи площадку перед гаражом для транспорта.",
		"Clear the parking area in front of your garage.",
	},
	vehicle_stopped = {
		"Тележка остановилась. Подойди к ней и восстанови положение (⚙); пустую можно отозвать.",
		"The cart stopped. Approach it and reset it (⚙), or recall it if empty.",
	},
	display = { "Выставить / убрать с подиума", "Display / remove from plinth" },
	display_full = {
		"Все три подиума заняты. Сначала убери один экспонат.",
		"All three plinths are occupied. Remove a displayed item first.",
	},
	alpha = {
		"ЗАКРЫТАЯ АЛЬФА • 10 НАХОДОК + 2 ПРОЕКТА",
		"CLOSED ALPHA • 10 FINDS + 2 PROJECTS",
	},
	garage = {
		"Проекты и оформление — у верстака",
		"Projects & themes — at your workbench",
	},
	equipment = { "Оборудование", "Equipment" },
	queue = { "Очередь подготовки", "Preparation queue" },
	queueAdd = { "Подготовить к ремонту", "Add to preparation queue" },
	queued = { "В очереди", "Queued" },
	queue_full = {
		"Очередь заполнена. Заверши ремонт или улучши верстак.",
		"Queue full. Complete a repair or upgrade your workbench.",
	},
	already_queued = { "Предмет уже подготовлен.", "This item is already queued." },
	install = { "Установить как оборудование", "Install as equipment" },
	cart = { "Тележка", "Cart" },
	buggy = { "Багги", "Buggy" },
	build = { "Собрать", "Build" },
	spawn = { "Вызвать", "Spawn" },
	recall = { "Отозвать пустой транспорт", "Recall empty vehicle" },
	resetVehicle = { "Восстановить положение • 10 с", "Reset vehicle • 10 s" },
	theme = { "Тема гаража", "Garage theme" },
	paint = { "Расцветка техники", "Vehicle paint" },
	default = { "Классика", "Classic" },
	mint = { "Мятная", "Mint" },
	rust = { "Ретро", "Rust & copper" },
	workshop = { "Мастерская", "Workshop" },
	observatory = { "Обсерватория", "Observatory" },
	plum = { "Сливовая", "Plum" },
	cream = { "Кремовая", "Cream" },
	order_lamps = { "Заказ: 3 исправные лампы", "Order: 3 restored lamps" },
	order_radiofan = {
		"Заказ: исправные радио и вентилятор",
		"Order: restored radio + fan",
	},
	order_generator = { "Заказ: исправный генератор", "Order: restored generator" },
	order_cooldown = {
		"Заказ ещё восстанавливается.",
		"This order is still on cooldown.",
	},
	order_missing = {
		"Не хватает исправных предметов для заказа.",
		"You need all restored items for this order.",
	},
	pass_decor = { "Набор оформления", "Garage furniture pack" },
	pass_paint = { "Расцветки техники", "Vehicle colors" },
	pass_storage = { "+24 места склада", "+24 storage slots" },
	loadingPrice = { "Цена загружается", "Loading price" },
	purchase_pending = {
		"Заверши или закрой окно покупки.",
		"Complete or close the purchase prompt.",
	},
	day = { "ДЕНЬ — ДО НОЧИ", "DAY — NIGHT IN" },
	night = { "НОЧЬ — ДО РАССВЕТА", "NIGHT — DAWN IN" },
	nightTaskHint = {
		"Вылазка: два фонаря на центральной дороге → свой гараж",
		"Night task: two beacons on the main road → your garage",
	},
	night_wait = {
		"Приходи ночью, когда до рассвета осталось не меньше 90 секунд.",
		"Come at night with at least 90 seconds left before dawn.",
	},
	captured = {
		"Смотритель вернул тебя в гараж. Недоставленный груз потерян.",
		"The caretaker returned you home. Undelivered cargo was lost.",
	},
	needs_radio = {
		"Сначала установи исправное радио на верстаке.",
		"First install a restored radio at your workbench.",
	},
	needs_robot = {
		"Сначала установи исправного робота на верстаке.",
		"First install a restored robot at your workbench.",
	},
	needs_tools = {
		"Для багги нужны инструменты из магазина.",
		"Buy tools at the shop before building a buggy.",
	},
	needs_buggy = {
		"Заказы откроются после сборки багги.",
		"Orders unlock after building a buggy.",
	},
	robot_busy = {
		"Робот занят или перезаряжается (30 с).",
		"Robot is busy or recharging (30 s).",
	},
	signal_found = {
		"Сигнал найден! Ищи золотистый луч (8 с).",
		"Signal found! Look for the amber beam (8 s).",
	},
	signal_none = {
		"В пределах 60 studs новых тайников нет.",
		"No unclaimed caches within 60 studs.",
	},
	already_claimed = { "Эта награда уже получена.", "You already claimed this reward." },
	no_vehicle = { "Транспорт ещё не вызван.", "No active vehicle." },
	recall_first = {
		"Сначала отзови предыдущий транспорт.",
		"Recall your current vehicle first.",
	},
	vehicle_busy = {
		"Разгрузи транспорт и выйди из него перед отзывом.",
		"Unload and leave the vehicle before recalling it.",
	},
	bring_vehicle = {
		"Подвези груз к зоне сдачи.",
		"Bring the loaded vehicle to the unloading zone.",
	},
	not_available = { "Сейчас недоступно.", "Currently unavailable." },
	invalid_action = {
		"Действие сейчас недоступно.",
		"This action is unavailable right now.",
	},
	invalid_repair = {
		"Выбери текущий ремонтируемый предмет.",
		"Select the item currently being repaired.",
	},
	already_issued = {
		"Учебный предмет уже выдан.",
		"This training item was already issued.",
	},
	q7 = {
		"07  Ночная вылазка: начни у первого фонаря, дойди до второго и вернись к зоне сдачи. Остальные задания доступны.",
		"07  Start at the first beacon at night, visit the second, then unload at home. Other tasks remain available.",
	},
	q8 = {
		"08  Восстанови учебные радио и робота на верстаке. Найди тайник (◎) и включи роботом переключатель. Ночная вылазка доступна отдельно.",
		"08  Restore your training radio and robot. Scan (◎), claim a cache, and activate a robot switch. The night task is optional alongside this.",
	},
	q9 = {
		"09  Купи инструменты и собери багги (⚙). Продолжай ночную вылазку, когда удобно.",
		"09  Buy tools and build a buggy (⚙). Complete your night outing when convenient.",
	},
	q10 = {
		"Обучение завершено! Собери каталог, открой короткие пути и выполняй заказы. Ночь: бег и багги привлекают смотрителя.",
		"Training complete! Fill your collection, open shortcuts, and fulfill orders. Running and buggy noise attract the caretaker at night.",
	},
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
		"06  Накопи 450 монет и 4 детали. Собери тележку у верстака (⚙) и сдай три находки за раз. Вылазка ночью доступна отдельно.",
		"06  Save 450 coins + 4 parts. Build a cart at your workbench (⚙), then deliver three finds together. The night outing is also available.",
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
