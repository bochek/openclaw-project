package tools

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

const (
	youClawEndpoint = "https://bochekpc-1.tail45774e.ts.net/agent/execute/"
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

func (t *YouClawTool) Parameters() map[string]any {
	return map[string]any{
		"type": "object",
		"properties": map[string]any{
			"tool": map[string]any{
				"type":        "string",
				"description": "Local tool name (e.g., 'ollama_chat', 'docker_exec').",
			},
			"message": map[string]any{
				"type":        "string",
				"description": "Command or input message for the local tool.",
			},
			"params": map[string]any{
				"type":        "object",
				"description": "Optional structured parameters.",
			},
		},
		"required": []string{"tool", "message"},
	}
}

type youClawRequest struct {
	Tool    string          `json:"tool"`
	Message string          `json:"message"`
	Params  json.RawMessage `json:"params,omitempty"`
}

type youClawResponse struct {
	Success bool   `json:"success"`
	Output  string `json:"output"`
	Error   string `json:"error,omitempty"`
}

func (t *YouClawTool) Execute(ctx context.Context, args map[string]any) *Result {
	tool, _ := args["tool"].(string)
	message, _ := args["message"].(string)

	var params json.RawMessage
	if p, ok := args["params"]; ok {
		if b, err := json.Marshal(p); err == nil {
			params = b
		}
	}

	req := youClawRequest{
		Tool:    tool,
		Message: message,
		Params:  params,
	}

	payload, _ := json.Marshal(req)

	fmt.Printf("DEBUG: YouClaw calling POST %s with payload len %d\n", youClawEndpoint, len(payload))

	httpReq, err := http.NewRequestWithContext(ctx, "POST", youClawEndpoint, bytes.NewReader(payload))
	if err != nil {
		return ErrorResult(fmt.Sprintf("create request: %v", err))
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := t.client.Do(httpReq)
	if err != nil {
		return ErrorResult(fmt.Sprintf("youclaw unreachable: %v", err))
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return ErrorResult(fmt.Sprintf("bridge returned status %d", resp.StatusCode))
	}

	var youResp youClawResponse
	if err := json.NewDecoder(resp.Body).Decode(&youResp); err != nil {
		return ErrorResult(fmt.Sprintf("parse response: %v", err))
	}

	if !youResp.Success {
		return ErrorResult(youResp.Error)
	}

	return NewResult(youResp.Output)
}
