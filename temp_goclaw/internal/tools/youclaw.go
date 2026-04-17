package tools

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/go-claw/goclaw"
)

const (
	youClawEndpoint = "https://bochekpc-1.tail45774e.ts.net/agent/execute"
	youClawTimeout  = 120 * time.Second
)

type YouClawTool struct {
	client *http.Client
}

func NewYouClawTool() *YouClawTool {
	return &YouClawTool{
		client: &http.Client{Timeout: youClawTimeout},
	}
}

func (t *YouClawTool) Name() string { return "youclaw" }
func (t *YouClawTool) Description() string {
	return `Executes heavy tasks on your local PC (GPU/Docker/File operations).
Uses RTX 3090 Ti + 5080 Ti for AI/ML workloads.
Use for: ollama_chat, ollama_embed, docker exec, file read/write, web search.`
}

// Request/Response types
type YouClawRequest struct {
	Tool    string          `json:"tool"`
	Message string          `json:"message"`
	Params  json.RawMessage `json:"params,omitempty"`
}

type YouClawResponse struct {
	Success bool   `json:"success"`
	Output  string `json:"output"`
	Error   string `json:"error,omitempty"`
}

func (t *YouClawTool) Handle(ctx context.Context, input goclaw.ToolInput) (goclaw.ToolOutput, error) {
	// Parse request
	var req YouClawRequest
	if err := json.Unmarshal([]byte(input.Arguments), &req); err != nil {
		// Try simple format: just tool name
		req = YouClawRequest{
			Tool:    input.Tool,
			Message: input.Arguments,
		}
	}

	payload, _ := json.Marshal(req)

	httpReq, err := http.NewRequestWithContext(ctx, "POST", youClawEndpoint, bytes.NewReader(payload))
	if err != nil {
		return goclaw.ToolOutput{}, fmt.Errorf("create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := t.client.Do(httpReq)
	if err != nil {
		return goclaw.ToolOutput{Error: fmt.Sprintf("youclaw unreachable: %v", err)}, nil
	}
	defer resp.Body.Close()

	var youResp YouClawResponse
	if err := json.NewDecoder(resp.Body).Decode(&youResp); err != nil {
		return goclaw.ToolOutput{Error: fmt.Sprintf("parse response: %v", err)}, nil
	}

	if !youResp.Success {
		return goclaw.ToolOutput{Error: youResp.Error}, nil
	}

	return goclaw.ToolOutput{Content: youResp.Output}, nil
}

// Wrapper for easy calls
func CallYouClaw(tool, message string) (string, error) {
	ctx := context.Background()
	t := NewYouClawTool()
	out, err := t.Handle(ctx, goclaw.ToolInput{
		Tool:      tool,
		Arguments: fmt.Sprintf(`{"tool":"%s","message":"%s"}`, tool, message),
	})
	if err != nil {
		return "", err
	}
	if out.Error != "" {
		return "", fmt.Errorf(out.Error)
	}
	return out.Content, nil
}
