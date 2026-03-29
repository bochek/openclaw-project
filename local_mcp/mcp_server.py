import os
import base64
import json
import requests
import chromadb
from mcp.server import Server
from mcp.types import Tool, TextContent, ImageContent, EmbeddedResource
from typing import List, Optional
from starlette.applications import Starlette
from starlette.routing import Route
import uvicorn
from mcp.server.sse import SseServerTransport

mcp = Server("MemoryAudioServer")

# Configuration
CHROMA_PATH = "./chroma_db"
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://host.docker.internal:11434")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "qwen3-embedding")

# Initialize ChromaDB
client = chromadb.PersistentClient(path=CHROMA_PATH)
collection = client.get_or_create_collection(name="agent_memory")

@mcp.list_tools()
async def list_tools() -> List[Tool]:
    return [
        Tool(
            name="store_memory",
            description="Store a piece of information or reflection into long-term memory",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {"type": "string", "description": "The information to remember"},
                    "tags": {"type": "array", "items": {"type": "string"}, "description": "Tags for categorization (e.g. ['fix', 'config', 'preference'])"}
                },
                "required": ["text"]
            }
        ),
        Tool(
            name="recall_memory",
            description="Search long-term memory for relevant past information",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "What you want to remember"},
                    "n_results": {"type": "integer", "default": 3}
                },
                "required": ["query"]
            }
        ),
        Tool(
            name="transcribe_audio",
            description="Transcribe an audio file content (base64 encoded)",
            inputSchema={
                "type": "object",
                "properties": {
                    "content_base64": {"type": "string", "description": "Base64 encoded audio file content"},
                    "format": {"type": "string", "description": "Audio format (ogg, mp3, etc)"}
                },
                "required": ["content_base64"]
            }
        )
    ]

async def get_embedding(text: str):
    response = requests.post(f"{OLLAMA_URL}/api/embeddings", json={
        "model": EMBEDDING_MODEL,
        "prompt": text
    })
    response.raise_for_status()
    return response.json()["embedding"]

@mcp.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "store_memory":
        text = arguments["text"]
        tags = arguments.get("tags", [])
        
        embedding = await get_embedding(text)
        collection.add(
            documents=[text],
            embeddings=[embedding],
            metadatas=[{"tags": json.dumps(tags), "timestamp": str(requests.utils.quote(text[:20]))}], # Simple timestamp substitute
            ids=[str(hash(text))]
        )
        return [TextContent(type="text", text=f"Successfully stored in memory: {text[:50]}...")]

    elif name == "recall_memory":
        query = arguments["query"]
        n = arguments.get("n_results", 3)
        
        embedding = await get_embedding(query)
        results = collection.query(
            query_embeddings=[embedding],
            n_results=n
        )
        
        memories = []
        for doc in results['documents'][0]:
            memories.append(f"- {doc}")
            
        if not memories:
            return [TextContent(type="text", text="No relevant memories found.")]
            
        return [TextContent(type="text", text="Found relevant memories:\n" + "\n".join(memories))]

    elif name == "transcribe_audio":
        return [TextContent(type="text", text="[STT STUB] This tool would now process the base64 content via local Whisper. Please ensure whisper-cli or faster-whisper is installed on the host.")]

    raise ValueError(f"Unknown tool: {name}")

sse = SseServerTransport("/messages")

async def handle_sse(request):
    async with sse.connect_sse(
        request.scope, request.receive, request._send
    ) as streams:
        await mcp.run(
            streams[0], streams[1], mcp.create_initialization_options()
        )

async def handle_messages(request):
    await sse.handle_post_message(
        request.scope, request.receive, request._send
    )

app = Starlette(routes=[
    Route("/sse", endpoint=handle_sse),
    Route("/messages", endpoint=handle_messages, methods=["POST"]),
])

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
