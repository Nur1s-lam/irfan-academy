# Cloudflare R2 для видеоуроков

Приложение сохраняет в R2 только видео. Firebase Authentication, Firestore и
остальные Firebase-сервисы остаются без изменений. Bucket должен оставаться
приватным: Flutter получает короткоживущие URL через Firebase Callable Functions.

## 1. Bucket и API credentials

1. В Cloudflare Dashboard откройте **R2 Object Storage**.
2. Используйте созданный bucket `irfan-academy-videos` и не включайте Public Development URL.
3. Откройте **Manage R2 API Tokens → Create API token**.
4. Выдайте права **Object Read & Write** только для bucket `irfan-academy-videos`.
5. Сохраните `Access Key ID`, `Secret Access Key` и Cloudflare `Account ID`.

Не добавляйте эти значения в Flutter, `.env`, GitHub или Firestore.

## 2. CORS bucket

В **R2 → irfan-academy-videos → Settings → CORS Policy** добавьте политику.
Замените production-домен на настоящий. Для разработки запускайте Flutter на
фиксированном порту `5000`.

```json
[
  {
    "AllowedOrigins": [
      "http://localhost:5000",
      "https://YOUR_PRODUCTION_DOMAIN"
    ],
    "AllowedMethods": ["GET", "HEAD", "PUT"],
    "AllowedHeaders": ["Content-Type", "Range"],
    "ExposeHeaders": [
      "ETag",
      "Accept-Ranges",
      "Content-Length",
      "Content-Range"
    ],
    "MaxAgeSeconds": 3600
  }
]
```

## 3. Firebase Functions secrets

Из корня проекта выполните по очереди и вставьте соответствующие значения:

```powershell
firebase functions:secrets:set R2_ACCOUNT_ID
firebase functions:secrets:set R2_ACCESS_KEY_ID
firebase functions:secrets:set R2_SECRET_ACCESS_KEY
firebase functions:secrets:set R2_BUCKET
```

Значение `R2_BUCKET`:

```text
irfan-academy-videos
```

## 4. Установка и deployment

```powershell
cd functions
npm install
npm run check
cd ..
firebase deploy --only functions,firestore:rules --project irfanacademy
```

Cloud Functions и Secret Manager требуют подключённый billing-план Firebase.

## 5. Локальный запуск Web

```powershell
C:\Users\HP\flutter\bin\flutter.bat run -d chrome --web-port 5000
```

Случайный порт не совпадёт с CORS policy. Для Android/iOS CORS браузера не
применяется, но используется тот же защищённый API.

## 6. Как устроены данные

Новые документы `videoLessons/{id}` содержат только метаданные:

```json
{
  "number": 1,
  "title": "Урок 1",
  "description": "...",
  "videoPath": "videos/2026-09-04/uuid.mp4",
  "fileName": "lesson-1.mp4",
  "fileSize": 734003200,
  "contentType": "video/mp4",
  "totalSeconds": 3600,
  "duration": "60:00",
  "storageProvider": "cloudflare-r2",
  "createdAt": "server timestamp"
}
```

R2 credentials и постоянный публичный URL здесь отсутствуют.

## 7. Проверка большого видео

1. Войдите пользователем с `role: admin`.
2. Выберите MP4 размером 500 MB или больше.
3. В DevTools Network проверьте загрузку отдельных частей приблизительно по 16 MiB.
4. Во время одной части отключите сеть и включите снова: часть должна повториться
   до четырёх раз с новой подписью.
5. После завершения проверьте объект в R2 и только метаданные в Firestore.
6. Войдите обычным учеником и откройте видео: callable function должна вернуть
   временный GET URL сроком на один час.
7. Удалите видео администратором и убедитесь, что удалены объект R2 и документ Firestore.

## 8. MP4 или HLS

Для первого рабочего варианта используется MP4 с multipart upload. Перед
загрузкой рекомендуется кодировать H.264/AAC и включать `faststart`, чтобы
метаданные MP4 находились в начале файла. R2 поддерживает Range-запросы, поэтому
плеер может перематывать файл.

Для длинных уроков и слабого интернета HLS с 360p/480p/720p даст лучший старт и
адаптивное качество, но R2 сам не выполняет транскодирование. Для HLS понадобится
отдельный процесс FFmpeg/Cloudflare Stream: создать варианты, сегменты и приватно
выдавать manifest/segments. Это отдельный этап и не включён скрыто в текущую
интеграцию.
