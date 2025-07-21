import os

# Dossiers à créer
folders = [
    "assets/ui/",
    "assets/ui/themes/",
    "assets/fonts/",
    "localization/"
]

for folder in folders:
    os.makedirs(folder, exist_ok=True)

# Placeholder PNG blanc

# Placeholder Theme Godot
with open("assets/ui/themes/main_theme.tres", "w", encoding="utf-8") as f:
    f.write('[gd_resource type="Theme" load_steps=2 format=3]\n')

# Placeholder Font (faux fichier, à remplacer par une vraie TTF plus tard)
with open("assets/fonts/pratchett_font.ttf", "wb") as f:
    f.write(b"FAKEFONT")  # Placez une vraie TTF ensuite !

# Fichiers de traduction vides
translations = {
    "fr": 'locale="fr"\n',
    "en": 'locale="en"\n',
    "de": 'locale="de"\n'
}
for lang, content in translations.items():
    with open(f"localization/translations.{lang}.translation", "w", encoding="utf-8") as f:
        f.write("[resource]\n" + content)
