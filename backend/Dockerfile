FROM python:3.10-slim

WORKDIR /app

COPY . /app

# Set correct path to the credentials file
ENV GOOGLE_APPLICATION_CREDENTIALS=/app/gcloud_access_credentials.json

ENV PIP_DEFAULT_TIMEOUT=1200

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD ["python", "main.py"]
