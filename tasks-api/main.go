// Tasks API Server
// Minimal REST API for kanban board backed by PostgreSQL

package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/lib/pq"
)

var db *sql.DB

type Task struct {
	ID        string    `json:"id"`
	Text      string    `json:"text"`
	Status    string    `json:"status"`
	Priority  string    `json:"priority"`
	CreatedAt time.Time `json:"created_at"`
}

type CreateTaskReq struct {
	Text     string `json:"text"`
	Priority string `json:"priority"`
	Status   string `json:"status"`
}

type UpdateTaskReq struct {
	Text     string `json:"text"`
	Priority string `json:"priority"`
	Status   string `json:"status"`
}

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = os.Getenv("GOCLAW_POSTGRES_DSN")
	}
	if dsn == "" {
		log.Println("WARNING: DATABASE_URL and GOCLAW_POSTGRES_DSN are empty. Falling back to localhost.")
		dsn = "postgres://goclaw:goclaw@localhost:5432/goclaw?sslmode=disable"
	}

	var err error
	db, err = sql.Open("postgres", dsn)
	if err != nil {
		log.Fatalf("Failed to open database connection: %v", err)
	}
	defer db.Close()

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database (check your DATABASE_URL env var on Render): %v", err)
	}

	log.Println("Connected to PostgreSQL")

	// Create tasks table if not exists
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS tasks (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			text TEXT NOT NULL,
			status VARCHAR(50) DEFAULT 'todo',
			priority VARCHAR(20) DEFAULT 'medium',
			created_at TIMESTAMP DEFAULT NOW()
		)
	`)
	if err != nil {
		log.Printf("Warning: could not create table: %v", err)
	}

	// Routes
	http.HandleFunc("/health", corsMiddleware(healthHandler))
	http.HandleFunc("/api/tasks", corsMiddleware(tasksHandler))
	http.HandleFunc("/api/tasks/", corsMiddleware(taskByIDHandler))

	port := os.Getenv("PORT")
	if port == "" {
		port = os.Getenv("GOCLAW_GATEWAY_PORT")
	}
	if port == "" {
		port = "8080"
	}

	log.Printf("Tasks API listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PATCH, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		next(w, r)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func tasksHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		rows, err := db.Query("SELECT id, text, COALESCE(status, 'todo'), COALESCE(priority, 'medium'), created_at FROM tasks ORDER BY created_at DESC")
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		defer rows.Close()

		tasks := []Task{}
		for rows.Next() {
			var t Task
			if err := rows.Scan(&t.ID, &t.Text, &t.Status, &t.Priority, &t.CreatedAt); err != nil {
				continue
			}
			tasks = append(tasks, t)
		}
		json.NewEncoder(w).Encode(tasks)

	case http.MethodPost:
		var req CreateTaskReq
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), 400)
			return
		}

		if req.Status == "" {
			req.Status = "todo"
		}
		if req.Priority == "" {
			req.Priority = "medium"
		}

		var id string
		err := db.QueryRow(
			"INSERT INTO tasks (text, status, priority) VALUES ($1, $2, $3) RETURNING id",
			req.Text, req.Status, req.Priority,
		).Scan(&id)

		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"id": id})

	default:
		w.WriteHeader(405)
	}
}

func taskByIDHandler(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Path[len("/api/tasks/"):]
	if id == "" {
		http.Error(w, "missing task id", 400)
		return
	}

	switch r.Method {
	case http.MethodGet:
		var t Task
		err := db.QueryRow(
			"SELECT id, text, COALESCE(status, 'todo'), COALESCE(priority, 'medium'), created_at FROM tasks WHERE id = $1",
			id,
		).Scan(&t.ID, &t.Text, &t.Status, &t.Priority, &t.CreatedAt)

		if err == sql.ErrNoRows {
			http.Error(w, "not found", 404)
			return
		}
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		json.NewEncoder(w).Encode(t)

	case http.MethodPatch:
		var req UpdateTaskReq
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), 400)
			return
		}

		// Build dynamic update query
		query := "UPDATE tasks SET "
		args := []interface{}{}
		argIdx := 1

		if req.Text != "" {
			query += fmt.Sprintf("text = $%d, ", argIdx)
			args = append(args, req.Text)
			argIdx++
		}
		if req.Status != "" {
			query += fmt.Sprintf("status = $%d, ", argIdx)
			args = append(args, req.Status)
			argIdx++
		}
		if req.Priority != "" {
			query += fmt.Sprintf("priority = $%d, ", argIdx)
			args = append(args, req.Priority)
			argIdx++
		}

		// Remove trailing comma
		query = query[:len(query)-2]
		query += fmt.Sprintf(" WHERE id = $%d", argIdx)
		args = append(args, id)

		_, err := db.Exec(query, args...)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		w.WriteHeader(204)

	case http.MethodDelete:
		_, err := db.Exec("DELETE FROM tasks WHERE id = $1", id)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		w.WriteHeader(204)

	default:
		w.WriteHeader(405)
	}
}
