# QA: расширенная альфа v4

25 октября 2026. Роль qa_tester. Проверенная версия: `qa-manifest.txt`, SHA256
`2929C4FBFBBDD7F861CBD50A44D0CFA3F16799E6DAF724FE9A4D8F56745B9960`.
Хеши перечисленных исходников после прогона совпали. Исходники, конфигурация
и фикстуры не менялись.

## Окружение и результаты

Studio, место `115227968642980`, одиночный Play с Client/Server, Studio Mock.
Применялись действующие remotes, ProximityPrompt через E, навигация персонажа
и существующий Studio-only GarageTestDriver. **59 TestEZ passed, 0 failed,
0 skipped.** Существенных новых дефектов в проверенных сценариях не подтверждено.

| Сценарий и шаги | Ожидаемое и фактическое | Результат |
|---|---|---|
| TestEZ на Server | Непустой запуск 59/0/0; экономика, все 10 типов, обучение, миграции, атомарность, сессии, cargo, guard, limiter, NightBrain | passed |
| 7 неверных Request: extra coins, nested id, id 65 символов, missing key, boolean как число, неизвестный action, лишний id у Deposit | До/после: 50 монет, 8 деталей, 0 items | passed |
| E у личной машинки | Один cargo, capacity 1, CarriedFind видим | passed |
| Deposit дважды у своего гаража | Ровно 1 item, cargo 0, CarriedFind исчез; повтор no_cargo | passed |
| Три этапа ремонта машинки с реальными таймерами по 5 с, ранний Finish на каждом этапе | Ранние Finish отклонены; затем стадии 1/2/3, toycar зарегистрирована, детали 7 | passed |
| Sell и повтор Sell | 85 монет, 0 items; повтор invalid_item, двойной награды нет | passed |
| P2: обычное исправное и bound радио через Mock-фикстуру; BeginRepair(bound), Install(ordinary) | repair_busy; ordinary, bound, repair.id и 8 деталей сохранены | passed |
| Завершить первый этап bound ремонта, затем Install ordinary | Repair освобождён, radio=true, ordinary расходуется один раз | passed |
| Critical=true, BuyPart у магазина | save_unavailable; 85 монет / 8 деталей неизменны; постоянное предупреждение видно | passed |
| Critical=false, повтор BuyPart | 75 монет / 9 деталей, предупреждение снято | passed |
| Тележка: вызвать, подойти, пройти | Ожидает владельца, затем следует; дистанция 5.27 studs | passed |
| Столкновение тележки и Reset | Остановка у TreeTrunk; Reset рядом возобновил движение, издалека too_far | passed |
| Подбор вдали от cart, затем подход к ней | Ручной cargo остаётся capacity 1, сдача успешна | passed |
| Подбор обычной находки рядом с cart | cargo 1, capacity 3, ручная визуальная переноска отсутствует | passed |
| Тестовый teleport к депо без cart, Deposit | bring_vehicle, cargo 1 сохранён | passed |
| Вернуться к cart, Reset, довести к депо, Deposit дважды | Cart в 12.47 studs; ровно +1 item, cargo 0, повтор no_cargo | passed |
| NightBrain: слух, потеря видимости, давность/дальность, смена цели | 6 соответствующих TestEZ passed; поиск завершается через 8 с от последнего шума | passed — unit |
| Runtime SessionEnd, ожидание 6 с | Server players=0; Output содержит Server Kick Message с предложением войти снова | passed |

Транспорт разблокирован через Mock-фикстуру: это не замер времени заработка.
Контейнеры, награды и серверные проверки не перемещались и не обходились.
Телепорт персонажа использовался только для негативного теста отсутствующего
транспорта и возврата к нему. Положительная сдача — после доставки тележки.

## Интерфейс

Samsung Galaxy A16 preset 780×360, LandscapeLeft, viewport **685×338**.
Игра LandscapeSensor, HUD DeviceSafeInsets. Эмулятор не является POCO X4 5G.

| Сценарий | Фактическое | Результат |
|---|---|---|
| RU HUD | Статистика, задача, таймер, кнопки видны без обрезки | passed — visual |
| RU/EN Workbench | Заголовки, предметы, кнопки читаемы; окно вмещается | passed — visual |
| Модальное окно | TouchGui.Enabled=false, HUD скрыт | passed |
| Прокрутка | Canvas 270 px > окно 239.2 px; CanvasPosition=30.8, нижняя строка достижима | passed — programmatic + visual |
| Зоны кнопок | Client сообщил 48×48 у закрытия/выбора, высоту 52 у задания | passed — logical viewport units |
| Закрытие через MCP mouse по instance_path | Tool Success, panel остаётся открытой; восстановление TouchGui обычным нажатием не подтверждено | blocked — повторить обычным touch/мышью |

Снимки инструмента: QA_Mobile_RU_HUD_Actual, QA_Mobile_RU_Workbench,
QA_Mobile_EN_Workbench, QA_Mobile_EN_Scrolled, QA_SessionEnded_AfterWait.
Локальных файлов screen_capture не вернул. Kick подтверждён сервером и Output;
последний клиентский кадр после отключения не использован как доказательство.

## Output и ограничения

- ProfileStore предупредил об отключённом Studio API Access. Это ожидаемо
  для Mock; настройки настоящих данных не менялись.
- Присутствует rbxassetid://203785492: Asset type does not match requested type.
  ID не найден в src/tests/проектных JSON; источник не установлен. Не объявлено
  исправленным или доказанно безвредным.
- Два AssistantCommand сообщения относятся к моей диагностике: cart claim failed
  при неверном setup (cart была в 30 studs, cargo оказался ручным), и Blockcast
  с нулевым направлением после достижения цели. Исправленный сценарий затем прошёл.
  Игровых stack trace из Main/Expansion/Vehicles/Night не было.
- Тележка часто останавливается у углов декора/деревьев черновой карты.
  Reset работает; удобство маршрутов следует проверить с людьми.
- Свежий runtime повтор всего обучения 1–5, багги, радио/тайников, робота,
  смерти с грузом, поимки и emitted noise здесь не выполнялся. Часть покрыта unit;
  прежние игровые результаты остаются отдельным baseline.
- Шесть клиентов текущей версии проверяет координатор отдельно. Прежние 48 тестов
  и six-client baseline не засчитаны за текущий прогон.
- Реальные DataStore, покупки, шесть людей по сети, баланс 90–150 минут до багги
  и 5–7 часов до покупок, FPS/память POCO — blocked до закрытого теста.
  Данные телефона от пользователя: 8 GB LPDDR4x, Android 11 / MIUI 13;
  это описание устройства, а не измерение.

Конечное состояние: **Studio Edit, Device Simulator default / выключен**.
Слот возвращён координатору. Mock-изменения остановлены вместе с Play.
