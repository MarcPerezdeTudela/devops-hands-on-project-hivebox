FROM python:3.13-slim-bookworm

WORKDIR /app

COPY app.py .

CMD ["python", "app.py"]
