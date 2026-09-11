# ☕ Coffe.nvim

Coffe.nvim — готовая сборка и Lua-плагин для **Neovim 0.11+**. Она рассчитана на
программистов и тех, кто редактирует Markdown и обычные текстовые файлы прямо в
терминале.

Coffe добавляет стартовый экран, проекты, файловую панель, поиск, Git/diff,
Markdown-инструменты, быстрые заметки и автоматические сессии. Нативные команды и
режимы Neovim остаются доступными.

## Быстрая установка

### 1. Проверь требования

Обязательны:

- Neovim 0.11 или новее;
- Git;
- `curl` для установки одной командой.

Рекомендуется `ripgrep` — он ускоряет поиск файлов и нужен для поиска текста по
проекту.

Проверка:

```sh
nvim --version | head -n 1
git --version
rg --version
```

На macOS зависимости можно установить через Homebrew:

```sh
brew install neovim git ripgrep
```

На Linux сначала проверь версию Neovim из репозитория своего дистрибутива: она
должна быть не ниже 0.11.

### 2. Установи Coffe.nvim

Вставь в терминал:

```sh
curl -fsSL https://raw.githubusercontent.com/SDH4114/Coffe_nvim/main/install.sh | sh
```

Установщик:

- скачает проект в `~/.local/share/coffe.nvim`;
- создаст команду `~/.local/bin/coffe`;
- создаст пользовательский конфиг `~/.config/coffe/coffe.lua`;
- установит стандартные плагины;
- не изменит `~/.config/nvim` и обычный Neovim.

### 3. Запусти

```sh
~/.local/bin/coffe
```

Открыть текущую папку, проект или конкретный файл:

```sh
~/.local/bin/coffe .
~/.local/bin/coffe ~/Projects/my-app
~/.local/bin/coffe README.md
~/.local/bin/coffe src/main.py tests/test_main.py
```

Если `~/.local/bin` находится в `PATH`, используй короткую команду:

```sh
coffe
coffe .
coffe README.md
```

Если команда `coffe` не найдена, добавь в `~/.zshrc`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Затем перезапусти терминал или выполни `source ~/.zshrc`.

## Установка без внешних плагинов

Чтобы установить только автономное ядро и не скачивать плагины:

```sh
curl -fsSL https://raw.githubusercontent.com/SDH4114/Coffe_nvim/main/install.sh | COFFE_SKIP_PLUGINS=1 sh
```

Запустить Coffe без bootstrap lazy.nvim:

```sh
COFFE_OFFLINE=1 coffe
```

Без сети продолжают работать встроенная тема, dashboard, explorer, picker,
Markdown, заметки, проекты, сессии и Git/diff. Для поиска текста всё равно нужен
локально установленный `ripgrep`.

## Ручной запуск из репозитория

Подходит для разработки или проверки проекта перед установкой:

```sh
git clone https://github.com/SDH4114/Coffe_nvim.git
cd Coffe_nvim
./scripts/coffe
```

Открыть файл или каталог:

```sh
./scripts/coffe README.md
./scripts/coffe .
```

Offline-запуск:

```sh
COFFE_OFFLINE=1 ./scripts/coffe
```

## Обновление

Повтори команду установки:

```sh
curl -fsSL https://raw.githubusercontent.com/SDH4114/Coffe_nvim/main/install.sh | sh
```

Установщик выполнит безопасное fast-forward обновление и сохранит
`~/.config/coffe/coffe.lua`. Если установленный код был изменён вручную, обновление
остановится, чтобы не потерять эти изменения.

## Что входит

- адаптивный dashboard с логотипом COFFE, проектами и недавними файлами;
- Gruvbox Dark и встроенная offline-тема;
- Neo-tree или автономный файловый explorer;
- Telescope или автономный fuzzy picker с preview;
- поиск файлов, текста, недавних файлов и открытых буферов;
- создание, открытие и закрепление проектов;
- Markdown outline, checkbox и переход по локальным ссылкам;
- быстрые заметки в настраиваемый `inbox.md`;
- автоматическое восстановление файлов, вкладок, split-окон и курсоров;
- Git status, diff текущего файла и diff репозитория;
- строка состояния с веткой и количеством изменённых файлов;
- persistent undo, системный clipboard, автоскобки и автодополнение;
- command palette и встроенная справка.

Языковые серверы, форматтеры и отладчики автоматически не устанавливаются. Их можно
добавить через обычные lazy.nvim specs и `vim.lsp.config` / `vim.lsp.enable`.

## Все команды

Все пользовательские команды Coffe начинаются с `Cf`. Neovim требует, чтобы
пользовательская команда начиналась с заглавной буквы.

| Команда | Что делает |
| --- | --- |
| `:Cf` | Открывает главный экран |
| `:Cf <action>` | Выполняет действие без открытия dashboard |
| `:CfCommands` | Открывает общую command palette |
| `:CfFiles` | Ищет файл в текущем проекте |
| `:CfSearch` | Ищет текст по проекту через ripgrep |
| `:CfRecent` | Показывает недавно открытые файлы |
| `:CfBuffers` | Показывает открытые буферы; `Ctrl-X` закрывает сохранённый буфер |
| `:CfExplorer` | Открывает или закрывает файловую панель |
| `:CfSettings` | Открывает активный файл конфигурации Coffe |
| `:CfCreateProject` | Создаёт проект, не перезаписывая существующий каталог |
| `:CfOpenProject` | Предлагает выбрать каталог проекта |
| `:CfOpenProject {path}` | Открывает указанный каталог проекта |
| `:CfProjects` | Показывает недавние и закреплённые проекты |
| `:CfPinProject` | Закрепляет или открепляет текущий проект |
| `:CfNote` | Открывает окно быстрой заметки |
| `:CfMarkdown` | Показывает outline заголовков текущего Markdown-файла |
| `:CfGit` | Показывает staged, unstaged, renamed и untracked файлы |
| `:CfDiff` | Показывает staged и unstaged diff текущего файла |
| `:CfDiffAll` | Показывает staged и unstaged diff всего репозитория |
| `:CfKeys` | Открывает встроенную справку по клавишам |
| `:checkhealth coffe` | Проверяет локальные требования и clipboard |

Действия для `:Cf <action>`:

| Действие | Эквивалент |
| --- | --- |
| `home` | `:Cf` |
| `commands` | `:CfCommands` |
| `files` | `:CfFiles` |
| `search` | `:CfSearch` |
| `recent` | `:CfRecent` |
| `buffers` | `:CfBuffers` |
| `explorer` | `:CfExplorer` |
| `settings` | `:CfSettings` |
| `new` | `:CfCreateProject` |
| `projects` | `:CfProjects` |
| `note` | `:CfNote` |
| `markdown` | `:CfMarkdown` |
| `git` | `:CfGit` |
| `diff` | `:CfDiff` |
| `diffall` | `:CfDiffAll` |
| `help` | `:CfKeys` |

Примеры:

```vim
:Cf files
:Cf search
:Cf note
:Cf git
:Cf diffall
```

## Основные клавиши

Leader в самостоятельной сборке — `Space`. В режиме плагина используется leader
текущей конфигурации. Существующие пользовательские keymaps имеют приоритет.

| Действие | Клавиши |
| --- | --- |
| Command palette | `Space Space` |
| Dashboard | `Space h` |
| Explorer | `Space e` |
| Файлы / текст / недавние | `Space ff` / `Space fg` / `Space fr` |
| Открытые буферы | `Space bb` |
| Создать / открыть / выбрать проект | `Space pn` / `Space po` / `Space pr` |
| Быстрая заметка | `Space mn` |
| Markdown outline | `Space mo` |
| Переключить Markdown checkbox | `Space mx` |
| Перейти по локальной Markdown-ссылке | `Space mf` |
| Git status | `Space gs` |
| Diff текущего файла | `Space gd` |
| Настройки / справка | `Space ,` / `Space ?` |
| Следующий / предыдущий / закрыть буфер | `Space bn` / `Space bp` / `Space bd` |
| Копировать / вставить | `Space y` / `Space p` |
| Сохранить | `Ctrl-S` или `Cmd-S` |
| Удалить строку | `dd`, `F8` или `Cmd-Backspace` |

Нативные `u`, `Ctrl-R`, `Ctrl-V`, `Ctrl-W`, `dd` и `dw` не заменяются.

## Как пользоваться отдельными функциями

### Быстрые заметки

1. Выполни `:CfNote` или нажми `Space mn`.
2. Напиши текст.
3. Выполни `:w`, чтобы добавить заметку с датой и временем в `notes.path`.
4. Нажми `Esc`, затем `q`, чтобы закрыть окно без сохранения.

Путь по умолчанию: `~/Documents/Coffe/inbox.md`.

### Markdown

- `:CfMarkdown` или `Space mo` — список заголовков и переход к разделу;
- `Space mx` — переключение `- [ ]` и `- [x]`;
- `Space mf` — переход по `[название](file.md)` или `[[wiki-link]]`;
- перенос длинных строк включён визуально и не изменяет файл.

### Git и diff

- `:CfGit` или `Space gs` — изменённые файлы;
- `Enter` в Git picker — открыть выбранный файл;
- `Ctrl-O` — preview diff;
- `:CfDiff` или `Space gd` — diff текущего файла;
- `:CfDiffAll` — diff всего репозитория;
- `q` закрывает окно diff.

### Автоматические сессии

Сессия сохраняется перед выходом и перед сменой проекта. При чистом запуске проекта
Coffe восстанавливает открытые файлы, вкладки, split-окна и позиции курсоров.
Несохранённые буферы не закрываются и не перезаписываются. Отдельных команд сохранения
и восстановления нет.

### Explorer

Во встроенной offline-панели:

| Клавиша | Действие |
| --- | --- |
| `h` / `l` | Свернуть / раскрыть каталог |
| `Enter` или `o` | Открыть файл |
| `s` | Открыть в вертикальном split |
| `t` | Открыть во вкладке |
| `P` | Preview |
| `a` | Создать файл; путь с `/` в конце создаёт каталог |
| `r` | Переименовать |
| `D` | Удалить после подтверждения |
| `m` | Отметить элемент |
| `.` | Показать или скрыть скрытые файлы |
| `R` | Обновить панель |
| `?` | Справка |
| `q` | Закрыть панель |

Explorer удаляет только файлы и пустые каталоги. Загруженный файл перед
переименованием или удалением нужно закрыть через `:bd`.

## Настройка

Конфиг установленной сборки: `~/.config/coffe/coffe.lua`.

Открыть его можно через `:CfSettings`. После изменения перезапусти Neovim.

```lua
return {
  theme = "gruvbox",
  background = "dark",
  dashboard = true,
  clipboard = true,
  undo = true,
  mouse = true,
  numbers = true,
  relative_numbers = false,
  indent = 2,

  ui = { statusline = true },
  explorer = { side = "left", width = 32, auto_open = false },
  projects = { root = "~/Projects", recent_limit = 20 },
  markdown = {
    wrap = true,
    outline_key = "<leader>mo",
    checkbox_key = "<leader>mx",
    follow_key = "<leader>mf",
  },
  notes = { path = "~/Documents/Coffe/inbox.md" },
  sessions = { enabled = true, auto_restore = true },

  keys = {
    palette = "<leader><space>",
    explorer = "<leader>e",
    files = "<leader>ff",
    search = "<leader>fg",
    recent = "<leader>fr",
    buffers = "<leader>bb",
    note = "<leader>mn",
    git = "<leader>gs",
    diff = "<leader>gd",
    dashboard = "<leader>h",
    settings = "<leader>,",
  },

  plugins = {
    -- { "numToStr/Comment.nvim", opts = {} },
  },
}
```

Полезные правила:

- `theme = false` сохраняет тему существующей конфигурации;
- `mappings = false` отключает все keymaps Coffe;
- `false` вместо отдельной клавиши отключает только её;
- `ui.statusline = false` сохраняет существующую statusline;
- `sessions.enabled = false` отключает хранение сессий;
- `explorer.side` принимает `"left"` или `"right"`.

## Подключение как плагина

Если у тебя уже есть lazy.nvim или LazyVim, добавь:

```lua
{
  "SDH4114/Coffe_nvim",
  lazy = false,
  priority = 1000,
  opts = {
    theme = false,
    ui = { statusline = false },
    explorer = { side = "left", width = 32 },
    config_file = vim.fn.stdpath("config") .. "/lua/plugins/coffe.lua",
  },
}
```

В этом режиме Coffe не запускает второй lazy.nvim и не забирает управление LSP,
форматтерами или отладчиками. Расширенный пример находится в
[`examples/lazy.lua`](examples/lazy.lua).

## Где хранятся файлы

| Данные | Путь |
| --- | --- |
| Код установленной сборки | `~/.local/share/coffe.nvim` |
| Команда запуска | `~/.local/bin/coffe` |
| Пользовательский конфиг | `~/.config/coffe/coffe.lua` |
| Плагины и данные Neovim | `~/.local/share/coffe` |
| Сессии, undo и история | `~/.local/state/coffe` |
| Быстрые заметки по умолчанию | `~/Documents/Coffe/inbox.md` |

Обычные `~/.config/nvim`, `~/.local/share/nvim` и команда `nvim` не изменяются.

## Возможные проблемы

### `coffe: command not found`

Добавь `~/.local/bin` в `PATH` или запускай `~/.local/bin/coffe`.

### Установлена старая версия Neovim

Проверь `nvim --version`. Coffe требует 0.11+. Обнови Neovim и повтори установку.

### Не работает поиск текста

Установи ripgrep (`brew install ripgrep`) и проверь `rg --version`.

### Не скачались плагины

Проверь интернет и Git, затем повтори установку. Ядро можно запустить без плагинов:

```sh
COFFE_OFFLINE=1 coffe
```

### Не работают Cmd-сочетания

Терминал должен передавать эти клавиши Neovim. Переносимый вариант удаления строки —
`F8`. Пример настройки Ghostty находится в
[`examples/ghostty.conf`](examples/ghostty.conf). Coffe не изменяет конфиг терминала.

### Проверка состояния

Внутри Coffe выполни `:checkhealth coffe`.

## Удаление

Перед удалением сохрани `~/.config/coffe/coffe.lua` и
`~/Documents/Coffe/inbox.md`, если они нужны.

На macOS можно переместить установленную сборку в Корзину:

```sh
mkdir -p "$HOME/.Trash/Coffe.nvim-backup"
mv "$HOME/.local/share/coffe.nvim" "$HOME/.Trash/Coffe.nvim-backup/"
mv "$HOME/.local/bin/coffe" "$HOME/.Trash/Coffe.nvim-backup/"
mv "$HOME/.config/coffe" "$HOME/.Trash/Coffe.nvim-backup/"
mv "$HOME/.local/share/coffe" "$HOME/.Trash/Coffe.nvim-backup/" 2>/dev/null || true
mv "$HOME/.local/state/coffe" "$HOME/.Trash/Coffe.nvim-backup/" 2>/dev/null || true
```

Заметки не удаляются автоматически, потому что могут содержать пользовательский текст.

## Проверка проекта для разработчиков

```sh
bash tests/run.sh
git diff --check
```

Проверка с установленными внешними плагинами:

```sh
./scripts/coffe --headless '+luafile tests/plugins.lua'
```

Проект проверен на macOS с Neovim 0.12.2. Основной минимальный контракт — Neovim
0.11+.

## Лицензия

См. [`LICENSE`](LICENSE).
