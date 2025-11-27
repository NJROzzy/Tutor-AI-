FROM python:3.10-slim-bullseye

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    python3-distutils \
 && rm -rf /var/lib/apt/lists/*

COPY backend_requirements.txt .

RUN pip install --no-cache-dir -r backend_requirements.txt

COPY . .

ENV DJANGO_SETTINGS_MODULE=TutorAI.settings

CMD ["gunicorn", "TutorAI.wsgi:application", "--bind", "0.0.0.0:8000"]