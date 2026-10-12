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
