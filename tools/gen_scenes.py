#!/usr/bin/env python3
"""Генератор .tscn-сцен проекта (project.godot, объекты, мир, персонаж, HUD, main).
Запускать из корня проекта: python3 tools/gen_scenes.py
Результат — обычные сцены Godot: их можно открывать и править в редакторе."""
import math, random

MAP = 10000          # 1 км = 10000 px (1 м = 10 px)
random.seed(7)

def circle(r, n=14, cx=0.0, cy=0.0, jitter=0.0):
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        rr = r * (1 + random.uniform(-jitter, jitter))
        pts += [round(cx + rr * math.cos(a), 1), round(cy + rr * math.sin(a), 1)]
    return pts

def pv(pts):
    return "PackedVector2Array(" + ", ".join(str(p) for p in pts) + ")"

def col(r, g, b, a=1):
    return f"Color({r}, {g}, {b}, {a})"

def write(path, text):
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)

# ---------------- project.godot ----------------
def key(phys):
    return ('Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,'
            '"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,'
            '"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":%d,"key_label":0,'
            '"unicode":0,"location":0,"echo":false,"script":null)' % phys)

def action(*codes):
    return '{\n"deadzone": 0.5,\n"events": [' + ", ".join(key(c) for c in codes) + ']\n}'

W, A, S, D, E, N1, N2, N3 = 87, 65, 83, 68, 69, 49, 50, 51
SHIFT, TAB = 4194325, 4194306
write("project.godot", f'''; Engine configuration file.
config_version=5

[application]

config/name="Wasteland Survivors 2D"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.3")
config/icon="res://icon.svg"

[autoload]

Perks="*res://scripts/perks.gd"
Game="*res://scripts/game.gd"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"

[input]

move_up={action(W)}
move_down={action(S)}
move_left={action(A)}
move_right={action(D)}
sprint={action(SHIFT)}
interact={action(E)}
switch_1={action(N1)}
switch_2={action(N2)}
switch_3={action(N3)}
switch_next={action(TAB)}

[rendering]

environment/defaults/default_clear_color=Color(0.06, 0.06, 0.07, 1)
''')

write("icon.svg", '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="128" height="128" fill="#2b2d24"/><circle cx="64" cy="64" r="34" fill="#c8532f"/><circle cx="64" cy="64" r="14" fill="#2b2d24"/></svg>\n')

# ---------------- объекты: дерево, камень, куст, манекен, книга ----------------
write("scenes/tree.tscn", f'''[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/world_resource.gd" id="1"]

[sub_resource type="CircleShape2D" id="trunk"]
radius = 6.0

[node name="Tree" type="StaticBody2D" groups=["tree", "resource"]]
collision_layer = 1
collision_mask = 0
script = ExtResource("1")
kind = "tree"
amount = 6

[node name="Collision" type="CollisionShape2D" parent="."]
shape = SubResource("trunk")

[node name="Trunk" type="Polygon2D" parent="."]
color = {col(0.25, 0.17, 0.1)}
polygon = {pv(circle(6, 10))}

[node name="Canopy" type="Polygon2D" parent="."]
color = {col(0.2, 0.3, 0.16, 0.92)}
polygon = {pv(circle(34, 16, jitter=0.12))}

[node name="CanopyLight" type="Polygon2D" parent="."]
color = {col(0.3, 0.42, 0.2, 0.7)}
polygon = {pv(circle(18, 12, -6, -6))}
''')

rock_pts = circle(15, 7, jitter=0.25)
write("scenes/rock.tscn", f'''[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/world_resource.gd" id="1"]

[node name="Rock" type="StaticBody2D" groups=["rock", "resource"]]
collision_layer = 1
collision_mask = 0
script = ExtResource("1")
kind = "rock"
amount = 5

[node name="Collision" type="CollisionPolygon2D" parent="."]
polygon = {pv(rock_pts)}

[node name="Mesh" type="Polygon2D" parent="."]
color = {col(0.45, 0.45, 0.47)}
polygon = {pv(rock_pts)}

[node name="Highlight" type="Polygon2D" parent="."]
color = {col(0.6, 0.6, 0.62, 0.8)}
polygon = {pv(circle(6, 6, -3, -4))}
''')

berries = ""
for i, (bx, by) in enumerate([(-6, -4), (5, -6), (7, 4), (-3, 7), (0, 0)]):
    berries += f'''
[node name="Berry{i}" type="Polygon2D" parent="."]
color = {col(0.75, 0.12, 0.2)}
polygon = {pv(circle(2.2, 6, bx, by))}
'''
write("scenes/bush.tscn", f'''[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/world_resource.gd" id="1"]

[sub_resource type="CircleShape2D" id="bushshape"]
radius = 9.0

[node name="Bush" type="StaticBody2D" groups=["bush", "resource"]]
collision_layer = 1
collision_mask = 0
script = ExtResource("1")
kind = "bush"
amount = 4

[node name="Collision" type="CollisionShape2D" parent="."]
shape = SubResource("bushshape")

[node name="Mesh" type="Polygon2D" parent="."]
color = {col(0.22, 0.34, 0.15)}
polygon = {pv(circle(12, 12, jitter=0.2))}
{berries}''')

write("scenes/dummy.tscn", f'''[gd_scene format=3]

[sub_resource type="CircleShape2D" id="dshape"]
radius = 9.0

[node name="Dummy" type="StaticBody2D" groups=["dummy"]]
collision_layer = 1
collision_mask = 0

[node name="Collision" type="CollisionShape2D" parent="."]
shape = SubResource("dshape")

[node name="Post" type="Polygon2D" parent="."]
color = {col(0.5, 0.35, 0.2)}
polygon = {pv(circle(9, 12))}

[node name="Target" type="Polygon2D" parent="."]
color = {col(0.85, 0.8, 0.6)}
polygon = {pv(circle(6, 12))}

[node name="Bull" type="Polygon2D" parent="."]
color = {col(0.8, 0.15, 0.15)}
polygon = {pv(circle(2.5, 8))}
''')

write("scenes/book.tscn", f'''[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/book_pickup.gd" id="1"]

[sub_resource type="CircleShape2D" id="bookshape"]
radius = 12.0

[node name="Book" type="Area2D"]
collision_layer = 0
collision_mask = 2
script = ExtResource("1")

[node name="Collision" type="CollisionShape2D" parent="."]
shape = SubResource("bookshape")

[node name="Cover" type="Polygon2D" parent="."]
color = {col(0.75, 0.55, 0.15)}
polygon = {pv([-7, -9, 7, -9, 7, 9, -7, 9])}

[node name="Pages" type="Polygon2D" parent="."]
color = {col(0.93, 0.9, 0.78)}
polygon = {pv([-5, -7, 6, -7, 6, 7, -5, 7])}
''')

# ---------------- перк-строка HUD ----------------
write("scenes/perk_row.tscn", '''[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/perk_row.gd" id="1"]

[node name="PerkRow" type="HBoxContainer"]
layout_mode = 2
mouse_filter = 0
script = ExtResource("1")

[node name="NameLabel" type="Label" parent="."]
custom_minimum_size = Vector2(160, 0)
layout_mode = 2
text = "Перк"
clip_text = true

[node name="Bar" type="ProgressBar" parent="."]
custom_minimum_size = Vector2(80, 12)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 4
show_percentage = false

[node name="ValueLabel" type="Label" parent="."]
custom_minimum_size = Vector2(28, 0)
layout_mode = 2
text = "0"
horizontal_alignment = 2
''')

# ---------------- персонаж ----------------
write("scenes/character.tscn", f'''[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/character.gd" id="1"]
[ext_resource type="Script" path="res://scripts/character_stats.gd" id="2"]
[ext_resource type="Script" path="res://scripts/task_runner.gd" id="3"]

[sub_resource type="CircleShape2D" id="bodyshape"]
radius = 8.0

[node name="Survivor" type="CharacterBody2D"]
z_index = 1
collision_layer = 2
collision_mask = 1
motion_mode = 1
script = ExtResource("1")

[node name="Collision" type="CollisionShape2D" parent="."]
shape = SubResource("bodyshape")

[node name="ActiveRing" type="Polygon2D" parent="."]
visible = false
z_index = -1
color = {col(1, 0.9, 0.2, 0.55)}
polygon = {pv(circle(14, 18))}

[node name="Body" type="Polygon2D" parent="."]
color = {col(1, 1, 1)}
polygon = {pv(circle(9, 14))}

[node name="Pointer" type="Polygon2D" parent="Body"]
color = {col(0.1, 0.1, 0.1, 0.85)}
polygon = {pv([4, -3, 11, 0, 4, 3])}

[node name="NameLabel" type="Label" parent="."]
offset_left = -50.0
offset_top = -34.0
offset_right = 50.0
offset_bottom = -16.0
theme_override_font_sizes/font_size = 11
horizontal_alignment = 1
text = "Имя"

[node name="MapMarker" type="Polygon2D" parent="."]
visibility_layer = 2
z_index = 50
color = {col(1, 1, 1)}
polygon = {pv(circle(180, 12))}

[node name="Stats" type="Node" parent="."]
script = ExtResource("2")

[node name="TaskRunner" type="Node" parent="."]
script = ExtResource("3")
''')

# ---------------- мир ----------------
roads = {
    "Highway":   [(0, 5200), (2500, 5100), (5000, 5000), (7500, 5150), (10000, 5000)],
    "CrossRoad": [(5000, 0), (5050, 2500), (5000, 5000), (4900, 7500), (5100, 10000)],
    "DirtRoad":  [(2500, 5100), (2300, 6500), (1500, 8500), (1200, 10000)],
}
road_w = {"Highway": 70, "CrossRoad": 60, "DirtRoad": 40}
road_c = {"Highway": col(0.16, 0.16, 0.18), "CrossRoad": col(0.19, 0.19, 0.2), "DirtRoad": col(0.33, 0.27, 0.19)}

def seg_dist(p, a, b):
    ax, ay = a; bx, by = b; px, py = p
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))

def road_dist(p):
    return min(seg_dist(p, pts[i], pts[i + 1]) for pts in roads.values() for i in range(len(pts) - 1))

spawns = [(4650, 4750), (4800, 4650), (5350, 4700)]
placed = []
def spot(lo=3400, hi=6600, min_road=85, sep=90):
    while True:
        p = (random.randint(lo, hi), random.randint(lo, hi))
        if road_dist(p) < min_road: continue
        if any(math.hypot(p[0] - s[0], p[1] - s[1]) < 180 for s in spawns): continue
        if any(math.hypot(p[0] - q[0], p[1] - q[1]) < sep for q in placed): continue
        placed.append(p)
        return p

def points_str(pts):
    return pv([c for p in pts for c in p])

out = ['[gd_scene format=3]', '',
       '[ext_resource type="PackedScene" path="res://scenes/tree.tscn" id="1_tree"]',
       '[ext_resource type="PackedScene" path="res://scenes/rock.tscn" id="2_rock"]',
       '[ext_resource type="PackedScene" path="res://scenes/bush.tscn" id="3_bush"]',
       '[ext_resource type="PackedScene" path="res://scenes/book.tscn" id="4_book"]',
       '[ext_resource type="PackedScene" path="res://scenes/dummy.tscn" id="5_dummy"]', '',
       '[sub_resource type="RectangleShape2D" id="wall_h"]',
       f'size = Vector2({MAP + 400}, 100)', '',
       '[sub_resource type="RectangleShape2D" id="wall_v"]',
       f'size = Vector2(100, {MAP + 400})', '',
       '[node name="World" type="Node2D"]', '',
       '[node name="Ground" type="Polygon2D" parent="."]', 'z_index = -10',
       f'color = {col(0.33, 0.34, 0.25)}',
       f'polygon = {pv([0, 0, MAP, 0, MAP, MAP, 0, MAP])}', '',
       '[node name="Roads" type="Node2D" parent="."]', 'z_index = -5', '']
for name, pts in roads.items():
    out += [f'[node name="{name}" type="Line2D" parent="Roads"]',
            f'points = {points_str(pts)}', f'width = {float(road_w[name])}',
            f'default_color = {road_c[name]}', 'joint_mode = 2', 'antialiased = true', '']
    if name != "DirtRoad":
        out += [f'[node name="{name}Marking" type="Line2D" parent="Roads"]',
                f'points = {points_str(pts)}', 'width = 3.0',
                f'default_color = {col(0.62, 0.55, 0.28, 0.65)}', 'joint_mode = 2', 'antialiased = true', '']
# границы карты
out += ['[node name="Bounds" type="StaticBody2D" parent="."]', 'collision_layer = 1', 'collision_mask = 0', '']
for nm, shape, pos in [("Top", "wall_h", (MAP / 2, -50)), ("Bottom", "wall_h", (MAP / 2, MAP + 50)),
                       ("Left", "wall_v", (-50, MAP / 2)), ("Right", "wall_v", (MAP + 50, MAP / 2))]:
    out += [f'[node name="{nm}" type="CollisionShape2D" parent="Bounds"]',
            f'position = Vector2({pos[0]}, {pos[1]})', f'shape = SubResource("{shape}")', '']

def group(name, ext, count, prefix, scale=(1, 1), rot=False):
    out.extend([f'[node name="{name}" type="Node2D" parent="."]', ''])
    for i in range(count):
        x, y = spot()
        out.extend([f'[node name="{prefix}{i + 1:02d}" parent="{name}" instance=ExtResource("{ext}")]',
                    f'position = Vector2({x}, {y})'])
        s = round(random.uniform(*scale), 2)
        if s != 1: out.append(f'scale = Vector2({s}, {s})')
        if rot: out.append(f'rotation = {round(random.uniform(0, 6.28), 2)}')
        out.append('')

group("Trees", "1_tree", 45, "Tree", (0.8, 1.3))
group("Rocks", "2_rock", 18, "Rock", (0.8, 1.6), rot=True)
group("Bushes", "3_bush", 22, "Bush", (0.9, 1.3))

books = [("unarmed", 35, "Книга «Рукопашный бой для всех»"), ("melee", 40, "Книга «Клинок и копьё»"),
         ("first_aid", 40, "Справочник «Первая помощь»"), ("foraging", 30, "Журнал «Съедобные растения Пустоши»"),
         ("mechanics", 45, "Руководство «Ремонт своими руками»"), ("literacy", 30, "Букварь выживших"),
         ("carpentry", 35, "Журнал «Мастерская» №7")]
out += ['[node name="Books" type="Node2D" parent="."]', '']
for i, (perk, cap, title) in enumerate(books):
    x, y = spot(3300, 6700, 70, 120)
    out += [f'[node name="Book{i + 1:02d}" parent="Books" instance=ExtResource("4_book")]',
            f'position = Vector2({x}, {y})', f'perk_id = "{perk}"', f'cap = {float(cap)}', f'title = "{title}"', '']
out += ['[node name="Dummies" type="Node2D" parent="."]', '',
        '[node name="Dummy01" parent="Dummies" instance=ExtResource("5_dummy")]', 'position = Vector2(4950, 4850)', '',
        '[node name="Dummy02" parent="Dummies" instance=ExtResource("5_dummy")]', 'position = Vector2(5100, 4850)', '']
write("scenes/world.tscn", "\n".join(out))

# ---------------- HUD ----------------
nodes = []
def n(name, typ, parent=".", props="", unique=False, instance=None):
    head = f'[node name="{name}" type="{typ}" parent="{parent}"]'
    body = ("unique_name_in_owner = true\n" if unique else "") + props.strip("\n")
    nodes.append(head + "\n" + body + "\n")

def row(parent, title, prefix, color):
    n(f"{prefix}Row", "HBoxContainer", parent, "layout_mode = 2")
    p = f"{parent}/{prefix}Row"
    n(f"{prefix}Title", "Label", p, f'custom_minimum_size = Vector2(80, 0)\nlayout_mode = 2\ntext = "{title}"')
    n(f"{prefix}Bar", "ProgressBar", p, f'layout_mode = 2\nsize_flags_horizontal = 3\nsize_flags_vertical = 4\nmodulate = {color}\nshow_percentage = false', True)
    n(f"{prefix}Val", "Label", p, 'custom_minimum_size = Vector2(70, 0)\nlayout_mode = 2\ntext = "0"\nhorizontal_alignment = 2', True)

def btn(name, text, parent, extra=""):
    n(name, "Button", parent, f'layout_mode = 2\nfocus_mode = 0\ntext = "{text}"\n{extra}', True)

n("CharPanel", "PanelContainer", ".",
  'theme = SubResource("Theme_small")\nlayout_mode = 3\nanchors_preset = 0\noffset_left = 10.0\noffset_top = 10.0\noffset_right = 330.0\noffset_bottom = 10.0')
n("VBox", "VBoxContainer", "CharPanel", "layout_mode = 2")
n("NameLabel", "Label", "CharPanel/VBox", 'layout_mode = 2\ntext = "Персонаж"', True)
row("CharPanel/VBox", "Здоровье", "Health", col(1.0, 0.4, 0.4))
row("CharPanel/VBox", "Выносливость", "Stamina", col(0.5, 0.85, 0.4))
row("CharPanel/VBox", "Опыт", "Xp", col(0.5, 0.7, 1.0))
n("InfoLabel", "Label", "CharPanel/VBox", 'custom_minimum_size = Vector2(300, 0)\nlayout_mode = 2\ntext = "..."\nautowrap_mode = 3', True)
n("PerksTitle", "Label", "CharPanel/VBox", 'layout_mode = 2\ntext = "Перки (0–100), наведи для описания"')
n("PerksScroll", "ScrollContainer", "CharPanel/VBox", 'custom_minimum_size = Vector2(0, 300)\nlayout_mode = 2\nhorizontal_scroll_mode = 0')
n("PerkList", "VBoxContainer", "CharPanel/VBox/PerksScroll", 'layout_mode = 2\nsize_flags_horizontal = 3', True)

n("MapPanel", "PanelContainer", ".",
  'theme = SubResource("Theme_small")\nlayout_mode = 3\nanchors_preset = 1\nanchor_left = 1.0\nanchor_right = 1.0\noffset_left = -240.0\noffset_top = 10.0\noffset_right = -10.0\noffset_bottom = 10.0\ngrow_horizontal = 0')
n("MapBox", "VBoxContainer", "MapPanel", "layout_mode = 2")
n("MapTitle", "Label", "MapPanel/MapBox", 'layout_mode = 2\ntext = "Карта местности 1×1 км"\nhorizontal_alignment = 1')
n("MapContainer", "SubViewportContainer", "MapPanel/MapBox", 'custom_minimum_size = Vector2(220, 220)\nlayout_mode = 2\nstretch = true')
n("MapViewport", "SubViewport", "MapPanel/MapBox/MapContainer", 'handle_input_locally = false\nsize = Vector2i(220, 220)\nrender_target_update_mode = 4', True)
n("MapCamera", "Camera2D", "MapPanel/MapBox/MapContainer/MapViewport", f'position = Vector2({MAP // 2}, {MAP // 2})\nzoom = Vector2(0.022, 0.022)')

n("Switcher", "HBoxContainer", ".",
  'theme = SubResource("Theme_small")\nlayout_mode = 3\nanchors_preset = 5\nanchor_left = 0.5\nanchor_right = 0.5\noffset_left = -255.0\noffset_top = 10.0\noffset_right = 255.0\noffset_bottom = 10.0\ngrow_horizontal = 2')
for i in (1, 2, 3):
    btn(f"Btn{i}", f"{i}", "Switcher", 'custom_minimum_size = Vector2(165, 44)\nclip_text = true')

n("TaskPanel", "PanelContainer", ".",
  'theme = SubResource("Theme_small")\nlayout_mode = 3\nanchors_preset = 7\nanchor_left = 0.5\nanchor_top = 1.0\nanchor_right = 0.5\nanchor_bottom = 1.0\noffset_left = -290.0\noffset_top = -160.0\noffset_right = 290.0\noffset_bottom = -10.0\ngrow_horizontal = 2\ngrow_vertical = 0')
n("TaskBox", "VBoxContainer", "TaskPanel", "layout_mode = 2")
n("Row1", "HBoxContainer", "TaskPanel/TaskBox", "layout_mode = 2")
for nm, t in [("StopBtn", "Стоп"), ("ChopBtn", "Рубить дерево"), ("MineBtn", "Добывать камень"), ("BerryBtn", "Собирать ягоды"), ("ReadBtn", "Читать книги")]:
    btn(nm, t, "TaskPanel/TaskBox/Row1")
n("Row2", "HBoxContainer", "TaskPanel/TaskBox", "layout_mode = 2")
for nm, t in [("SpearBtn", "Крафт: копьё"), ("MealBtn", "Крафт: паёк"), ("EatBtn", "Съесть паёк")]:
    btn(nm, t, "TaskPanel/TaskBox/Row2")
n("Row3", "HBoxContainer", "TaskPanel/TaskBox", "layout_mode = 2")
n("PerkSelect", "OptionButton", "TaskPanel/TaskBox/Row3", 'layout_mode = 2\nsize_flags_horizontal = 3\nfocus_mode = 0', True)
btn("TrainBtn", "Тренировать перк", "TaskPanel/TaskBox/Row3")
n("Row4", "HBoxContainer", "TaskPanel/TaskBox", "layout_mode = 2")
n("TeacherSelect", "OptionButton", "TaskPanel/TaskBox/Row4", 'layout_mode = 2\nsize_flags_horizontal = 3\nfocus_mode = 0', True)
btn("LearnBtn", "Учиться у него (за деньги)", "TaskPanel/TaskBox/Row4")
n("HintLabel", "Label", "TaskPanel/TaskBox", 'layout_mode = 2\ntext = ""\nautowrap_mode = 3\nmodulate = ' + col(0.8, 0.8, 0.8), True)

write("scenes/hud.tscn", '''[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hud.gd" id="1"]

[sub_resource type="Theme" id="Theme_small"]
default_font_size = 13

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1")

''' + "\n".join(nodes))

# ---------------- main ----------------
def surv(name, title, pos, color, money, perks):
    d = ", ".join(f'"{k}": {float(v)}' for k, v in perks.items())
    return (f'[node name="{name}" parent="Characters" instance=ExtResource("3_char")]\n'
            f'position = Vector2{pos}\ndisplay_name = "{title}"\nbody_color = {color}\n'
            f'start_money = {money}\nstart_perks = {{{d}}}\n')

write("scenes/main.tscn", f'''[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1_main"]
[ext_resource type="PackedScene" path="res://scenes/world.tscn" id="2_world"]
[ext_resource type="PackedScene" path="res://scenes/character.tscn" id="3_char"]
[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="4_hud"]
[ext_resource type="Script" path="res://scripts/follow_camera.gd" id="5_cam"]

[node name="Main" type="Node2D"]
script = ExtResource("1_main")

[node name="World" parent="." instance=ExtResource("2_world")]

[node name="Characters" type="Node2D" parent="."]

{surv("Miron", "Мирон (боец)", (4650, 4750), col(0.85, 0.25, 0.2), 40,
      {"unarmed": 30, "melee": 40, "thrown": 15, "shotgun": 20, "stealth": 10, "lumberjack": 25, "mining": 15})}
{surv("Alisa", "Алиса (инженер)", (4800, 4650), col(0.25, 0.5, 0.9), 25,
      {"mechanics": 45, "electrics": 35, "carpentry": 30, "smithing": 15, "literacy": 35, "chemistry": 20, "teaching": 25, "ranged": 10})}
{surv("Zoya", "Зоя (врач)", (5350, 4700), col(0.3, 0.75, 0.35), 30,
      {"first_aid": 45, "foraging": 40, "cooking": 25, "hunting": 20, "campcraft": 25, "farming": 20, "teaching": 30, "navigation": 15})}
[node name="Camera" type="Camera2D" parent="."]
position = Vector2(4800, 4700)
zoom = Vector2(1.6, 1.6)
limit_left = 0
limit_top = 0
limit_right = {MAP}
limit_bottom = {MAP}
position_smoothing_enabled = true
script = ExtResource("5_cam")

[node name="HUD" parent="." instance=ExtResource("4_hud")]
''')
print("ok")
