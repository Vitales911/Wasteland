extends Node
## Автозагрузка "Perks": база данных 30 перков (шкала каждого 0..100).

const CATEGORIES := {
	"weapon": "Оружие",
	"survival": "Выживание",
	"work": "Работа",
	"other": "Прочее",
}

const LIST := [
	# --- Оружие (7) ---
	{"id": "unarmed", "name": "Без оружия", "cat": "weapon", "desc": "Рукопашный бой, удары, блоки, броски."},
	{"id": "melee", "name": "Ближний бой", "cat": "weapon", "desc": "Дубины, ножи, топоры, копья."},
	{"id": "thrown", "name": "Метательное оружие", "cat": "weapon", "desc": "Ножи, топорики, дротики, гранаты."},
	{"id": "ranged", "name": "Лук и арбалет", "cat": "weapon", "desc": "Тихое дальнобойное оружие."},
	{"id": "automatic", "name": "Автоматическое оружие", "cat": "weapon", "desc": "Автоматы, пистолеты-пулемёты."},
	{"id": "shotgun", "name": "Гладкоствольное оружие", "cat": "weapon", "desc": "Дробовики и обрезы."},
	{"id": "heavy", "name": "Тяжёлое оружие", "cat": "weapon", "desc": "Пулемёты, гранатомёты, самоделки."},
	# --- Выживание (7) ---
	{"id": "first_aid", "name": "Первая помощь", "cat": "survival", "desc": "Бинты, шины, лечение ран."},
	{"id": "foraging", "name": "Собирательство", "cat": "survival", "desc": "Ягоды, грибы, коренья, чистая вода."},
	{"id": "hunting", "name": "Охота и разделка", "cat": "survival", "desc": "Выслеживание и разделка добычи."},
	{"id": "campcraft", "name": "Костёр и укрытие", "cat": "survival", "desc": "Огонь, ночлег, защита от непогоды."},
	{"id": "stealth", "name": "Скрытность", "cat": "survival", "desc": "Тихое передвижение, маскировка."},
	{"id": "navigation", "name": "Ориентирование", "cat": "survival", "desc": "Карты, компас, звёзды."},
	{"id": "rad_resist", "name": "Стойкость к радиации", "cat": "survival", "desc": "Снижает урон от заражённых зон."},
	# --- Работа (7) ---
	{"id": "lumberjack", "name": "Лесоруб", "cat": "work", "desc": "Рубка деревьев, больше дерева за удар."},
	{"id": "mining", "name": "Горное дело", "cat": "work", "desc": "Добыча камня и руды."},
	{"id": "carpentry", "name": "Столярное дело", "cat": "work", "desc": "Копья, постройки, мебель."},
	{"id": "smithing", "name": "Кузнечное дело", "cat": "work", "desc": "Ковка и заточка металла."},
	{"id": "cooking", "name": "Кулинария", "cat": "work", "desc": "Готовка пайков и консервация."},
	{"id": "mechanics", "name": "Ремонт и механика", "cat": "work", "desc": "Починка техники и механизмов."},
	{"id": "electrics", "name": "Электрика", "cat": "work", "desc": "Проводка, генераторы, аккумуляторы."},
	# --- Прочее (9) ---
	{"id": "literacy", "name": "Грамотность", "cat": "other", "desc": "Ускоряет обучение любому перку."},
	{"id": "trade", "name": "Торговля", "cat": "other", "desc": "Выгодный обмен и торг."},
	{"id": "teaching", "name": "Преподавание", "cat": "other", "desc": "Учеников учишь эффективнее."},
	{"id": "driving", "name": "Вождение", "cat": "other", "desc": "Машины, мотоциклы, телеги."},
	{"id": "lockpick", "name": "Взлом замков", "cat": "other", "desc": "Отмычки, сейфы, двери."},
	{"id": "scavenging", "name": "Поиск лута", "cat": "other", "desc": "Находить ценное в руинах."},
	{"id": "chemistry", "name": "Химия", "cat": "other", "desc": "Лекарства, фильтры, топливо."},
	{"id": "farming", "name": "Земледелие", "cat": "other", "desc": "Огороды, семена, урожай."},
	{"id": "radio", "name": "Радиосвязь", "cat": "other", "desc": "Рации, приём сигналов выживших."},
]

var by_id := {}

func _ready() -> void:
	for p in LIST:
		var id: String = p.id
		by_id[id] = p

func name_of(id: String) -> String:
	return by_id[id].name
