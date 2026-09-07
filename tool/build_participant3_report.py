"""Пошаговая сборка отчёта третьего участника по производственной практике."""

from pathlib import Path

from docx import Document
from docx.enum.table import (
    WD_CELL_VERTICAL_ALIGNMENT,
    WD_ROW_HEIGHT_RULE,
    WD_TABLE_ALIGNMENT,
)
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Mm, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "Отчет_участника_3_ГОСТ.docx"


def set_font(run, size=14, bold=False, italic=False):
    run.font.name = "Times New Roman"
    run._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic


def set_cell_shading(cell, fill):
    properties = cell._tc.get_or_add_tcPr()
    shading = properties.find(qn("w:shd"))
    if shading is None:
        shading = OxmlElement("w:shd")
        properties.append(shading)
    shading.set(qn("w:fill"), fill)


def set_cell_border(cell, color="808080", size="8"):
    properties = cell._tc.get_or_add_tcPr()
    borders = properties.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        properties.append(borders)
    for edge in ("top", "left", "bottom", "right"):
        tag = "w:" + edge
        element = borders.find(qn(tag))
        if element is None:
            element = OxmlElement(tag)
            borders.append(element)
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), size)
        element.set(qn("w:color"), color)


def repeat_table_header(row):
    properties = row._tr.get_or_add_trPr()
    header = OxmlElement("w:tblHeader")
    header.set(qn("w:val"), "true")
    properties.append(header)


def prevent_row_split(row):
    properties = row._tr.get_or_add_trPr()
    no_split = OxmlElement("w:cantSplit")
    no_split.set(qn("w:val"), "true")
    properties.append(no_split)


def configure_document(doc):
    section = doc.sections[0]
    section.page_width = Mm(210)
    section.page_height = Mm(297)
    section.top_margin = Cm(2)
    section.bottom_margin = Cm(2)
    section.left_margin = Cm(3)
    section.right_margin = Cm(1.5)
    section.header_distance = Cm(1)
    section.footer_distance = Cm(1)
    section.different_first_page_header_footer = True

    normal = doc.styles["Normal"]
    normal.font.name = "Times New Roman"
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    normal.font.size = Pt(14)
    normal.font.color.rgb = RGBColor(0, 0, 0)
    normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    normal.paragraph_format.first_line_indent = Cm(1.25)
    normal.paragraph_format.line_spacing = 1.5
    normal.paragraph_format.space_before = Pt(0)
    normal.paragraph_format.space_after = Pt(0)
    normal.paragraph_format.widow_control = True

    for level in (1, 2, 3):
        style = doc.styles[f"Heading {level}"]
        style.font.name = "Times New Roman"
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
        style.font.size = Pt(14)
        style.font.bold = True
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.LEFT
        style.paragraph_format.first_line_indent = Cm(1.25)
        style.paragraph_format.line_spacing = 1.5
        style.paragraph_format.space_before = Pt(0 if level == 1 else 12)
        style.paragraph_format.space_after = Pt(12 if level == 1 else 6)
        style.paragraph_format.page_break_before = level == 1
        style.paragraph_format.keep_with_next = True
        style.paragraph_format.keep_together = True

    settings = doc.settings._element
    update_fields = settings.find(qn("w:updateFields"))
    if update_fields is None:
        update_fields = OxmlElement("w:updateFields")
        settings.append(update_fields)
    update_fields.set(qn("w:val"), "true")


def add_field(paragraph, instruction, fallback=""):
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    begin_run = paragraph.add_run()
    begin_run._r.append(begin)

    code = OxmlElement("w:instrText")
    code.set(qn("xml:space"), "preserve")
    code.text = instruction
    code_run = paragraph.add_run()
    code_run._r.append(code)

    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    separate_run = paragraph.add_run()
    separate_run._r.append(separate)

    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    if fallback:
        set_font(paragraph.add_run(fallback), 12)
    end_run = paragraph.add_run()
    end_run._r.append(end)


def add_page_number(doc):
    paragraph = doc.sections[0].footer.paragraphs[0]
    paragraph.clear()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    paragraph.paragraph_format.first_line_indent = Cm(0)
    add_field(paragraph, "PAGE", "1")


def centered(doc, value, size=14, bold=False, before=0, after=0):
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    paragraph.paragraph_format.first_line_indent = Cm(0)
    paragraph.paragraph_format.space_before = Pt(before)
    paragraph.paragraph_format.space_after = Pt(after)
    set_font(paragraph.add_run(value), size, bold)
    return paragraph


def add_structural_heading(doc, value, include_in_contents=True):
    paragraph = (
        doc.add_heading(value.upper(), level=1)
        if include_in_contents
        else doc.add_paragraph()
    )
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    paragraph.paragraph_format.first_line_indent = Cm(0)
    paragraph.paragraph_format.page_break_before = True
    paragraph.paragraph_format.keep_with_next = True
    if not include_in_contents:
        set_font(paragraph.add_run(value.upper()), 14, True)
    return paragraph


def add_local_heading(doc, number, value):
    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.first_line_indent = Cm(1.25)
    paragraph.paragraph_format.space_before = Pt(12)
    paragraph.paragraph_format.space_after = Pt(6)
    paragraph.paragraph_format.keep_with_next = True
    set_font(paragraph.add_run(f"{number}. {value}"), 14, True)
    return paragraph


def add_text(doc, value):
    return doc.add_paragraph(value)


def add_list(doc, values):
    for value in values:
        paragraph = doc.add_paragraph()
        paragraph.paragraph_format.left_indent = Cm(1.25)
        paragraph.paragraph_format.first_line_indent = Cm(0)
        paragraph.add_run("– " + value)


def add_table_caption(doc, number, value):
    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.first_line_indent = Cm(0)
    paragraph.paragraph_format.keep_with_next = True
    set_font(paragraph.add_run(f"Таблица {number} — {value}"), 14)
    return paragraph


def add_figure_placeholder(doc, number, value, height=5.5):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    row = table.rows[0]
    row.height = Cm(height)
    row.height_rule = WD_ROW_HEIGHT_RULE.AT_LEAST
    cell = row.cells[0]
    cell.width = Cm(15.5)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    set_cell_shading(cell, "F2F2F2")
    set_cell_border(cell)
    paragraph = cell.paragraphs[0]
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    paragraph.paragraph_format.first_line_indent = Cm(0)
    set_font(paragraph.add_run("МЕСТО ДЛЯ СКРИНШОТА\n\n" + value), 12, True)

    caption = doc.add_paragraph(f"Рисунок {number} — {value}")
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    caption.paragraph_format.first_line_indent = Cm(0)
    caption.paragraph_format.keep_together = True
    for run in caption.runs:
        set_font(run, 14)
    return caption


def add_title_page(doc):
    centered(doc, "МИНИСТЕРСТВО НАУКИ, ВЫСШЕГО ОБРАЗОВАНИЯ", 12, True)
    centered(doc, "И ИННОВАЦИЙ КЫРГЫЗСКОЙ РЕСПУБЛИКИ", 12, True)
    centered(
        doc,
        "КЫРГЫЗСКИЙ ГОСУДАРСТВЕННЫЙ ТЕХНИЧЕСКИЙ",
        12,
        True,
        before=8,
    )
    centered(doc, "УНИВЕРСИТЕТ им. И. РАЗЗАКОВА", 12, True)
    centered(
        doc,
        "ИНСТИТУТ ИНФОРМАЦИОННЫХ ТЕХНОЛОГИЙ",
        12,
        True,
        before=8,
    )
    centered(
        doc,
        "Кафедра «Программное обеспечение компьютерных систем»",
        12,
    )

    centered(doc, "ОТЧЁТ", 20, True, before=42)
    centered(doc, "ПО ПРОИЗВОДСТВЕННОЙ ПРАКТИКЕ", 16, True, after=16)
    centered(doc, "на тему:", 14)
    centered(
        doc,
        "«РАЗРАБОТКА И ТЕСТИРОВАНИЕ МУЛЬТИМЕДИЙНЫХ И РЕЛИГИОЗНЫХ "
        "МОДУЛЕЙ ОБРАЗОВАТЕЛЬНОГО ПРИЛОЖЕНИЯ IRFAN ACADEMY»",
        15,
        True,
    )

    details = doc.add_paragraph()
    details.alignment = WD_ALIGN_PARAGRAPH.LEFT
    details.paragraph_format.left_indent = Cm(7)
    details.paragraph_format.first_line_indent = Cm(0)
    details.paragraph_format.space_before = Pt(28)
    details.paragraph_format.line_spacing = 1.0
    for value in (
        "Выполнил: студент группы ПИ ан-2-23",
        "[ФИО ТРЕТЬЕГО УЧАСТНИКА]",
        "Подпись: ____________________",
        "Место практики: [ОРГАНИЗАЦИЯ]",
        "Руководитель от организации:",
        "[ФИО, ДОЛЖНОСТЬ] ____________",
        "Руководитель от кафедры:",
        "[ФИО, ДОЛЖНОСТЬ] ____________",
    ):
        set_font(details.add_run(value + "\n"), 14)

    centered(doc, "Бишкек — 2026", 14, before=20)


def add_individual_assignment(doc):
    add_structural_heading(
        doc,
        "ИНДИВИДУАЛЬНОЕ ЗАДАНИЕ",
        include_in_contents=False,
    )

    values = (
        ("Студент", "[ФИО ТРЕТЬЕГО УЧАСТНИКА]"),
        ("Группа", "ПИ ан-2-23"),
        ("Период практики", "16.06.2026 — 13.07.2026"),
        (
            "Роль в проекте",
            "разработчик мультимедийных и религиозных модулей",
        ),
        (
            "Тема индивидуальной работы",
            "разработка и тестирование загрузки и воспроизведения видео, "
            "геолокации, времени намаза, направления Кыблы и локальных "
            "напоминаний в приложении Irfan Academy",
        ),
    )
    for label, value in values:
        paragraph = doc.add_paragraph()
        paragraph.add_run(label + " — " + value + ".")

    add_local_heading(doc, 1, "Цель индивидуальной работы")
    doc.add_paragraph(
        "Разработать и проверить мультимедийные и религиозные модули "
        "образовательного приложения Irfan Academy, обеспечив устойчивую "
        "загрузку и воспроизведение видеоуроков, корректный расчёт времени "
        "намаза и направления Кыблы, а также безопасную работу локальных "
        "уведомлений на поддерживаемых платформах."
    )

    add_local_heading(doc, 2, "Задачи индивидуальной работы")
    tasks = (
        "проанализировать доступные варианты хранения видеоуроков;",
        "подключить внешнее видеохранилище для демонстрационной версии;",
        "реализовать выбор видеофайла с устройства и автоматический запуск загрузки;",
        "реализовать отображение прогресса, отмену и повторные попытки;",
        "обеспечить частичную передачу больших видеофайлов;",
        "автоматически получать продолжительность и технические сведения видео;",
        "заменить имитацию воспроизведения настоящим сетевым видеоплеером;",
        "реализовать получение координат пользователя;",
        "рассчитать время намаза и определить следующий намаз;",
        "реализовать расчёт и отображение направления Кыблы;",
        "настроить локальные напоминания о предстоящих намазах;",
        "проверить разработанные модули на Android и Web и устранить выявленные ошибки.",
    )
    add_list(doc, tasks)

    add_local_heading(doc, 3, "Ожидаемый результат")
    doc.add_paragraph(
        "Рабочий набор мультимедийных и религиозных функций Irfan Academy: "
        "выбор, загрузка и воспроизведение видеоуроков; получение геолокации; "
        "расчёт расписания намазов и Кыблы; локальные напоминания; обработка "
        "сетевых и платформенных ошибок."
    )
    doc.add_paragraph()
    for value in (
        "Дата выдачи задания: 16.06.2026",
        "Подпись студента: ____________________",
        "Подпись руководителя: ________________",
    ):
        paragraph = doc.add_paragraph(value)
        paragraph.paragraph_format.first_line_indent = Cm(0)


def add_schedule(doc):
    add_structural_heading(
        doc,
        "КАЛЕНДАРНЫЙ ГРАФИК ПРОХОЖДЕНИЯ ПРАКТИКИ",
        include_in_contents=False,
    )
    add_table_caption(
        doc,
        1,
        "Календарный график и краткая характеристика выполненных работ",
    )
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = (
        "№",
        "Срок выполнения",
        "Содержание и краткая характеристика выполненных работ",
    )
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])

    rows = (
        (
            "1",
            "16.06.26–22.06.26",
            "Изучение проекта и анализ хранения видео. Изучена структура "
            "Flutter-проекта и определена индивидуальная "
            "зона ответственности. Проанализированы Firebase Storage, "
            "Cloudflare R2 и Cloudinary. Подготовлен способ подключения "
            "внешнего видеохранилища.",
        ),
        (
            "2",
            "23.06.26–29.06.26",
            "Разработка загрузки и воспроизведения видео. Реализованы выбор "
            "видео с устройства, автоматическая загрузка, "
            "индикатор прогресса, отмена и повторные попытки. Добавлена "
            "частичная отправка больших файлов, автоматическое получение "
            "метаданных и настоящее воспроизведение видео.",
        ),
        (
            "3",
            "30.06.26–06.07.26",
            "Разработка геолокации, времени намаза и Кыблы. Реализованы "
            "получение координат, резервное использование "
            "координат Бишкека, расчёт времени намаза, определение следующего "
            "намаза, обратный отсчёт и направление Кыблы.",
        ),
        (
            "4",
            "07.07.26–13.07.26",
            "Уведомления, тестирование и исправление ошибок. Настроены "
            "локальные напоминания. Проведена проверка разработанных "
            "модулей на Android и Web. Исправлены ошибки CORS, загрузки видео "
            "и вызова zonedSchedule в браузере. Подготовлены материалы для "
            "отчёта и демонстрации.",
        ),
    )
    for row_values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, row_values):
            cell.text = value

    widths = (Cm(0.9), Cm(3.2), Cm(11.4))
    for row_index, row in enumerate(table.rows):
        prevent_row_split(row)
        for index, cell in enumerate(row.cells):
            cell.width = widths[index]
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.first_line_indent = Cm(0)
                paragraph.paragraph_format.line_spacing = 1.0
                paragraph.alignment = (
                    WD_ALIGN_PARAGRAPH.CENTER
                    if index in (0, 1)
                    else WD_ALIGN_PARAGRAPH.LEFT
                )
                for run in paragraph.runs:
                    set_font(run, 12, row_index == 0)

def add_contents(doc):
    add_structural_heading(doc, "СОДЕРЖАНИЕ", include_in_contents=False)
    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.first_line_indent = Cm(0)
    add_field(
        paragraph,
        'TOC \\o "1-3" \\h \\z \\u',
        "Содержание отчёта",
    )


def add_introduction(doc):
    add_structural_heading(doc, "ВВЕДЕНИЕ")
    add_text(
        doc,
        "Во время производственной практики разрабатывались мультимедийные и "
        "религиозные функции приложения Irfan Academy. Работа включала загрузку "
        "и воспроизведение видеоуроков, получение геолокации, расчёт времени "
        "намаза и Кыблы, а также локальные напоминания.",
    )
    add_text(
        doc,
        "Цель работы — сделать эти функции удобными и устойчивыми к сетевым и "
        "платформенным ошибкам. Для видео была подключена загрузка в Cloudinary "
        "с отображением прогресса и получением метаданных. Для религиозного "
        "раздела были подключены координаты пользователя, библиотека расчёта "
        "намазов, компас и локальные уведомления.",
    )
    add_text(
        doc,
        "Разработанные модули были встроены в существующий Flutter-проект без "
        "изменения Firebase Authentication и структуры Firestore. Проверка "
        "выполнялась для Android- и Web-версий приложения.",
    )


def add_stack_table(doc):
    add_table_caption(doc, 2, "Назначение основных технологий Irfan Academy")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Технология", "Роль в проекте", "Практический результат")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])

    rows = (
        (
            "Flutter / Dart",
            "клиентская логика и пользовательский интерфейс",
            "одна кодовая база экранов, сервисов и моделей для Android и Web",
        ),
        (
            "Firebase",
            "Authentication и Cloud Firestore",
            "вход пользователей, роли, профили и хранение учебных метаданных",
        ),
        (
            "Cloudinary",
            "внешнее видеохранилище и доставка файлов",
            "загрузка видео, получение secure_url, public_id, размера и длительности",
        ),
        (
            "Firebase Functions",
            "серверный слой для защищённых интеграций",
            "проверка Firebase-пользователя и подготовка временных URL без передачи секретов клиенту",
        ),
        (
            "GitHub",
            "распределённый контроль версий",
            "история изменений, совместная работа и восстановление предыдущих версий",
        ),
        (
            "Android / Web",
            "целевые платформы демонстрационной версии",
            "проверка мобильного сценария и работы приложения в браузере",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value

    widths = (Cm(3.5), Cm(5), Cm(7))
    for row_index, row in enumerate(table.rows):
        prevent_row_split(row)
        for index, cell in enumerate(row.cells):
            cell.width = widths[index]
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.first_line_indent = Cm(0)
                paragraph.paragraph_format.line_spacing = 1.0
                paragraph.alignment = (
                    WD_ALIGN_PARAGRAPH.CENTER
                    if index == 0
                    else WD_ALIGN_PARAGRAPH.LEFT
                )
                for run in paragraph.runs:
                    set_font(run, 12, row_index == 0)


def add_technology_table(doc):
    add_table_caption(
        doc,
        3,
        "Библиотеки, использованные в индивидуальной части проекта",
    )
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Инструмент", "Версия", "Назначение")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])

    rows = (
        ("Flutter и Dart", "Dart 3.11.5", "разработка общей кодовой базы для Android и Web"),
        ("Cloudinary Upload API", "Web API", "хранение и получение сетевого адреса видео"),
        ("image_picker", "1.2.3", "выбор видеофайла на устройстве пользователя"),
        ("http", "1.6.0", "потоковая и частичная отправка видеофайлов"),
        ("video_player", "2.14.0", "воспроизведение видео по сетевому адресу"),
        ("geolocator", "14.0.3", "получение координат и обработка разрешений"),
        ("adhan", "2.0.0+1", "расчёт времени намаза и направления Кыблы"),
        ("flutter_compass", "0.8.1", "получение направления устройства"),
        (
            "flutter_local_notifications",
            "22.0.1",
            "локальные напоминания на поддерживаемых платформах",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value

    widths = (Cm(4.2), Cm(2.6), Cm(8.7))
    for row_index, row in enumerate(table.rows):
        prevent_row_split(row)
        for index, cell in enumerate(row.cells):
            cell.width = widths[index]
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.first_line_indent = Cm(0)
                paragraph.paragraph_format.line_spacing = 1.0
                paragraph.alignment = (
                    WD_ALIGN_PARAGRAPH.CENTER
                    if index in (0, 1)
                    else WD_ALIGN_PARAGRAPH.LEFT
                )
                for run in paragraph.runs:
                    set_font(run, 12, row_index == 0)


def add_chapter_one(doc):
    doc.add_heading(
        "1 АНАЛИЗ ИНДИВИДУАЛЬНОЙ ЗАДАЧИ И СРЕДСТВ РАЗРАБОТКИ",
        level=1,
    )

    doc.add_heading("1.1 Назначение разрабатываемых модулей", level=2)
    add_text(
        doc,
        "Irfan Academy представляет собой образовательное приложение на "
        "Flutter, использующее единую кодовую базу для мобильной и Web-версии. "
        "Приложение объединяет учебные материалы и религиозные функции. В "
        "рамках индивидуального задания рассматривались только компоненты, "
        "связанные с видеоуроками, геолокацией, временем намаза, направлением "
        "Кыблы и локальными уведомлениями.",
    )
    add_text(
        doc,
        "Мультимедийный модуль предназначен для выбора видео на устройстве, "
        "его отправки во внешнее хранилище, получения технических метаданных "
        "и последующего воспроизведения по защищённому HTTPS-адресу. В базу "
        "данных при этом должны передаваться только сведения о видео, а не "
        "сам бинарный файл. Такой подход предотвращает чрезмерное потребление "
        "памяти приложения и не создаёт избыточную нагрузку на Firestore.",
    )
    add_text(
        doc,
        "Религиозный модуль предназначен для получения координат пользователя, "
        "формирования расписания намазов с ханафитским временем Асра, выбора "
        "следующего намаза и вычисления направления на Каабу. Локальные "
        "напоминания дополняют расписание, но включаются только там, где "
        "соответствующий платформенный API поддерживается.",
    )

    doc.add_heading("1.2 Границы ответственности участника", level=2)
    add_text(
        doc,
        "Для исключения пересечения обязанностей команды была определена "
        "отдельная зона ответственности. Третий участник разрабатывал и "
        "проверял следующие компоненты:",
    )
    add_list(
        doc,
        (
            "сервис загрузки видео во внешнее хранилище;",
            "сценарий выбора файла и отображения состояния загрузки;",
            "сетевой видеоплеер и обработку его состояний;",
            "сервис получения координат пользователя;",
            "расчёт расписания намазов и следующего намаза;",
            "виджет определения направления Кыблы;",
            "локальные напоминания о предстоящих намазах;",
            "проверку перечисленных функций в Android- и Web-версиях.",
        ),
    )
    add_text(
        doc,
        "Сохранение учебных метаданных выполняется через существующий слой "
        "проекта. Изменение Firebase Authentication, проектирование коллекций "
        "Firestore, управление ролями и разработка остальных функций "
        "административной панели в индивидуальную задачу не включались.",
    )

    doc.add_heading("1.3 Требования к индивидуальной части проекта", level=2)
    add_text(
        doc,
        "На основании выявленных проблем были сформулированы функциональные "
        "требования к мультимедийному модулю:",
    )
    add_list(
        doc,
        (
            "выбор видеофайла непосредственно с устройства без ручного ввода ссылки;",
            "автоматический запуск загрузки после подтверждения выбора;",
            "отображение процента передачи, возможность отмены и повторной попытки;",
            "поддержка крупных файлов без чтения всего содержимого в оперативную память;",
            "автоматическое получение размера, формата, адреса и продолжительности видео;",
            "реальное воспроизведение с обработкой загрузки, паузы и ошибки ресурса.",
        ),
    )
    add_text(
        doc,
        "К религиозному модулю предъявлялись следующие требования:",
    )
    add_list(
        doc,
        (
            "запрашивать геолокацию только после проверки системного разрешения;",
            "не блокировать экран при отказе пользователя или недоступности датчика;",
            "использовать резервные координаты Бишкека при невозможности определить местоположение;",
            "корректно определять следующий намаз, включая переход к Фаджру следующего дня;",
            "рассчитывать Кыблу по тем же координатам, что и расписание;",
            "не вызывать неподдерживаемое планирование уведомлений в браузере.",
        ),
    )
    add_text(
        doc,
        "К нефункциональным требованиям были отнесены устойчивость к "
        "нестабильному соединению, понятные сообщения об ошибках, освобождение "
        "ресурсов видеоплеера, отсутствие секретных ключей в пользовательском "
        "интерфейсе и сохранение работоспособности существующих Firebase-модулей.",
    )

    doc.add_heading("1.4 Технологический стек проекта", level=2)
    add_text(
        doc,
        "Технологический стек Irfan Academy включает клиентскую платформу, "
        "облачные сервисы, внешнее видеохранилище, серверный интеграционный "
        "слой, систему контроля версий и целевые платформы. Их обобщённое "
        "назначение приведено в таблице 2.",
    )
    add_stack_table(doc)

    doc.add_heading("1.4.1 Flutter и Dart", level=3)
    add_text(
        doc,
        "Flutter является основой клиентской части Irfan Academy. Он формирует "
        "экраны, диалоговые окна, списки уроков, индикатор загрузки, элементы "
        "управления видеоплеером и интерфейс религиозных модулей. Виджеты "
        "Flutter позволяют использовать одну структуру интерфейса на Android "
        "и в браузере, сохраняя единое визуальное поведение приложения.",
    )
    add_text(
        doc,
        "Язык Dart используется для моделей данных, сервисов и асинхронных "
        "операций. Конструкции Future и Stream обеспечивают ожидание сетевых "
        "ответов, наблюдение за изменениями Firestore, обновление прогресса "
        "загрузки и управление жизненным циклом видеоплеера. Для проекта это "
        "означает, что клиентская логика и пользовательский интерфейс "
        "разрабатываются в одной кодовой базе.",
    )

    doc.add_heading("1.4.2 Firebase", level=3)
    add_text(
        doc,
        "Firebase используется как основная облачная платформа приложения. "
        "Firebase Authentication выполняет регистрацию, вход и выход "
        "пользователей по электронной почте и паролю. Полученный уникальный "
        "идентификатор пользователя связывает учётную запись с профилем и "
        "персональными данными в базе.",
    )
    add_text(
        doc,
        "Cloud Firestore хранит профили, роли, учебные записи, задания, "
        "расписание, уведомления и метаданные видеоуроков. Сам видеофайл в "
        "Firestore не передаётся: в коллекции videoLessons сохраняются только "
        "название, номер урока, продолжительность, размер, тип содержимого, "
        "Cloudinary public_id и сетевой адрес. Потоковые запросы Firestore "
        "позволяют интерфейсу автоматически отображать изменения данных.",
    )

    doc.add_heading("1.4.3 Cloudinary", level=3)
    add_text(
        doc,
        "Cloudinary выполняет хранение и доставку видеоуроков в текущей "
        "демонстрационной версии. После передачи файла сервис возвращает "
        "secure_url для воспроизведения, public_id для идентификации ресурса, "
        "размер, формат и продолжительность. Благодаря этому технические "
        "характеристики не вводятся администратором вручную.",
    )
    add_text(
        doc,
        "Файл передаётся через Upload API. Небольшие и средние видео "
        "отправляются потоком, а крупные разбиваются на части. Полученный "
        "HTTPS-адрес используется пакетом video_player. В проекте применён "
        "unsigned upload preset без размещения Cloudinary API Secret в клиенте.",
    )

    doc.add_heading("1.4.4 Firebase Functions", level=3)
    add_text(
        doc,
        "Firebase Functions предназначены для операций, которые нельзя "
        "безопасно выполнять во Flutter-приложении. В каталоге functions "
        "подготовлены вызываемые серверные функции для интеграции с объектным "
        "хранилищем: начало и завершение multipart-загрузки, подпись отдельных "
        "частей, получение временной ссылки, чтение технических сведений и "
        "удаление объекта. Перед выполнением сервер проверяет Firebase "
        "Authentication, а для изменяющих операций дополнительно проверяется "
        "роль администратора в Firestore.",
    )
    add_text(
        doc,
        "Секретные ключи в этой схеме определяются только на стороне Functions "
        "и не включаются в APK или Web-сборку. В демонстрационной версии видео "
        "загружается напрямую в Cloudinary, поэтому подготовленные функции R2 "
        "не участвуют в рабочем потоке загрузки.",
    )

    doc.add_heading("1.4.5 GitHub", level=3)
    add_text(
        doc,
        "GitHub используется как удалённое хранилище исходного кода и основа "
        "командного контроля версий. Репозиторий фиксирует изменения в виде "
        "коммитов, позволяет сопоставлять выполненную работу с конкретными "
        "файлами и возвращаться к стабильной версии при обнаружении ошибки. "
        "Для команды это обеспечивает единую историю проекта и уменьшает риск "
        "потери или случайной перезаписи результатов других участников.",
    )

    doc.add_heading("1.4.6 Android и Web", level=3)
    add_text(
        doc,
        "Android и Web являются целевыми платформами демонстрационной версии. "
        "На Android доступны системная геолокация, аппаратный компас и "
        "планирование локальных уведомлений. В Web-версии выбор файла и "
        "воспроизведение выполняются средствами браузера, а сетевые запросы "
        "дополнительно зависят от политики CORS.",
    )
    add_text(
        doc,
        "Единая кодовая база не означает полного равенства платформенных API. "
        "Поэтому перед вызовом локальных уведомлений выполняется проверка "
        "kIsWeb, при отсутствии датчика компаса интерфейс показывает безопасное "
        "состояние, а при недоступной геолокации используются резервные "
        "координаты. Такой подход позволяет сохранить общий интерфейс, но "
        "учесть реальные ограничения каждой платформы.",
    )

    doc.add_heading("1.5 Вспомогательные библиотеки", level=2)
    add_text(
        doc,
        "Кроме основных технологий, индивидуальная часть использует набор "
        "специализированных Flutter-пакетов. В таблице 3 перечислены только "
        "библиотеки, которые непосредственно участвуют в загрузке и "
        "воспроизведении видео либо в работе религиозных модулей.",
    )
    add_technology_table(doc)
    add_text(
        doc,
        "Выбранное сочетание библиотек разделяет ответственность между "
        "компонентами: сетевой сервис выполняет отправку видео, контроллер "
        "видеоплеера отвечает за воспроизведение, а геолокация и религиозные "
        "вычисления изолированы от пользовательского интерфейса. Это упрощает "
        "обработку ошибок и последующую проверку каждого модуля.",
    )

    doc.add_heading("1.6 Структура разработанных компонентов", level=2)
    add_text(
        doc,
        "Основная логика индивидуальной работы размещена в сервисах "
        "cloudinary_video_service.dart, prayer_service.dart и "
        "notification_service.dart. Пользовательские компоненты сетевого "
        "плеера и компаса находятся в video_player_modal.dart и "
        "qibla_compass.dart. Точки подключения расположены в экране "
        "административной загрузки видео и экране расписания намазов.",
    )
    add_text(
        doc,
        "Структура файлов индивидуальных модулей представлена на рисунке 1.",
    )
    add_figure_placeholder(
        doc,
        1,
        "Структура файлов мультимедийных и религиозных модулей Irfan Academy",
    )


def add_video_storage_table(doc):
    add_table_caption(doc, 4, "Распределение видеоданных между компонентами")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Компонент", "Обрабатываемые данные", "Назначение")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "Flutter-приложение",
            "выбранный XFile, прогресс и временное состояние формы",
            "управление выбором, отправкой и отображением результата",
        ),
        (
            "Cloudinary",
            "бинарный видеофайл и его технические характеристики",
            "постоянное хранение файла и доставка по HTTPS",
        ),
        (
            "Cloud Firestore",
            "название урока, URL, public_id, размер, формат и длительность",
            "хранение только метаданных для списка видеоуроков",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(3.8), Cm(5.5), Cm(6.2)))


def add_video_metadata_table(doc):
    add_table_caption(doc, 5, "Метаданные результата загрузки видео")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Поле", "Источник", "Использование в приложении")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        ("secureUrl", "secure_url", "сетевой адрес для видеоплеера"),
        ("publicId", "public_id", "идентификатор файла в Cloudinary"),
        ("fileName", "XFile.name", "исходное имя выбранного файла"),
        ("fileSize", "bytes", "размер файла в байтах"),
        ("contentType", "format", "тип содержимого вида video/mp4"),
        ("durationSeconds", "duration", "продолжительность, округлённая до секунд"),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(3.8), Cm(3.5), Cm(8.2)))


def add_video_error_table(doc):
    add_table_caption(doc, 6, "Обработка ошибок видеомодуля")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Ситуация", "Реакция программы", "Результат для пользователя")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "выбран пустой файл",
            "операция прекращается до сетевого запроса",
            "отображается сообщение о некорректном файле",
        ),
        (
            "ответ Cloudinary 4xx",
            "ошибка API разбирается и не повторяется автоматически",
            "можно изменить файл или настройки и повторить загрузку",
        ),
        (
            "временный сбой части",
            "выполняется до четырёх попыток с увеличением задержки",
            "загрузка может продолжиться без повторного выбора файла",
        ),
        (
            "отмена пользователем",
            "публикация урока не выполняется; цикл частей останавливается при проверке флага",
            "диалог закрывается без создания записи видеоурока",
        ),
        (
            "некорректный или недоступный URL",
            "контроллер освобождается и сохраняется состояние ошибки",
            "показывается понятное сообщение и кнопка повторной попытки",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(4.1), Cm(6), Cm(5.4)))


def _format_three_column_table(table, widths):
    for row_index, row in enumerate(table.rows):
        prevent_row_split(row)
        for index, cell in enumerate(row.cells):
            cell.width = widths[index]
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.first_line_indent = Cm(0)
                paragraph.paragraph_format.line_spacing = 1.0
                paragraph.alignment = (
                    WD_ALIGN_PARAGRAPH.CENTER
                    if row_index == 0
                    else WD_ALIGN_PARAGRAPH.LEFT
                )
                for run in paragraph.runs:
                    set_font(run, 12, row_index == 0)


def add_chapter_two(doc):
    doc.add_heading(
        "2 РАЗРАБОТКА МОДУЛЯ ЗАГРУЗКИ И ВОСПРОИЗВЕДЕНИЯ ВИДЕО",
        level=1,
    )

    doc.add_heading("2.1 Выбор архитектуры хранения видео", level=2)
    add_text(
        doc,
        "Видеоуроки продолжительностью от 30 до 120 минут могут занимать "
        "сотни мегабайт. Передача такого файла через документ Firestore "
        "технически и экономически нецелесообразна: Firestore предназначен "
        "для структурированных данных, а не для крупных бинарных объектов. "
        "Поэтому файл и его описание были разделены между специализированным "
        "хранилищем и базой метаданных.",
    )
    add_text(
        doc,
        "На этапе анализа рассматривались Firebase Storage, Cloudflare R2 и "
        "Cloudinary. Прямая загрузка в Firebase Storage из Web-версии "
        "столкнулась с ограничением CORS. Для Cloudflare R2 была подготовлена "
        "защищённая схема через Firebase Functions и временные подписанные URL, "
        "но серверные функции не развёртывались. В рабочей демонстрационной "
        "версии использован Cloudinary с отдельным unsigned upload preset.",
    )
    add_text(
        doc,
        "Распределение информации между Flutter, Cloudinary и Firestore "
        "представлено в таблице 4. Такая схема сохраняет существующую "
        "Firebase-архитектуру: Authentication продолжает определять "
        "пользователя, Firestore хранит учебные записи, а Cloudinary отвечает "
        "только за видеофайл.",
    )
    add_video_storage_table(doc)
    add_text(
        doc,
        "Поток загрузки и воспроизведения видео показан на рисунке 2.",
    )
    add_figure_placeholder(
        doc,
        2,
        "Поток загрузки и воспроизведения видеоурока",
    )

    doc.add_heading("2.2 Выбор файла и автоматический запуск загрузки", level=2)
    add_text(
        doc,
        "В административной панели пользователь нажимает кнопку выбора видео. "
        "Метод ImagePicker.pickVideo открывает системный выбор файла и "
        "возвращает объект XFile. Отмена системного окна не считается ошибкой: "
        "форма остаётся в исходном состоянии. Если файл выбран, сразу "
        "открывается диалог загрузки, который нельзя случайно закрыть нажатием "
        "за его пределами.",
    )
    add_text(
        doc,
        "Ручные поля URL и продолжительности исключены. После успешной передачи "
        "администратор вводит только номер, название и необязательное описание "
        "урока. Размер, формат, длительность, public_id и адрес поступают из "
        "результата Cloudinary. Это сокращает количество действий и исключает "
        "ошибки ручного ввода технических данных.",
    )
    add_text(
        doc,
        "Экран выбора видео показан на рисунке 3.",
    )
    add_figure_placeholder(
        doc,
        3,
        "Выбор видеофайла в административной панели",
    )

    doc.add_heading("2.3 Потоковая и частичная передача файла", level=2)
    add_text(
        doc,
        "Перед началом передачи сервис получает размер файла методом length. "
        "Нулевой размер считается ошибкой. Файлы размером до 95 МБ передаются "
        "потоковым MultipartRequest: содержимое читается через openRead и не "
        "загружается целиком в оперативную память. Специальный класс "
        "_ProgressMultipartRequest подсчитывает фактически отправленные байты "
        "и передаёт отношение отправленного объёма к общему размеру в интерфейс.",
    )
    add_text(
        doc,
        "Для файлов больше 95 МБ используется частичная загрузка. Файл "
        "последовательно читается диапазонами по 8 МБ. Каждая часть получает "
        "общий X-Unique-Upload-Id и заголовок Content-Range, содержащий начало, "
        "конец и полный размер. В памяти одновременно находится только "
        "текущая часть, поэтому размер используемой памяти не растёт вместе с "
        "размером видео.",
    )
    add_text(
        doc,
        "При временной ошибке отправка части повторяется до четырёх раз. Между "
        "попытками используются задержки 1, 2 и 4 секунды. Клиентские ответы "
        "Cloudinary с кодами 4xx не повторяются автоматически, поскольку они "
        "обычно означают неверный формат, ограничение preset или другую ошибку "
        "запроса. После каждой успешно принятой части обновляется общий процент.",
    )
    add_text(
        doc,
        "Отображение прогресса загрузки показано на рисунке 4.",
    )
    add_figure_placeholder(
        doc,
        4,
        "Отображение прогресса загрузки большого видео",
    )

    doc.add_heading("2.4 Обработка результата и сохранение метаданных", level=2)
    add_text(
        doc,
        "После завершения Upload API возвращает ответ JSON. Сервис проверяет "
        "наличие secure_url и public_id: без этих значений операция не считается "
        "успешной. Остальные сведения преобразуются в объект "
        "CloudinaryUploadResult. Соответствие полей приведено в таблице 5.",
    )
    add_video_metadata_table(doc)
    add_text(
        doc,
        "После заполнения учебных сведений AdminService создаёт документ в "
        "коллекции videoLessons. Вместе с техническими полями сохраняются "
        "номер урока, название, описание, строковое представление длительности, "
        "признак storageProvider со значением cloudinary и серверная дата "
        "создания. Сам файл остаётся в Cloudinary.",
    )
    add_text(
        doc,
        "После успешного создания записи существующий сервис формирует "
        "Firestore-уведомление «Новый видеоурок» для учеников. Эта операция "
        "относится к общей логике административной панели; видеомодуль передаёт "
        "ей готовые технические метаданные.",
    )
    add_text(
        doc,
        "Результат сохранения видеоурока показан на рисунке 5.",
    )
    add_figure_placeholder(
        doc,
        5,
        "Результат загрузки и сохранения метаданных видеоурока",
    )

    doc.add_heading("2.5 Реальное воспроизведение видео", level=2)
    add_text(
        doc,
        "Первоначальная имитация воспроизведения таймером была заменена "
        "VideoPlayerController.networkUrl. Перед созданием контроллера адрес "
        "очищается и проверяется как URI со схемой. Контроллер асинхронно "
        "инициализирует сетевой ресурс и запускает воспроизведение только после "
        "получения сведений о длительности и соотношении сторон.",
    )
    add_text(
        doc,
        "Плеер поддерживает запуск и паузу, перемотку ползунком, переход между "
        "видеоуроками, повтор и скорости 0,75; 1; 1,25; 1,5 и 2. Отдельно "
        "отображаются инициализация, буферизация и ошибка открытия. Если ресурс "
        "не удалось получить, пользователь видит объяснение и кнопку "
        "повторного запуска.",
    )
    add_text(
        doc,
        "При смене урока предыдущий контроллер и его listener освобождаются. "
        "Счётчик поколения исключает применение результата устаревшей "
        "асинхронной операции после быстрого переключения или закрытия окна. "
        "Проверка mounted предотвращает обновление удалённого виджета.",
    )
    add_text(
        doc,
        "Работа сетевого видеоплеера показана на рисунке 6.",
    )
    add_figure_placeholder(
        doc,
        6,
        "Воспроизведение сетевого видеоурока",
    )

    doc.add_heading("2.6 Обработка ошибок и ограничения", level=2)
    add_text(
        doc,
        "Основные ошибочные ситуации и реакция программы систематизированы в "
        "таблице 6. Сообщения выводятся на русском языке и предлагают повторить "
        "операцию там, где это имеет практический смысл.",
    )
    add_video_error_table(doc)
    add_text(
        doc,
        "Флаг отмены проверяется перед загрузкой, между частями и перед "
        "повторными попытками. Поэтому частичная загрузка прекращается на "
        "ближайшей границе части и запись урока не публикуется. Текущий прямой "
        "HTTP-запрос не является возобновляемой сессией и после закрытия "
        "диалога может завершить передачу на транспортном уровне.",
    )
    add_text(
        doc,
        "В клиентском коде отсутствуют Cloudinary API Secret и секретный ключ. "
        "Использованный unsigned preset и полученный URL относятся к "
        "демонстрационному режиму. Удаление урока из административной панели "
        "удаляет документ Firestore, но не объект Cloudinary.",
    )


def add_religious_components_table(doc):
    add_table_caption(doc, 7, "Состав религиозного модуля")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Компонент", "Основная функция", "Результат")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "PrayerService",
            "геолокация, вычисление намазов и Кыблы",
            "объект PrayerSchedule для выбранных координат",
        ),
        (
            "PrayerSchedule",
            "объединение координат, направления и списка времён",
            "единая модель данных экрана",
        ),
        (
            "PrayerTime",
            "хранение названия, времени и состояния намаза",
            "строка расписания с визуальным статусом",
        ),
        (
            "PrayerScreen",
            "загрузка и периодическое обновление расписания",
            "пользовательский экран намазов",
        ),
        (
            "QiblaCompass",
            "сопоставление Кыблы и курса устройства",
            "графический указатель направления",
        ),
        (
            "NotificationService",
            "планирование будущих напоминаний",
            "системные уведомления на поддерживаемой платформе",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(4.1), Cm(6), Cm(5.4)))


def add_geolocation_scenarios_table(doc):
    add_table_caption(doc, 8, "Сценарии получения местоположения")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Условие", "Действие сервиса", "Используемые координаты")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "служба включена, разрешение выдано",
            "запрос позиции с высокой точностью",
            "фактические координаты устройства",
        ),
        (
            "разрешение ещё не запрашивалось",
            "показ системного запроса разрешения",
            "координаты устройства при согласии",
        ),
        (
            "служба выключена или доступ запрещён",
            "перехват исключения и резервный сценарий",
            "Бишкек: 42,8746; 74,5698",
        ),
        (
            "ответ не получен за пять секунд",
            "завершение ожидания по тайм-ауту",
            "Бишкек: 42,8746; 74,5698",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(4.7), Cm(6), Cm(4.8)))


def add_prayer_status_table(doc):
    add_table_caption(doc, 9, "Состояния элементов расписания намазов")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Значение PrayerStatus", "Назначение", "Отображение")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        ("done", "время уже наступило", "завершённый пункт"),
        ("next", "ближайший будущий обязательный намаз", "акцентная строка"),
        ("upcoming", "последующий обязательный намаз", "обычная строка"),
        ("faint", "вспомогательное время Восход", "приглушённая строка"),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(4.6), Cm(6.1), Cm(4.8)))


def add_notification_platform_table(doc):
    add_table_caption(doc, 10, "Особенности уведомлений на целевых платформах")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Платформа", "Поведение", "Причина")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "Android",
            "инициализация канала, запрос разрешений и планирование будущих намазов",
            "плагин поддерживает системное zonedSchedule",
        ),
        (
            "Web",
            "методы инициализации и планирования завершаются без вызова плагина",
            "zonedSchedule не поддерживается браузерной реализацией",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(3.2), Cm(7.3), Cm(5)))


def add_chapter_three(doc):
    doc.add_heading(
        "3 РАЗРАБОТКА ГЕОЛОКАЦИИ, РАСПИСАНИЯ НАМАЗОВ И НАПРАВЛЕНИЯ КЫБЛЫ",
        level=1,
    )

    doc.add_heading("3.1 Архитектура религиозного модуля", level=2)
    add_text(
        doc,
        "Религиозный модуль построен с разделением вычислительной логики, "
        "платформенных возможностей и пользовательского интерфейса. "
        "PrayerService получает координаты и формирует расписание, "
        "NotificationService отвечает за локальные напоминания, а PrayerScreen "
        "и QiblaCompass представляют результат пользователю. Назначение "
        "компонентов приведено в таблице 7.",
    )
    add_religious_components_table(doc)
    add_text(
        doc,
        "Общей моделью результата является PrayerSchedule. Она содержит "
        "широту, долготу, текстовую метку местоположения, абсолютное направление "
        "Кыблы и список PrayerTime. Благодаря этому экран получает согласованный "
        "набор данных из одного асинхронного запроса и не выполняет религиозные "
        "вычисления внутри виджетов.",
    )
    add_text(
        doc,
        "Взаимодействие компонентов показано на рисунке 7.",
    )
    add_figure_placeholder(
        doc,
        7,
        "Взаимодействие компонентов религиозного модуля",
    )

    doc.add_heading("3.2 Получение географических координат", level=2)
    add_text(
        doc,
        "Перед запросом позиции PrayerService проверяет состояние системной "
        "службы геолокации. Затем определяется текущее разрешение. Если доступ "
        "ещё не предоставлялся, приложение вызывает стандартный системный "
        "диалог. Состояния denied и deniedForever обрабатываются без повторного "
        "бесконечного запроса.",
    )
    add_text(
        doc,
        "При доступной геолокации Geolocator.getCurrentPosition запрашивает "
        "позицию с высокой точностью. Вся операция ограничена пятью секундами. "
        "Тайм-аут важен для интерфейса: экран не должен неопределённо долго "
        "ожидать GPS в помещении или при нестабильной работе браузера.",
    )
    add_text(
        doc,
        "При выключенной службе, отказе в разрешении, тайм-ауте или другой "
        "ошибке применяется резервное местоположение — Бишкек с координатами "
        "42,8746 северной широты и 74,5698 восточной долготы. Основные сценарии "
        "приведены в таблице 8.",
    )
    add_geolocation_scenarios_table(doc)
    add_text(
        doc,
        "Отображение местоположения показано на рисунке 8.",
    )
    add_figure_placeholder(
        doc,
        8,
        "Отображение местоположения в расписании намазов",
    )

    doc.add_heading("3.3 Расчёт расписания и следующего намаза", level=2)
    add_text(
        doc,
        "Расписание рассчитывается библиотекой adhan на основании координат и "
        "текущей календарной даты. В качестве метода вычисления выбран Muslim "
        "World League, а для времени Асра установлен Madhab.hanafi. Результат "
        "включает Фаджр, Восход, Зухр, Аср, Магриб и Иша. Перед выводом время "
        "преобразуется в локальный часовой пояс и форматируется как часы и минуты.",
    )
    add_text(
        doc,
        "Для каждого элемента определяется визуальное состояние. Восход "
        "помечается вспомогательным значением и не выбирается как следующий "
        "обязательный намаз. Назначение состояний приведено в таблице 9. Экран "
        "обновляет их один раз в минуту, поэтому выделение ближайшего намаза "
        "изменяется без полной перезагрузки приложения.",
    )
    add_prayer_status_table(doc)
    add_text(
        doc,
        "После Иша в расписании текущего дня не остаётся будущего обязательного "
        "намаза. Метод getNextPrayerForSchedule в этом случае отдельно "
        "рассчитывает Фаджр следующего дня по тем же координатам. Метод "
        "getTimeUntilNextPrayer использует полный DateTime, поэтому обратный "
        "отсчёт не становится отрицательным при переходе через полночь.",
    )
    add_text(
        doc,
        "Расписание и следующий намаз показаны на рисунке 9.",
    )
    add_figure_placeholder(
        doc,
        9,
        "Расписание, следующий намаз и обратный отсчёт",
    )

    doc.add_heading("3.4 Определение направления Кыблы", level=2)
    add_text(
        doc,
        "Абсолютное направление на Каабу вычисляется объектом Qibla из "
        "библиотеки adhan по тем же координатам, которые использованы для "
        "расписания. Это исключает расхождение между указанным городом и "
        "направлением. Полученный азимут передаётся в QiblaCompass.",
    )
    add_text(
        doc,
        "Flutter Compass формирует поток показаний heading — направления верхней "
        "части устройства относительно севера. Относительный угол указателя "
        "вычисляется как разность абсолютного азимута Кыблы и текущего курса "
        "телефона, после чего нормализуется в диапазон от 0 до 360 градусов. "
        "Графический указатель поворачивается к золотой метке и сопровождается "
        "обозначением одной из восьми сторон света.",
    )
    add_text(
        doc,
        "Если браузер или устройство не предоставляет данные датчика, виджет "
        "остаётся работоспособным: отображается абсолютный азимут и сообщение о "
        "недоступности либо калибровке компаса. Работа указателя показана на "
        "рисунке 10.",
    )
    add_figure_placeholder(
        doc,
        10,
        "Определение направления Кыблы по данным компаса",
    )

    doc.add_heading("3.5 Планирование локальных напоминаний", level=2)
    add_text(
        doc,
        "NotificationService реализован как единый экземпляр сервиса. При "
        "первой инициализации загружается база часовых поясов, определяется "
        "локальная зона устройства и настраивается плагин уведомлений. Если "
        "идентификатор зоны получить не удалось, используется UTC.",
    )
    add_text(
        doc,
        "Перед созданием нового расписания ранее запланированные уведомления "
        "удаляются. Затем сервис перебирает будущие обязательные намазы и "
        "создаёт напоминание с названием и временем. Сначала используется "
        "режим exactAllowWhileIdle. Если точное планирование не разрешено "
        "системой, выполняется повтор в режиме inexactAllowWhileIdle.",
    )
    add_text(
        doc,
        "Изначально вызов zonedSchedule в браузере приводил к исключению "
        "Unsupported operation. Для устранения ошибки в initialize и "
        "schedulePrayerNotifications добавлена ранняя проверка kIsWeb. Различие "
        "поведения целевых платформ отражено в таблице 10.",
    )
    add_notification_platform_table(doc)
    add_text(
        doc,
        "Локальное Android-уведомление показано на рисунке 11.",
    )
    add_figure_placeholder(
        doc,
        11,
        "Локальное напоминание о наступлении намаза на Android",
    )

    doc.add_heading("3.6 Устойчивость интерфейса на Android и Web", level=2)
    add_text(
        doc,
        "PrayerScreen использует FutureBuilder и отображает отдельные состояния "
        "ожидания, результата и ошибки. Пользователь может повторить загрузку "
        "расписания. После получения данных экран запускает формирование "
        "локальных напоминаний, а периодический Timer обновляет статусы намазов "
        "раз в минуту. При закрытии экрана Timer отменяется.",
    )
    add_text(
        doc,
        "За счёт резервной геолокации экран сохраняет основную функциональность "
        "при отказе в разрешении. Отсутствие компаса не скрывает рассчитанный "
        "азимут. Web-проверка предотвращает обращение к неподдерживаемому API "
        "уведомлений. Эти решения позволяют использовать общий интерфейс без "
        "маскировки реальных различий между мобильной и браузерной платформами.",
    )
    add_text(
        doc,
        "Работа Web-версии без ошибки zonedSchedule показана на рисунке 12.",
    )
    add_figure_placeholder(
        doc,
        12,
        "Работа религиозного модуля в Web-версии без платформенной ошибки",
    )


def add_check_results_table(doc):
    add_table_caption(doc, 11, "Результаты автоматизированных проверок проекта")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Команда", "Назначение", "Результат 07.09.2026")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "flutter analyze",
            "статический анализ Dart-кода и правил flutter_lints",
            "замечаний не обнаружено; 135 секунд",
        ),
        (
            "flutter test",
            "запуск существующего набора модульных и widget-тестов",
            "2 теста из 2 пройдены; около 2 секунд",
        ),
        (
            "npm run check",
            "проверка синтаксиса functions/index.js командой node --check",
            "завершено успешно, синтаксических ошибок нет",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(4), Cm(6.1), Cm(5.4)))


def add_automated_tests_table(doc):
    add_table_caption(doc, 12, "Существующие автоматизированные тесты Flutter")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Код", "Проверяемое поведение", "Фактический результат")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "AT-01",
            "роли admin и «Администратор» распознаются как административные, роль «Ученик» — нет",
            "пройден",
        ),
        (
            "AT-02",
            "SplashScreen содержит название, кнопку начала обучения и подпись местоположения",
            "пройден",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(2.2), Cm(10.5), Cm(2.8)))


def add_video_test_cases_table(doc):
    add_table_caption(doc, 13, "Проверенные сценарии видеомодуля")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Код", "Действия", "Полученный результат")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "VT-01",
            "открыть системный выбор видео и отменить операцию",
            "форма остаётся открытой, загрузка и запись не создаются",
        ),
        (
            "VT-02",
            "выбрать корректный MP4 размером меньше 95 МБ",
            "запускается потоковая загрузка, процент достигает 100",
        ),
        (
            "VT-03",
            "загрузить видео размером больше 95 МБ",
            "файл передаётся частями по 8 МБ без загрузки целиком в память",
        ),
        (
            "VT-04",
            "временно прервать соединение при отправке части",
            "выполняются повторные попытки с увеличением задержки",
        ),
        (
            "VT-05",
            "отменить частичную загрузку",
            "цикл прекращается на ближайшей проверке, урок не публикуется",
        ),
        (
            "VT-06",
            "завершить загрузку и сохранить номер, название и описание",
            "Firestore получает метаданные, но не бинарное содержимое файла",
        ),
        (
            "VT-07",
            "открыть сохранённый урок и использовать паузу, перемотку и скорость",
            "видео воспроизводится, элементы управления изменяют состояние контроллера",
        ),
        (
            "VT-08",
            "передать недоступный сетевой адрес и нажать «Повторить»",
            "показывается сообщение об ошибке без аварийного закрытия интерфейса",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(2.1), Cm(6.7), Cm(6.7)))


def add_prayer_test_cases_table(doc):
    add_table_caption(doc, 14, "Проверенные сценарии религиозного модуля")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Код", "Условие проверки", "Полученный результат")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "PT-01",
            "геолокация включена и разрешение выдано",
            "расписание строится по фактическим координатам",
        ),
        (
            "PT-02",
            "геолокация выключена либо доступ запрещён",
            "за пять секунд выбираются резервные координаты Бишкека",
        ),
        (
            "PT-03",
            "открыть расписание до наступления ближайшего намаза",
            "один обязательный намаз получает состояние next",
        ),
        (
            "PT-04",
            "определить следующий намаз после Иша",
            "выбирается Фаджр следующего дня, отсчёт остаётся положительным",
        ),
        (
            "PT-05",
            "поворачивать устройство с доступным компасом",
            "указатель Кыблы изменяет относительное направление",
        ),
        (
            "PT-06",
            "открыть экран на устройстве без данных компаса",
            "отображаются абсолютный азимут и сообщение о датчике",
        ),
        (
            "PT-07",
            "разрешить уведомления на Android",
            "будущие обязательные намазы планируются локально",
        ),
        (
            "PT-08",
            "открыть модуль в Web-версии",
            "zonedSchedule не вызывается, экран работает без исключения",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(2.1), Cm(6.7), Cm(6.7)))


def add_fixed_defects_table(doc):
    add_table_caption(doc, 15, "Дефекты, устранённые в индивидуальных модулях")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Дефект", "Причина", "Внесённое изменение")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "исключение zonedSchedule в браузере",
            "мобильный API вызывался в Web-реализации",
            "добавлена ранняя проверка kIsWeb",
        ),
        (
            "видеоплеер имитировал воспроизведение",
            "использовался локальный таймер вместо медиаконтроллера",
            "подключён VideoPlayerController.networkUrl",
        ),
        (
            "URL и длительность вводились вручную",
            "технические данные не извлекались из ответа хранилища",
            "поля заполняются по ответу Cloudinary",
        ),
        (
            "риск большого потребления памяти",
            "крупный файл мог обрабатываться как единый массив",
            "добавлены потоковая передача и части по 8 МБ",
        ),
        (
            "после Иша выбирался прошедший Фаджр",
            "поиск выполнялся только в расписании текущего дня",
            "добавлен расчёт Фаджра следующего дня",
        ),
        (
            "экран зависел от GPS и компаса",
            "не учитывались отказ в разрешении и отсутствие датчика",
            "добавлены резервные координаты и безопасное состояние компаса",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(4.7), Cm(5.3), Cm(5.5)))


def add_chapter_four(doc):
    doc.add_heading(
        "4 ТЕСТИРОВАНИЕ И КОНТРОЛЬ КАЧЕСТВА РАЗРАБОТАННЫХ МОДУЛЕЙ",
        level=1,
    )

    doc.add_heading("4.1 Цель и уровни проверки", level=2)
    add_text(
        doc,
        "Цель тестирования заключалась в подтверждении работоспособности "
        "индивидуальных модулей и отсутствии очевидной регрессии в общей "
        "кодовой базе. Проверка разделена на статический анализ, "
        "автоматизированные тесты, интеграционные сценарии с внешними сервисами "
        "и платформенные проверки на Android и Web.",
    )
    add_text(
        doc,
        "Разделение использовалось потому, что сетевое видео, геолокация, "
        "компас и системные уведомления зависят от реального окружения. "
        "Обычный widget-тест не подтверждает скорость передачи большого файла, "
        "доступность Cloudinary, точность GPS или доставку Android-уведомления. "
        "Автоматические и ручные проверки поэтому рассматриваются как "
        "дополняющие, а не взаимозаменяемые этапы.",
    )

    doc.add_heading("4.2 Среда и результаты автоматических проверок", level=2)
    add_text(
        doc,
        "Проверка выполнена 7 сентября 2026 года на Windows с Flutter 3.44.9 "
        "stable, Dart 3.12.2 и Node.js. Команды запускались из корневого "
        "каталога проекта. Полученные результаты приведены в таблице 11.",
    )
    add_check_results_table(doc)
    add_text(
        doc,
        "Статический анализ завершён сообщением No issues found. Это "
        "подтверждает соответствие текущего Dart-кода подключённым правилам "
        "flutter_lints. Результат команды показан на рисунке 13.",
    )
    add_figure_placeholder(
        doc,
        13,
        "Результат статического анализа Flutter",
    )

    doc.add_heading("4.3 Существующее автоматизированное покрытие", level=2)
    add_text(
        doc,
        "В проекте присутствуют два автоматизированных теста, перечисленные в "
        "таблице 12. Оба завершились успешно. Первый проверяет интерпретацию "
        "административных ролей, второй — наличие основных элементов стартового "
        "экрана.",
    )
    add_automated_tests_table(doc)
    add_text(
        doc,
        "Эти тесты выполняют базовую регрессионную функцию, но напрямую не "
        "проверяют CloudinaryVideoService, PrayerService, NotificationService, "
        "QiblaCompass и VideoPlayerController. Результат All tests passed "
        "показан на рисунке 14.",
    )
    add_figure_placeholder(
        doc,
        14,
        "Успешное выполнение автоматизированных тестов Flutter",
    )

    doc.add_heading("4.4 Проверка модуля видео", level=2)
    add_text(
        doc,
        "Видеомодуль проверялся по сценариям, охватывающим "
        "выбор файла, два режима загрузки, временный сетевой сбой, отмену, "
        "сохранение метаданных и воспроизведение. Сценарии представлены в "
        "таблице 13.",
    )
    add_video_test_cases_table(doc)

    doc.add_heading("4.5 Проверка религиозного модуля", level=2)
    add_text(
        doc,
        "Религиозные функции проверялись при доступной и отключённой "
        "геолокации, отсутствии компаса, переходе суток и запуске в браузере. "
        "Результаты приведены в таблице 14.",
    )
    add_prayer_test_cases_table(doc)

    doc.add_heading("4.6 Устранённые дефекты", level=2)
    add_text(
        doc,
        "В процессе разработки исправлялись ошибки, воспроизводившиеся в "
        "пользовательских сценариях или выявленные при анализе исходного кода. "
        "Причины и внесённые изменения приведены в таблице 15.",
    )
    add_fixed_defects_table(doc)
    add_text(
        doc,
        "После изменений повторно выполнены flutter analyze и flutter test. "
        "Обе команды завершились успешно, поэтому исправления не внесли "
        "обнаруживаемых статическим анализатором проблем и не нарушили два "
        "существующих автоматизированных сценария.",
    )


def add_results_table(doc):
    add_table_caption(doc, 16, "Итоги индивидуальной работы")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Направление", "Выполненная работа", "Полученный результат")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "Загрузка видео",
            "выбор файла, потоковая и частичная передача, прогресс и повторы",
            "видео загружается в Cloudinary, параметры определяются автоматически",
        ),
        (
            "Воспроизведение",
            "подключение VideoPlayerController.networkUrl и элементов управления",
            "вместо таймера используется настоящий сетевой видеоплеер",
        ),
        (
            "Расписание намазов",
            "геолокация, резервные координаты и расчёт библиотекой adhan",
            "отображаются времена намазов и ближайший намаз",
        ),
        (
            "Кыбла",
            "расчёт азимута и обработка показаний компаса",
            "указатель реагирует на направление устройства",
        ),
        (
            "Напоминания",
            "локальное планирование с отдельной обработкой Web",
            "Android получает напоминания, браузер не вызывает zonedSchedule",
        ),
        (
            "Контроль качества",
            "статический анализ, Flutter-тесты и проверка Functions",
            "анализ без замечаний, 2 теста пройдены, синтаксис Functions корректен",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(3.7), Cm(6.1), Cm(5.7)))


def add_chapter_five(doc):
    doc.add_heading("5 РЕЗУЛЬТАТЫ ИНДИВИДУАЛЬНОЙ РАБОТЫ", level=1)

    doc.add_heading("5.1 Результат разработки видеомодуля", level=2)
    add_text(
        doc,
        "В административной панели реализован выбор видео с устройства. "
        "Загрузка начинается автоматически и показывает прогресс. Крупные "
        "файлы передаются частями, а временно неудачные запросы повторяются. "
        "Cloudinary возвращает адрес, идентификатор, размер, формат и "
        "продолжительность видео.",
    )
    add_text(
        doc,
        "Полученные метаданные сохраняются в Firestore вместе с номером и "
        "названием урока. Сам файл хранится в Cloudinary. Видеоурок открывается "
        "в сетевом плеере с паузой, перемоткой, повтором и изменением скорости.",
    )

    doc.add_heading("5.2 Результат разработки религиозного модуля", level=2)
    add_text(
        doc,
        "PrayerService получает координаты пользователя и рассчитывает "
        "расписание по методу Muslim World League с ханафитским временем Асра. "
        "При недоступной геолокации используются координаты Бишкека. После Иша "
        "следующим временем становится Фаджр нового дня.",
    )
    add_text(
        doc,
        "Направление Кыблы связано с показаниями компаса. При отсутствии "
        "датчика сохраняется отображение абсолютного азимута. На Android "
        "создаются локальные напоминания, а Web-версия пропускает "
        "неподдерживаемый вызов zonedSchedule.",
    )

    doc.add_heading("5.3 Результат проверки", level=2)
    add_text(
        doc,
        "После внесённых изменений выполнены статический анализ Flutter, два "
        "автоматизированных теста и синтаксическая проверка Firebase Functions. "
        "Все три проверки завершились успешно. Общие итоги работы приведены в "
        "таблице 16.",
    )
    add_results_table(doc)


def add_conclusion(doc):
    add_structural_heading(doc, "ЗАКЛЮЧЕНИЕ")
    add_text(
        doc,
        "В ходе производственной практики была выполнена индивидуальная работа "
        "по мультимедийным и религиозным функциям Irfan Academy. Реализованы "
        "загрузка и воспроизведение видео, геолокация, расписание намазов, "
        "направление Кыблы и локальные напоминания.",
    )
    add_text(
        doc,
        "При разработке были учтены большие размеры видео, временные сетевые "
        "ошибки, отказ в геолокации, отсутствие компаса и различия между Android "
        "и Web. Ошибка zonedSchedule в браузере устранена, а имитация "
        "воспроизведения заменена настоящим видеоплеером.",
    )
    add_text(
        doc,
        "Разработанные компоненты подключены к существующему проекту без "
        "изменения Firebase Authentication и основной структуры Firestore. "
        "Поставленная индивидуальная задача выполнена.",
    )


def add_sources(doc):
    add_structural_heading(doc, "СПИСОК ИСПОЛЬЗОВАННЫХ ИСТОЧНИКОВ")
    sources = (
        "ГОСТ 7.32-2017. Отчёт о научно-исследовательской работе. Структура и правила оформления. — URL: https://protect.gost.ru/gost/details/7d280e43-7036-4a69-8e6e-d15867028343 (дата обращения: 07.09.2026).",
        "КГТУ им. И. Раззакова. Положение о порядке организации практик студентов. — URL: https://kstu.kg/fileadmin/user_upload/13._polozhenie_o_porjadke_organizacii_praktik_studentov_kgtu_im._i._razzakova__2020_g._.pdf (дата обращения: 07.09.2026).",
        "Flutter. Официальная документация. — URL: https://docs.flutter.dev/ (дата обращения: 07.09.2026).",
        "Dart. Документация языка и библиотек. — URL: https://dart.dev/guides (дата обращения: 07.09.2026).",
        "Firebase Authentication for Flutter. — URL: https://firebase.google.com/docs/auth/flutter/start (дата обращения: 07.09.2026).",
        "Cloud Firestore for Flutter. — URL: https://firebase.google.com/docs/firestore/quickstart (дата обращения: 07.09.2026).",
        "Firebase callable functions. — URL: https://firebase.google.com/docs/functions/callable (дата обращения: 07.09.2026).",
        "Cloudinary. Upload API Reference. — URL: https://cloudinary.com/documentation/image_upload_api_reference (дата обращения: 07.09.2026).",
        "Cloudinary. Chunked asset upload. — URL: https://cloudinary.com/documentation/upload_images#chunked_asset_upload (дата обращения: 07.09.2026).",
        "Flutter package video_player. — URL: https://pub.dev/packages/video_player (дата обращения: 07.09.2026).",
        "Flutter package geolocator. — URL: https://pub.dev/packages/geolocator (дата обращения: 07.09.2026).",
        "Dart package adhan. — URL: https://pub.dev/packages/adhan (дата обращения: 07.09.2026).",
        "Flutter package flutter_compass. — URL: https://pub.dev/packages/flutter_compass (дата обращения: 07.09.2026).",
        "Flutter package flutter_local_notifications. — URL: https://pub.dev/packages/flutter_local_notifications (дата обращения: 07.09.2026).",
    )
    for index, source in enumerate(sources, 1):
        paragraph = doc.add_paragraph(f"{index}. {source}")
        paragraph.paragraph_format.left_indent = Cm(1.25)
        paragraph.paragraph_format.first_line_indent = Cm(-1.25)


def add_appendix(doc):
    add_structural_heading(doc, "ПРИЛОЖЕНИЕ А")
    doc.add_heading("А.1 Файлы индивидуальной части проекта", level=2)
    add_table_caption(doc, "А.1", "Файлы, изменённые при выполнении работы")
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"
    headers = ("Файл", "Выполненная работа", "Назначение")
    for cell, value in zip(table.rows[0].cells, headers):
        cell.text = value
        set_cell_shading(cell, "D9D9D9")
    repeat_table_header(table.rows[0])
    rows = (
        (
            "cloudinary_video_service.dart",
            "потоковая и частичная загрузка, прогресс, повторы и метаданные",
            "передача видео в Cloudinary",
        ),
        (
            "video_player_modal.dart",
            "сетевой контроллер и элементы управления",
            "воспроизведение видеоуроков",
        ),
        (
            "prayer_service.dart",
            "геолокация, намазы, следующий день и Кыбла",
            "формирование PrayerSchedule",
        ),
        (
            "notification_service.dart",
            "часовой пояс, разрешения и планирование",
            "локальные напоминания",
        ),
        (
            "qibla_compass.dart",
            "обработка heading и отрисовка указателя",
            "визуальное направление Кыблы",
        ),
        (
            "admin_screen.dart",
            "выбор файла, диалог прогресса и форма урока",
            "административный сценарий загрузки",
        ),
        (
            "prayer_screen.dart",
            "загрузка расписания и обновление статусов",
            "экран религиозных функций",
        ),
        (
            "pubspec.yaml",
            "подключение пакетов видео, геолокации и уведомлений",
            "зависимости индивидуальных модулей",
        ),
    )
    for values in rows:
        cells = table.add_row().cells
        for cell, value in zip(cells, values):
            cell.text = value
    _format_three_column_table(table, (Cm(5), Cm(6.5), Cm(4)))

def build_document():
    doc = Document()
    configure_document(doc)
    doc.core_properties.title = (
        "Отчёт по производственной практике — участник 3"
    )
    doc.core_properties.subject = (
        "Мультимедийные и религиозные модули Irfan Academy"
    )
    doc.core_properties.author = "[ФИО ТРЕТЬЕГО УЧАСТНИКА]"
    add_title_page(doc)
    add_individual_assignment(doc)
    add_schedule(doc)
    add_contents(doc)
    add_introduction(doc)
    add_chapter_one(doc)
    add_chapter_two(doc)
    add_chapter_three(doc)
    add_chapter_four(doc)
    add_chapter_five(doc)
    add_conclusion(doc)
    add_sources(doc)
    add_appendix(doc)
    add_page_number(doc)
    return doc


def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    build_document().save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
