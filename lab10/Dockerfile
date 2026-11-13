FROM python:3.11-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ .
ENV PORT=8000
EXPOSE 8000
CMD ["python", "app.py"]
