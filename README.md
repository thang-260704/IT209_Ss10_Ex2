# Session 10 - Bài 2: Đóng gói ứng dụng Web Backend bằng Single-stage Dockerfile

## 1. Mục tiêu

Đóng gói một REST API Node.js/Express thành image `hw-backend:v1` bằng Dockerfile single-stage, chạy container `app-single-stage` ở cổng `8080:3000`.

## 2. Cấu trúc thư mục

```text
ex2/
├── .dockerignore
├── Dockerfile
├── package.json
├── server.js
├── README.md
└── images/
```

## 3. Mã nguồn ứng dụng

`package.json`

```json
{
  "name": "ex2-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "^4.18.2" }
}
```

`server.js`

```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;
app.get('/', (req, res) => res.json({ status: 'success', message: 'Hello from Docker Single-stage!' }));
app.listen(PORT, () => console.log(`Server listening on port ${PORT}`));
```

## 4. Dockerfile

```dockerfile
# Base image: Node.js 18 trên Alpine Linux (nhẹ)
FROM node:18-alpine

# Thư mục làm việc trong container
WORKDIR /app

# Biến môi trường: cổng ứng dụng lắng nghe và chế độ chạy
ENV PORT=3000
ENV NODE_ENV=production

# Copy package.json trước để tận dụng layer cache khi chỉ sửa code
COPY package*.json ./

# Cài dependency (chỉ production)
RUN npm install --omit=dev && npm cache clean --force

# Copy mã nguồn ứng dụng
COPY server.js ./

# Ghi chú cổng ứng dụng sử dụng
EXPOSE 3000

# Lệnh khởi động dạng exec form: node chạy ở PID 1, nhận SIGTERM trực tiếp
CMD ["node", "server.js"]
```

| Chỉ thị | Giá trị | Vai trò |
|---|---|---|
| `FROM` | `node:18-alpine` | Image nền có sẵn Node.js 18, bản Alpine dung lượng nhỏ |
| `WORKDIR` | `/app` | Mọi lệnh `COPY`, `RUN`, `CMD` phía sau đều chạy trong `/app` |
| `ENV` | `PORT=3000`, `NODE_ENV=production` | `server.js` đọc `process.env.PORT`; biến tồn tại cả lúc build lẫn lúc chạy |
| `COPY` | `package*.json` rồi `server.js` | Tách làm 2 bước: sửa code chỉ build lại từ bước `COPY server.js`, không phải cài lại thư viện |
| `RUN` | `npm install --omit=dev` | Cài Express ngay trong lúc build, kết quả nằm trong một layer |
| `EXPOSE` | `3000` | Ghi chú cổng ứng dụng dùng; muốn truy cập từ host vẫn phải `-p` |
| `CMD` | `["node", "server.js"]` | Exec form: `node` là PID 1, `docker stop` dừng ứng dụng gọn gàng |

File `.dockerignore` loại `node_modules`, `README.md`, `images/` khỏi build context để build nhanh và image không chứa file thừa.

## 5. Build image

```bash
docker build -t hw-backend:v1 .
docker images hw-backend
```

```text
[+] Building 25.1s (10/10) FINISHED                                  docker:default
 => [internal] load build definition from Dockerfile                           0.0s
 => => transferring dockerfile: 709B                                           0.0s
 => [internal] load metadata for docker.io/library/node:18-alpine              2.5s
 => [internal] load .dockerignore                                              0.1s
 => [1/5] FROM docker.io/library/node:18-alpine@sha256:8d6421d663b4c28fd3ebc498332f249011d118945588d0a35cb9bc4b8c   6.6s
 => [internal] load build context                                              0.1s
 => => transferring context: 518B                                              0.0s
 => [2/5] WORKDIR /app                                                         0.6s
 => [3/5] COPY package*.json ./                                                0.1s
 => [4/5] RUN npm install --omit=dev && npm cache clean --force               10.3s
 => [5/5] COPY server.js ./                                                    0.2s
 => exporting to image                                                         4.3s
 => => naming to docker.io/library/hw-backend:v1                               0.0s
 => => unpacking to docker.io/library/hw-backend:v1                            3.7s

IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
hw-backend:v1   729cc53a9207        186MB         45.6MB
```

Build gồm 5 bước tương ứng các chỉ thị trong Dockerfile; bước nặng nhất là `RUN npm install` (10.3s). Image cuối có dung lượng nội dung **45.6MB** (186MB trên đĩa khi giải nén).

![docker build](images/01-build.png)

## 6. Chạy container và kiểm tra

```bash
docker run -d --name app-single-stage -p 8080:3000 hw-backend:v1
docker ps
docker logs app-single-stage
curl -i http://localhost:8080/
```

```text
b4af61cdff178a6c77cb752d906890ffb43afe2ab22cb7e40c636db20162dbed

$ docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED         STATUS         PORTS                                         NAMES
b4af61cdff17   hw-backend:v1    "docker-entrypoint.s…"   5 seconds ago   Up 4 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   app-single-stage
20672e4ed812   my-html-app:v1   "/docker-entrypoint.…"   3 days ago      Up 3 days      0.0.0.0:8081->80/tcp, [::]:8081->80/tcp       html-app

$ docker logs app-single-stage
Server listening on port 3000

$ curl -i http://localhost:8080/
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 64
ETag: W/"40-upZb7Fps+hszzRU9BoKtiCsmGCQ"
Date: Mon, 12 Oct 2026 01:00:32 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"status":"success","message":"Hello from Docker Single-stage!"}
```

![docker run, ps, logs, curl](images/02-run-curl.png)

## 7. Kết luận

- Image `hw-backend:v1` build thành công từ Dockerfile single-stage, đủ các chỉ thị `FROM`, `WORKDIR`, `ENV`, `COPY`, `RUN`, `EXPOSE`, `CMD`.
- Container `app-single-stage` ở trạng thái `Up`, log in `Server listening on port 3000`.
- `curl -i http://localhost:8080/` trả về `HTTP/1.1 200 OK` với body JSON.
