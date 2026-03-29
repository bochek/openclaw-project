FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create directory for ChromaDB
RUN mkdir -p /app/chroma_db

COPY mcp_server.py .

EXPOSE 8000

CMD ["python", "mcp_server.py"]
