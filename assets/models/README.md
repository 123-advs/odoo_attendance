# TFLite Face Recognition Models

Đặt file `mobilefacenet.tflite` vào thư mục này (~5 MB).

## Tải ở đâu

Một trong các nguồn TFLite MobileFaceNet công khai:

- **MCarlomagno/FaceRecognitionAuth** (đơn giản, có sẵn .tflite):
  https://github.com/MCarlomagno/FaceRecognitionAuth/raw/master/assets/mobilefacenet.tflite

- **estebanuri/face_recognition** (nhiều variant):
  https://github.com/estebanuri/face_recognition/tree/master/face_recognition/assets

## Đặc tả model app này expect

| Param | Giá trị |
|---|---|
| Input shape | `[1, 112, 112, 3]` |
| Input dtype | `float32` normalized `(pixel - 127.5) / 127.5` (range -1..1) |
| Output shape | `[1, 192]` |
| Output dtype | `float32` (face embedding) |

Nếu file `.tflite` của bạn có shape khác, sửa
`lib/app/core/constants/face_constants.dart` (`modelInputSize` /
`embeddingLength`) cho khớp.

## Tải nhanh (PowerShell)

```powershell
Invoke-WebRequest `
  -Uri "https://github.com/MCarlomagno/FaceRecognitionAuth/raw/master/assets/mobilefacenet.tflite" `
  -OutFile "assets/models/mobilefacenet.tflite"
```

## Tại sao file không có trong git

Model là binary ~5 MB — không nên commit. Sau khi clone repo, mỗi máy tự tải.

## Kiểm tra đã hoạt động

Sau khi đặt file vào, restart app + xem `flutter logs`:

```
[FaceMatch] Model loaded — input [1, 112, 112, 3], output [1, 192]
```

Nếu thấy:

```
[FaceMatch] Model load failed: ... Unable to load asset ...
```

→ File chưa đúng path / chưa đặt vào folder.
