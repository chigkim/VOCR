#!/usr/bin/env python3
"""
Script to add Ukrainian, Polish, and Russian translations to Localizable.xcstrings and InfoPlist.xcstrings
Language codes: uk (Ukrainian), pl (Polish), ru (Russian)
"""

import json

# Translation dictionaries - mapping English to Ukrainian, Polish, and Russian
translations = {
    # App
    "Presets": {
        "uk": "Пресети",
        "pl": "Ustawienia wstępne",
        "ru": "Пресеты"
    },
    "VOCR Ready!": {
        "uk": "VOCR готовий!",
        "pl": "VOCR gotowy!",
        "ru": "VOCR готов!"
    },

    # Buttons
    "Add": {
        "uk": "Додати",
        "pl": "Dodaj",
        "ru": "Добавить"
    },
    "Ask": {
        "uk": "Запитати",
        "pl": "Zapytaj",
        "ru": "Спросить"
    },
    "Cancel": {
        "uk": "Скасувати",
        "pl": "Anuluj",
        "ru": "Отменить"
    },
    "Create": {
        "uk": "Створити",
        "pl": "Utwórz",
        "ru": "Создать"
    },
    "Delete": {
        "uk": "Видалити",
        "pl": "Usuń",
        "ru": "Удалить"
    },
    "Duplicate": {
        "uk": "Дублювати",
        "pl": "Duplikuj",
        "ru": "Дублировать"
    },
    "Edit": {
        "uk": "Редагувати",
        "pl": "Edytuj",
        "ru": "Редактировать"
    },
    "From Beginning": {
        "uk": "З початку",
        "pl": "Od początku",
        "ru": "С начала"
    },
    "From Current": {
        "uk": "З поточного",
        "pl": "Od bieżącego",
        "ru": "С текущего"
    },
    "OK": {
        "uk": "OK",
        "pl": "OK",
        "ru": "OK"
    },
    "Reset and Relaunch": {
        "uk": "Скинути і перезапустити",
        "pl": "Zresetuj i uruchom ponownie",
        "ru": "Сбросить и перезапустить"
    },
    "Save": {
        "uk": "Зберегти",
        "pl": "Zapisz",
        "ru": "Сохранить"
    },

    # Columns
    "Hotkey": {
        "uk": "Гаряча клавіша",
        "pl": "Skrót klawiszowy",
        "ru": "Горячая клавиша"
    },
    "Model": {
        "uk": "Модель",
        "pl": "Model",
        "ru": "Модель"
    },
    "Name": {
        "uk": "Назва",
        "pl": "Nazwa",
        "ru": "Имя"
    },

    # Dialogs
    "Asking %@... Please wait...": {
        "uk": "Запит до %@... Зачекайте...",
        "pl": "Pytanie %@... Proszę czekać...",
        "ru": "Запрос %@... Пожалуйста, подождите..."
    },
    "Choose a camera for VOCR to use.": {
        "uk": "Виберіть камеру для VOCR.",
        "pl": "Wybierz kamerę dla VOCR.",
        "ru": "Выберите камеру для VOCR."
    },
    "Camera": {
        "uk": "Камера",
        "pl": "Kamera",
        "ru": "Камера"
    },
    "Unknown": {
        "uk": "Невідомо",
        "pl": "Nieznany",
        "ru": "Неизвестно"
    },
    "Update the system and user prompts used for the Explore Mode.": {
        "uk": "Оновіть системні та користувацькі підказки для режиму дослідження.",
        "pl": "Zaktualizuj monity systemowe i użytkownika używane w trybie eksploracji.",
        "ru": "Обновите системные и пользовательские подсказки для режима исследования."
    },
    "System Prompt": {
        "uk": "Системна підказка",
        "pl": "Monit systemowy",
        "ru": "Системная подсказка"
    },
    "Edit Explore Prompts": {
        "uk": "Редагувати підказки дослідження",
        "pl": "Edytuj monity eksploracji",
        "ru": "Редактировать подсказки исследования"
    },
    "User Prompt": {
        "uk": "Підказка користувача",
        "pl": "Monit użytkownika",
        "ru": "Пользовательская подсказка"
    },
    "Follow up": {
        "uk": "Продовження",
        "pl": "Kontynuacja",
        "ru": "Продолжение"
    },
    "All shortcuts have already been added.": {
        "uk": "Усі комбінації клавіш уже додано.",
        "pl": "Wszystkie skróty zostały już dodane.",
        "ru": "Все горячие клавиши уже добавлены."
    },
    "Shortcut Name": {
        "uk": "Назва комбінації",
        "pl": "Nazwa skrótu",
        "ru": "Название горячей клавиши"
    },
    "New Shortcut": {
        "uk": "Нова комбінація",
        "pl": "Nowy skrót",
        "ru": "Новая горячая клавиша"
    },
    "Unassigned": {
        "uk": "Не призначено",
        "pl": "Nieprzypisany",
        "ru": "Не назначена"
    },
    "Prompt": {
        "uk": "Підказка",
        "pl": "Monit",
        "ru": "Подсказка"
    },
    "This will erase all the settings and presets. This cannot be undone.": {
        "uk": "Це видалить усі налаштування та пресети. Це не можна скасувати.",
        "pl": "To usunie wszystkie ustawienia i konfiguracje. Tej operacji nie można cofnąć.",
        "ru": "Это удалит все настройки и пресеты. Это действие нельзя отменить."
    },
    "Reset?": {
        "uk": "Скинути?",
        "pl": "Zresetować?",
        "ru": "Сбросить?"
    },
    "Choose a destination and save your file.": {
        "uk": "Виберіть призначення та збережіть файл.",
        "pl": "Wybierz miejsce docelowe i zapisz plik.",
        "ru": "Выберите место назначения и сохраните файл."
    },
    "Save Your File": {
        "uk": "Зберегти файл",
        "pl": "Zapisz plik",
        "ru": "Сохранить файл"
    },
    "Choose an Output for positional audio feedback.": {
        "uk": "Виберіть вихід для позиційного звукового відгуку.",
        "pl": "Wybierz wyjście dla pozycyjnego dźwięku.",
        "ru": "Выберите выход для позиционной звуковой обратной связи."
    },
    "Sound Output": {
        "uk": "Звуковий вихід",
        "pl": "Wyjście dźwięku",
        "ru": "Звуковой выход"
    },

    # Errors
    "Failed to access %@, %@": {
        "uk": "Не вдалося отримати доступ до %@, %@",
        "pl": "Nie udało się uzyskać dostępu do %@, %@",
        "ru": "Не удалось получить доступ к %@, %@"
    },
    "Connection error": {
        "uk": "Помилка з'єднання",
        "pl": "Błąd połączenia",
        "ru": "Ошибка соединения"
    },
    "Error decoding JSON": {
        "uk": "Помилка декодування JSON",
        "pl": "Błąd dekodowania JSON",
        "ru": "Ошибка декодирования JSON"
    },
    "Error decoding models JSON": {
        "uk": "Помилка декодування JSON моделей",
        "pl": "Błąd dekodowania JSON modeli",
        "ru": "Ошибка декодирования JSON моделей"
    },
    "Status code %d: %@": {
        "uk": "Код стану %d: %@",
        "pl": "Kod stanu %d: %@",
        "ru": "Код состояния %d: %@"
    },
    "HTTP Error": {
        "uk": "Помилка HTTP",
        "pl": "Błąd HTTP",
        "ru": "Ошибка HTTP"
    },
    "Invalid URL": {
        "uk": "Неправильна URL-адреса",
        "pl": "Nieprawidłowy URL",
        "ru": "Недействительный URL"
    },
    "Cannot parse the JSON string. Try again.": {
        "uk": "Не вдається розібрати рядок JSON. Спробуйте ще раз.",
        "pl": "Nie można przetworzyć ciągu JSON. Spróbuj ponownie.",
        "ru": "Не удается разобрать строку JSON. Попробуйте снова."
    },
    "No data received from server.": {
        "uk": "Не отримано даних від сервера.",
        "pl": "Nie otrzymano danych z serwera.",
        "ru": "Данные от сервера не получены."
    },
    "Error: Could not parse JSON.": {
        "uk": "Помилка: Не вдалося розібрати JSON.",
        "pl": "Błąd: Nie można przetworzyć JSON.",
        "ru": "Ошибка: Не удалось разобрать JSON."
    },
    "Failed to save preset.": {
        "uk": "Не вдалося зберегти пресет.",
        "pl": "Nie udało się zapisać ustawienia.",
        "ru": "Не удалось сохранить пресет."
    },
    "No valid HTTP response object": {
        "uk": "Немає дійсного об'єкта відповіді HTTP",
        "pl": "Brak prawidłowego obiektu odpowiedzi HTTP",
        "ru": "Нет действительного объекта HTTP-ответа"
    },
    "Invalid response from server": {
        "uk": "Неправильна відповідь від сервера",
        "pl": "Nieprawidłowa odpowiedź z serwera",
        "ru": "Недействительный ответ от сервера"
    },
    "Faild to take a screenshot of %@, %@": {
        "uk": "Не вдалося зробити знімок екрана %@, %@",
        "pl": "Nie udało się zrobić zrzutu ekranu %@, %@",
        "ru": "Не удалось сделать снимок экрана %@, %@"
    },

    # Labels
    "API Key:": {
        "uk": "Ключ API:",
        "pl": "Klucz API:",
        "ru": "Ключ API:"
    },
    "API Key": {
        "uk": "Ключ API",
        "pl": "Klucz API",
        "ru": "Ключ API"
    },
    "Model Name": {
        "uk": "Назва моделі",
        "pl": "Nazwa modelu",
        "ru": "Название модели"
    },
    "Name:": {
        "uk": "Назва:",
        "pl": "Nazwa:",
        "ru": "Имя:"
    },
    "System Prompt:": {
        "uk": "Системна підказка:",
        "pl": "Monit systemowy:",
        "ru": "Системная подсказка:"
    },
    "Provider URL": {
        "uk": "URL-адреса постачальника",
        "pl": "URL dostawcy",
        "ru": "URL-адрес поставщика"
    },
    "User Prompt:": {
        "uk": "Підказка користувача:",
        "pl": "Monit użytkownika:",
        "ru": "Пользовательская подсказка:"
    },

    # Menu
    "About...": {
        "uk": "Про програму...",
        "pl": "O programie...",
        "ru": "О программе..."
    },
    "Automatically Check for Updates": {
        "uk": "Автоматично перевіряти оновлення",
        "pl": "Automatycznie sprawdzaj aktualizacje",
        "ru": "Автоматически проверять обновления"
    },
    "Automatically Install Updates": {
        "uk": "Автоматично встановлювати оновлення",
        "pl": "Automatycznie instaluj aktualizacje",
        "ru": "Автоматически устанавливать обновления"
    },
    "Check for Updates": {
        "uk": "Перевірити оновлення",
        "pl": "Sprawdź aktualizacje",
        "ru": "Проверить обновления"
    },
    "Choose Camera...": {
        "uk": "Вибрати камеру...",
        "pl": "Wybierz kamerę...",
        "ru": "Выбрать камеру..."
    },
    "Dismiss Menu": {
        "uk": "Закрити меню",
        "pl": "Zamknij menu",
        "ru": "Закрыть меню"
    },
    "Download  Pre-release": {
        "uk": "Завантажити попередню версію",
        "pl": "Pobierz wersję pre-release",
        "ru": "Загрузить предварительную версию"
    },
    "Edit Explore Prompts…": {
        "uk": "Редагувати підказки дослідження…",
        "pl": "Edytuj monity eksploracji…",
        "ru": "Редактировать подсказки исследования…"
    },
    "New Shortcuts": {
        "uk": "Нова комбінація",
        "pl": "Nowy skrót",
        "ru": "Новая горячая клавиша"
    },
    "Preset Manager…": {
        "uk": "Менеджер пресетів…",
        "pl": "Menedżer ustawień…",
        "ru": "Менеджер пресетов…"
    },
    "Quit": {
        "uk": "Вийти",
        "pl": "Zakończ",
        "ru": "Выйти"
    },
    "Reset...": {
        "uk": "Скинути...",
        "pl": "Zresetuj...",
        "ru": "Сбросить..."
    },
    "Save Latest Image": {
        "uk": "Зберегти останнє зображення",
        "pl": "Zapisz ostatni obraz",
        "ru": "Сохранить последнее изображение"
    },
    "Save OCR Result...": {
        "uk": "Зберегти результат OCR...",
        "pl": "Zapisz wynik OCR...",
        "ru": "Сохранить результат OCR..."
    },
    "Settings": {
        "uk": "Налаштування",
        "pl": "Ustawienia",
        "ru": "Настройки"
    },
    "Auto Scan": {
        "uk": "Автоматичне сканування",
        "pl": "Automatyczne skanowanie",
        "ru": "Автоматическое сканирование"
    },
    "Detect Objects": {
        "uk": "Виявляти об'єкти",
        "pl": "Wykrywaj obiekty",
        "ru": "Обнаруживать объекты"
    },
    "Launch on Login": {
        "uk": "Запускати при вході",
        "pl": "Uruchom przy logowaniu",
        "ru": "Запускать при входе"
    },
    "Log": {
        "uk": "Журнал",
        "pl": "Dziennik",
        "ru": "Журнал"
    },
    "Move Mouse": {
        "uk": "Рухати мишу",
        "pl": "Przesuń mysz",
        "ru": "Перемещать мышь"
    },
    "Positional Audio": {
        "uk": "Позиційний звук",
        "pl": "Dźwięk pozycyjny",
        "ru": "Позиционный звук"
    },
    "Reset Position on Scan": {
        "uk": "Скинути позицію при скануванні",
        "pl": "Zresetuj pozycję przy skanowaniu",
        "ru": "Сбросить позицию при сканировании"
    },
    "Target Window": {
        "uk": "Цільове вікно",
        "pl": "Okno docelowe",
        "ru": "Целевое окно"
    },
    "Use Preset Prompt": {
        "uk": "Використовувати підказку пресета",
        "pl": "Użyj monitu ustawienia",
        "ru": "Использовать подсказку пресета"
    },
    "Shortcuts...": {
        "uk": "Комбінації клавіш...",
        "pl": "Skróty...",
        "ru": "Горячие клавиши..."
    },
    "Sound Output...": {
        "uk": "Звуковий вихід...",
        "pl": "Wyjście dźwięku...",
        "ru": "Звуковой выход..."
    },
    "Updates": {
        "uk": "Оновлення",
        "pl": "Aktualizacje",
        "ru": "Обновления"
    },

    # Messages
    "RealTime OCR started.": {
        "uk": "Розпізнавання в реальному часі запущено.",
        "pl": "OCR w czasie rzeczywistym uruchomione.",
        "ru": "Распознавание в реальном времени запущено."
    },
    "Stopping RealTime OCR.": {
        "uk": "Зупинка розпізнавання в реальному часі.",
        "pl": "Zatrzymywanie OCR w czasie rzeczywistym.",
        "ru": "Остановка распознавания в реальном времени."
    },

    # Modes
    "Window": {
        "uk": "Вікно",
        "pl": "Okno",
        "ru": "Окно"
    },
    "VOCursor": {
        "uk": "VOCursor",
        "pl": "VOCursor",
        "ru": "VOCursor"
    },

    # Navigation
    "Choose an window to scan.": {
        "uk": "Виберіть вікно для сканування.",
        "pl": "Wybierz okno do skanowania.",
        "ru": "Выберите окно для сканирования."
    },
    "Close": {
        "uk": "Закрити",
        "pl": "Zamknij",
        "ru": "Закрыть"
    },
    "%d, %d": {
        "uk": "%d, %d",
        "pl": "%d, %d",
        "ru": "%d, %d"
    },
    "Exit VOCR navigation.": {
        "uk": "Вийти з навігації VOCR.",
        "pl": "Wyjdź z nawigacji VOCR.",
        "ru": "Выйти из навигации VOCR."
    },
    "Finished scanning %@, %@": {
        "uk": "Завершено сканування %@, %@",
        "pl": "Zakończono skanowanie %@, %@",
        "ru": "Завершено сканирование %@, %@"
    },
    "Nothing found": {
        "uk": "Нічого не знайдено",
        "pl": "Nic nie znaleziono",
        "ru": "Ничего не найдено"
    },
    "Unknown App": {
        "uk": "Невідома програма",
        "pl": "Nieznana aplikacja",
        "ru": "Неизвестное приложение"
    },
    "Unknown Window": {
        "uk": "Невідоме вікно",
        "pl": "Nieznane okno",
        "ru": "Неизвестное окно"
    },
    "Untitled": {
        "uk": "Без назви",
        "pl": "Bez tytułu",
        "ru": "Без названия"
    },

    # Placeholders
    "Will Not be shown After saving.": {
        "uk": "Не буде показано після збереження.",
        "pl": "Nie będzie wyświetlane po zapisaniu.",
        "ru": "Не будет показано после сохранения."
    },
    "https://": {
        "uk": "https://",
        "pl": "https://",
        "ru": "https://"
    },

    # Preset Editor
    "Loading…": {
        "uk": "Завантаження…",
        "pl": "Ładowanie…",
        "ru": "Загрузка…"
    },
    "No models found": {
        "uk": "Моделі не знайдено",
        "pl": "Nie znaleziono modeli",
        "ru": "Модели не найдены"
    },
    "Provider": {
        "uk": "Постачальник",
        "pl": "Dostawca",
        "ru": "Поставщик"
    },
    "Edit Preset": {
        "uk": "Редагувати пресет",
        "pl": "Edytuj ustawienie",
        "ru": "Редактировать пресет"
    },
    "New Preset": {
        "uk": "Новий пресет",
        "pl": "Nowe ustawienie",
        "ru": "Новый пресет"
    },
    "Preset Manager": {
        "uk": "Менеджер пресетів",
        "pl": "Menedżer ustawień",
        "ru": "Менеджер пресетов"
    },

    # Search
    "Cancelled.": {
        "uk": "Скасовано.",
        "pl": "Anulowano.",
        "ru": "Отменено."
    },
    "Search OCR Text": {
        "uk": "Шукати текст OCR",
        "pl": "Szukaj tekstu OCR",
        "ru": "Искать текст OCR"
    },
    "Not found.": {
        "uk": "Не знайдено.",
        "pl": "Nie znaleziono.",
        "ru": "Не найдено."
    },

    # Shortcuts
    "Beginning": {
        "uk": "Початок",
        "pl": "Początek",
        "ru": "Начало"
    },
    "Bottom": {
        "uk": "Низ",
        "pl": "Dół",
        "ru": "Низ"
    },
    "Capture Camera": {
        "uk": "Захопити з камери",
        "pl": "Przechwyć kamerę",
        "ru": "Захватить с камеры"
    },
    "Down": {
        "uk": "Вниз",
        "pl": "W dół",
        "ru": "Вниз"
    },
    "End": {
        "uk": "Кінець",
        "pl": "Koniec",
        "ru": "Конец"
    },
    "Exit Navigation": {
        "uk": "Вийти з навігації",
        "pl": "Wyjdź z nawigacji",
        "ru": "Выйти из навигации"
    },
    "Explore": {
        "uk": "Досліджувати",
        "pl": "Eksploruj",
        "ru": "Исследовать"
    },
    "Find Next": {
        "uk": "Знайти наступний",
        "pl": "Znajdź następny",
        "ru": "Найти следующий"
    },
    "Find Previous": {
        "uk": "Знайти попередній",
        "pl": "Znajdź poprzedni",
        "ru": "Найти предыдущий"
    },
    "Find Text": {
        "uk": "Знайти текст",
        "pl": "Znajdź tekst",
        "ru": "Найти текст"
    },
    "Identify Object": {
        "uk": "Ідентифікувати об'єкт",
        "pl": "Zidentyfikuj obiekt",
        "ru": "Идентифицировать объект"
    },
    "Left": {
        "uk": "Ліворуч",
        "pl": "Lewo",
        "ru": "Влево"
    },
    "Next Character": {
        "uk": "Наступний символ",
        "pl": "Następny znak",
        "ru": "Следующий символ"
    },
    "OCR VOCursor": {
        "uk": "OCR VOCursor",
        "pl": "OCR VOCursor",
        "ru": "OCR VOCursor"
    },
    "OCR Window": {
        "uk": "Вікно OCR",
        "pl": "Okno OCR",
        "ru": "Окно OCR"
    },
    "Previous Character": {
        "uk": "Попередній символ",
        "pl": "Poprzedni znak",
        "ru": "Предыдущий символ"
    },
    "Realtime OCR": {
        "uk": "Розпізнавання в реальному часі",
        "pl": "OCR w czasie rzeczywistym",
        "ru": "Распознавание в реальном времени"
    },
    "Report Location": {
        "uk": "Повідомити позицію",
        "pl": "Zgłoś lokalizację",
        "ru": "Сообщить позицию"
    },
    "Right": {
        "uk": "Праворуч",
        "pl": "Prawo",
        "ru": "Вправо"
    },
    "Top": {
        "uk": "Верх",
        "pl": "Góra",
        "ru": "Верх"
    },
    "Up": {
        "uk": "Вгору",
        "pl": "W górę",
        "ru": "Вверх"
    },
    "Customize Shortcuts": {
        "uk": "Налаштувати комбінації клавіш",
        "pl": "Dostosuj skróty",
        "ru": "Настроить горячие клавиши"
    },

    # Updates
    "Version %@ is now available": {
        "uk": "Доступна версія %@",
        "pl": "Dostępna jest wersja %@",
        "ru": "Доступна версия %@"
    },
    "A new update is available": {
        "uk": "Доступне нове оновлення",
        "pl": "Dostępna jest nowa aktualizacja",
        "ru": "Доступно новое обновление"
    },

    # InfoPlist.xcstrings translations
    "VOCR": {
        "uk": "VOCR",
        "pl": "VOCR",
        "ru": "VOCR"
    },
    "Image files": {
        "uk": "Файли зображень",
        "pl": "Pliki obrazów",
        "ru": "Файлы изображений"
    },
    "Speak announcements and take Screenshot under VoiceOver cursor": {
        "uk": "Озвучувати повідомлення та робити знімок екрана під курсором VoiceOver",
        "pl": "Odczytuj ogłoszenia i wykonuj zrzut ekranu pod kursorem VoiceOver",
        "ru": "Озвучивать объявления и делать снимок экрана под курсором VoiceOver"
    },
    "Capture a photo to VOCR to use.": {
        "uk": "Зробіть фото для використання в VOCR.",
        "pl": "Zrób zdjęcie do użycia w VOCR.",
        "ru": "Сделайте фото для использования в VOCR."
    },
    "Copyright © 2019 Chi Kim. All rights reserved.": {
        "uk": "© 2019 Chi Kim. Усі права захищено.",
        "pl": "Copyright © 2019 Chi Kim. Wszelkie prawa zastrzeżone.",
        "ru": "© 2019 Chi Kim. Все права защищены."
    },
}

def add_translations_to_file(input_path, output_path, languages=['uk', 'pl', 'ru']):
    """Add Ukrainian, Polish, and Russian translations to the xcstrings file"""
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    translation_count = 0

    # Iterate through all strings
    for key, string_data in data['strings'].items():
        if 'localizations' in string_data:
            # Get English value
            en_value = string_data['localizations'].get('en', {}).get('stringUnit', {}).get('value', '')

            # Check if we have translations for this English value
            if en_value in translations:
                trans = translations[en_value]

                # Add translations for each language
                for lang in languages:
                    if lang in trans and lang not in string_data['localizations']:
                        string_data['localizations'][lang] = {
                            "stringUnit": {
                                "state": "translated",
                                "value": trans[lang]
                            }
                        }
                        translation_count += 1

    # Write output
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Added {translation_count} translations to {output_path}")
    print(f"Languages: {', '.join(languages)}")

if __name__ == "__main__":
    # Process Localizable.xcstrings
    localizable_input = "/Users/vtsaran/src/vocr/VOCR/Localizable.xcstrings"
    localizable_output = "/Users/vtsaran/src/vocr/VOCR/Localizable.xcstrings"
    add_translations_to_file(localizable_input, localizable_output)

    # Process InfoPlist.xcstrings
    infoplist_input = "/Users/vtsaran/src/vocr/VOCR/InfoPlist.xcstrings"
    infoplist_output = "/Users/vtsaran/src/vocr/VOCR/InfoPlist.xcstrings"
    add_translations_to_file(infoplist_input, infoplist_output)

    print("\nTranslation complete!")
