# Демо-загрузка видео в Cloudinary

Приложение настроено на cloud name `rrup0mxf` и unsigned upload preset
`irfan_video_demo`. После выбора видео загрузка начинается автоматически,
выполняется частями по 8 MiB и показывает прогресс. При временной ошибке каждая
часть отправляется повторно до четырёх раз.

В Firestore, в коллекции `videoLessons`, сохраняются только метаданные:
`videoUrl`, `videoPath` (Cloudinary public ID), `fileName`, `fileSize`,
`contentType`, `duration`, `totalSeconds` и описание урока. Сам видеофайл в
Firestore не загружается.

## Настройка preset

В Cloudinary откройте **Settings → Upload → Upload presets** и проверьте:

- preset называется `irfan_video_demo`;
- signing mode — **Unsigned**;
- asset folder, например `irfan-academy/videos`;
- разрешены только нужные видеоформаты (`mp4`, `mov`, `webm`);
- задан разумный максимальный размер файла.

Никакие API Secret или API Key приложению не нужны и в исходный код не
добавляются.

## Ограничение демо

Unsigned preset предназначен для теста. Полученный `secure_url` является
публичной ссылкой: Firebase Authentication не защищает сам файл. Удаление урока
в админ-панели удаляет запись Firestore, а файл нужно удалить в Cloudinary Media
Library. Для закрытого production-доступа понадобится серверная подпись.

## Проверка

1. Запустите приложение и войдите администратором.
2. Откройте **Видеоуроки**, нажмите **Загрузить** и выберите MP4.
3. Дождитесь 100%, заполните номер, название и описание.
4. Проверьте объект в Cloudinary Media Library и документ `videoLessons` в
   Firestore.
5. Откройте урок обычным пользователем и проверьте запуск, перемотку и звук.
