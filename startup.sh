#!/bin/bash
set -e

# ===========================================
# Echo Startup Script
# Клонирует bochek-echo (личные файлы) в /data
# ===========================================

DATA_DIR="/data"
ECHO_SOURCE="$DATA_DIR/echo-source"

echo "[Echo] Starting initialization..."

# 1. Настроить SSH для deploy key
if [ -n "$DEPLOY_KEY" ]; then
    echo "[Echo] Setting up SSH deploy key..."
    mkdir -p ~/.ssh
    echo "$DEPLOY_KEY" > ~/.ssh/deploy_key
    chmod 600 ~/.ssh/deploy_key
    
    # SSH config для github.com
    cat > ~/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/deploy_key
    StrictHostKeyChecking no
EOF
    chmod 600 ~/.ssh/config
fi

# 2. Клонировать bochek-echo если ещё не склонирован
if [ ! -d "$ECHO_SOURCE" ]; then
    echo "[Echo] Cloning bochek-echo repository..."
    git clone git@github.com:bochek/bochek-echo.git "$ECHO_SOURCE"
else
    echo "[Echo] bochek-echo already cloned, pulling latest..."
    cd "$ECHO_SOURCE" && git pull
fi

# 3. Скопировать личные файлы в /data
echo "[Echo] Syncing personal files to /data..."

# MEMORY.md
if [ -f "$ECHO_SOURCE/MEMORY.md" ]; then
    cp "$ECHO_SOURCE/MEMORY.md" "$DATA_DIR/MEMORY.md"
    echo "[Echo]   ✓ MEMORY.md"
fi

# Скиллы
if [ -d "$ECHO_SOURCE/skills" ]; then
    cp -r "$ECHO_SOURCE/skills/"* "$DATA_DIR/skills/" 2>/dev/null || true
    echo "[Echo]   ✓ skills/"
fi

# Memory файлы (без credentials!)
if [ -d "$ECHO_SOURCE/memory" ]; then
    # Исключаем sensitive файлы
    rsync -av --exclude='credentials.md' --exclude='apikeys.md' \
          "$ECHO_SOURCE/memory/" "$DATA_DIR/memory/" 2>/dev/null || {
        # Если rsync нет, копируем вручную с фильтром
        mkdir -p "$DATA_DIR/memory"
        for f in "$ECHO_SOURCE/memory/"*.md; do
            [ -f "$f" ] && ! basename "$f" | grep -qE 'credentials|apikeys' && cp "$f" "$DATA_DIR/memory/"
        done
    }
    echo "[Echo]   ✓ memory/ (filtered)"
fi

# SOUL.md, IDENTITY.md, USER.md (если есть)
for f in SOUL.md IDENTITY.md USER.md AGENTS.md HEARTBEAT.md; do
    if [ -f "$ECHO_SOURCE/$f" ]; then
        cp "$ECHO_SOURCE/$f" "$DATA_DIR/$f"
        echo "[Echo]   ✓ $f"
    fi
done

echo "[Echo] Initialization complete!"
echo "[Echo] Files in /data:"
ls -la "$DATA_DIR" | grep -v "^d"

# 4. Запустить агента (передаём управление)
echo "[Echo] Starting GoClaw agent..."
