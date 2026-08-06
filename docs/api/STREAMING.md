# Server-Sent Events (SSE) Streaming Contract

## Purpose
This document defines the real-time communication contract for the Grahvani AI Chat interface. Because LLM generation takes several seconds, standard REST responses are unacceptable for UX. Grahvani uses Server-Sent Events (SSE) to stream tokens to the Flutter client as they are generated.

## Scope
Applies specifically to the `POST /api/v1/chat/stream` endpoint.

---

## 1. Protocol Details

- **Protocol**: HTTP/1.1 (or HTTP/2) Server-Sent Events (SSE).
- **Content-Type**: `text/event-stream`
- **Connection**: Keep-alive; unidirectional (Server to Client).
- **Authentication**: Standard Firebase JWT via `Authorization: Bearer <token>` header (same as REST endpoints).

Unlike WebSockets, SSE operates over standard HTTP, making it trivial to route through AWS App Runner, CloudFront, and WAF without connection upgrades or load balancer timeouts.

---

## 2. Request Structure

```http
POST /api/v1/chat/stream HTTP/1.1
Host: api.grahvani.app
Authorization: Bearer eyJhb...
Content-Type: application/json
Accept: text/event-stream

{
  "session_id": "00000000-0000-0000-0000-000000000001",
  "question": "What does Saturn in my 10th house signify?",
  "chart_id": "e4b2d184-7a33-4f9e-a892-123456789abc"
}
```

---

## 3. Event Types and Payloads

The server emits a sequence of events. Each event follows the SSE format:
```text
event: <event_name>
data: <json_string>
\n\n
```

### 3.1 Event: `metadata`
Emitted exactly once, immediately after connection. Contains the trace ID and billing status.
```text
event: metadata
data: {"request_id": "req-942a1", "remaining_quota": 2}
```

### 3.2 Event: `citation`
Emitted early in the stream, once for each knowledge base chunk retrieved by RAG. The UI renders these as clickable source chips above the chat bubble.
```text
event: citation
data: {"citation_id": 1, "source": "BPHS Ch. 34", "text_snippet": "Saturn in the 10th..."}
```

### 3.3 Event: `token`
Emitted continuously as the LLM generates the response. The UI appends the string to the active chat bubble.
```text
event: token
data: {"text": "Saturn "}
```

### 3.4 Event: `done`
Emitted exactly once when generation is complete. The connection is then closed gracefully.
```text
event: done
data: {"status": "completed", "finish_reason": "stop"}
```

### 3.5 Event: `error`
Emitted if an error occurs mid-stream (e.g., LLM provider timeout, guardrail block). The client should display the error message and close the connection.
```text
event: error
data: {"error_code": "AI_POLICY_VIOLATION", "message": "I cannot answer medical questions."}
```

---

## 4. Client-Side Parsing (Flutter)

The Flutter app parses the SSE stream using a custom HTTP client loop to avoid relying on outdated or heavy third-party SSE packages:

```dart
// Simplified Dart SSE parsing loop
final request = http.Request('POST', Uri.parse('.../api/v1/chat/stream'));
// Add headers and body...

final response = await http.Client().send(request);
response.stream
    .transform(const Utf8Decoder())
    .transform(const LineSplitter())
    .listen((String line) {
        if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
            final dataStr = line.substring(5).trim();
            final json = jsonDecode(dataStr);
            
            switch (currentEvent) {
                case 'token':
                    chatStore.appendToken(json['text']);
                    break;
                case 'citation':
                    chatStore.addCitation(json);
                    break;
                case 'error':
                    chatStore.showError(json['message']);
                    break;
            }
        }
    });
```

---

## 5. Rationale

SSE is vastly superior to WebSockets for this specific use case:
1. **Unidirectional requirement**: The user sends one block of JSON, and the server sends a stream of text. We don't need bi-directional streaming.
2. **Infrastructure simplicity**: Standard HTTP load balancers and AWS WAF inspect SSE requests natively.
3. **Reconnection**: Standard HTTP request retry logic applies if the connection drops.

---

## 6. Related Documents

- [ai/RAG.md](../ai/RAG.md) -- Where the `citation` events originate
- [api/REQUEST_RESPONSE.md](REQUEST_RESPONSE.md) -- For standard synchronous REST calls
