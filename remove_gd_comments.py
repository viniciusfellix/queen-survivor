from pathlib import Path
import shutil

PROJECT_DIR = Path(__file__).parent
BACKUP_DIR = PROJECT_DIR / "_backup_before_comment_removal"

EXTENSIONS = [".gd"]

IGNORED_DIRS = {
    ".godot",
    ".git",
    "addons",
    "_backup_before_comment_removal",
}


def should_ignore(path: Path) -> bool:
    return any(part in IGNORED_DIRS for part in path.parts)


def remove_comments_from_gdscript(text: str) -> str:
    result_lines = []

    for line in text.splitlines(keepends=True):
        new_line = []
        in_single_quote = False
        in_double_quote = False
        escaped = False

        i = 0
        while i < len(line):
            char = line[i]

            if escaped:
                new_line.append(char)
                escaped = False
                i += 1
                continue

            if char == "\\":
                new_line.append(char)
                escaped = True
                i += 1
                continue

            if char == "'" and not in_double_quote:
                in_single_quote = not in_single_quote
                new_line.append(char)
                i += 1
                continue

            if char == '"' and not in_single_quote:
                in_double_quote = not in_double_quote
                new_line.append(char)
                i += 1
                continue

            if char == "#" and not in_single_quote and not in_double_quote:
                break

            new_line.append(char)
            i += 1

        cleaned = "".join(new_line).rstrip()

        if line.endswith("\n"):
            cleaned += "\n"

        result_lines.append(cleaned)

    return "".join(result_lines)


def main():
    print("Iniciando remoção de comentários em arquivos .gd...")

    gd_files = [
        path for path in PROJECT_DIR.rglob("*")
        if path.is_file()
        and path.suffix in EXTENSIONS
        and not should_ignore(path.relative_to(PROJECT_DIR))
    ]

    if not gd_files:
        print("Nenhum arquivo .gd encontrado.")
        return

    BACKUP_DIR.mkdir(exist_ok=True)

    changed_count = 0

    for file_path in gd_files:
        relative_path = file_path.relative_to(PROJECT_DIR)
        backup_path = BACKUP_DIR / relative_path

        original_text = file_path.read_text(encoding="utf-8")
        cleaned_text = remove_comments_from_gdscript(original_text)

        if cleaned_text != original_text:
            backup_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(file_path, backup_path)

            file_path.write_text(cleaned_text, encoding="utf-8")
            changed_count += 1

            print(f"Comentários removidos: {relative_path}")

    print("")
    print(f"Finalizado. Arquivos alterados: {changed_count}")
    print(f"Backup criado em: {BACKUP_DIR}")


if __name__ == "__main__":
    main()