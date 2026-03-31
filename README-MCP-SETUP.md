# 🖥️ Local MCP Servers Setup

Настройка MCP серверов на локальной Windows машине с доступом через Tailscale.

## Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                     Windows + Docker Desktop                │
├─────────────────────────────────────────────────────────────┤
│  100.77.228.76 (Tailscale)                                  │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  local-mcp  │  │ mcp-docker  │  │ mcp-github  │         │
│  │   :8005     │  │   :8002     │  │   :8003     │         │
│  │ RAG+Whisper │  │ Docker API  │  │   GitHub    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
│  ┌─────────────┐                                           │
│  │   context7  │                                           │
│  │   :9001     │                                           │
│  └─────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
           │
           │ SSE (HTTP)
           ▼
    ┌─────────────────┐
    │  GoClaw Agent   │
    │   (Render)      │
    └─────────────────┘
```

## Быстрый старт

### 1. Клонировать репо
```powershell
git clone -b dev https://github.com/bochek/openclaw-project.git
cd openclaw-project
```

### 2. Создать .env файл
```powershell
# Скопировать пример и заполнить
copy .env.example .env
```

Отредактировать `.env`:
```env
GITHUB_PERSONAL_ACCESS_TOKEN=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
```

### 3. Проверить Ollama
```powershell
# Должен быть запущен
ollama list

# Проверить нужные модели
ollama show qwen3-embedding
```

Если модели нет — установить:
```powershell
ollama pull qwen3-embedding
```

### 4. Запустить серверы
```powershell
docker compose up -d
```

### 5. Проверить работу
```powershell
# Все серверы
docker compose ps

# Тест local-mcp
curl http://localhost:8005/sse

# Тест mcp-github
curl http://localhost:8003/sse
```

## Доступ через Tailscale

Серверы доступны извне по адресам:
- `http://100.77.228.76:8005` — local-mcp (RAG + Whisper)
- `http://100.77.228.76:8002` — mcp-docker
- `http://100.77.228.76:8003` — mcp-github
- `http://100.77.228.76:9001` — context7

**Важно:** Убедись что Windows Firewall разрешает входящие на этих портах!

```powershell
# Проверить listening ports
netstat -an | findstr "8000 8001 8002 8003 9001"
```

## Доступные Tools

### local-mcp (:8005)
- `store_memory` — сохранить информацию в ChromaDB
- `recall_memory` — поиск по памяти
- `transcribe_audio` — распознавание речи (base64 audio)

### mcp-github (:8003)
- `create_issue` — создать issue
- `search_code` — поиск по коду
- `list_repos` — список репозиториев
- и другие GitHub операции

### context7 (:9001)
- Контекстный поиск по документации

### mcp-docker (:8002)
- Управление Docker контейнерами

## Troubleshooting

### local-mcp не запускается
```powershell
docker compose logs local-mcp
# Проверить OLLAMA_URL — должен быть http://host.docker.internal:11434
```

### Whisper ошибка
```powershell
# Убедись что модель скачана
ollama list | findstr whisper
```

### Tailscale недоступен снаружи
```powershell
# Проверить status
tailscale status

# Проверить listening
tailscale serve status
```

## Stop & Restart

```powershell
# Остановить
docker compose down

# Перезапустить
docker compose restart

# Полный рестарт
docker compose down -v
docker compose up -d
```
