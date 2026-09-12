FROM python:3.9-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt "Werkzeug==2.3.8" && pip install --no-cache-dir "boto3>=1.34.0"

FROM python:3.9-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . .
EXPOSE 8005
CMD ["gunicorn", "--bind", "0.0.0.0:8005", "app:app"]
