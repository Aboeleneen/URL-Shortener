# ShortLink - URL Shortening Service

## Architecture

- **Sinatra**: Web framework
- **PostgreSQL**: URL storage
- **Redis**: Atomic counter for unique IDs
- **Base62**: Human-readable short codes (0-9, A-Z, a-z)

## API

### POST /encode
Convert long URL to short URL

**Request:**
```json
{
  "url": "https://example.com/very/long/url"
}
```

**Response:**
```json
{
  "short_url": "{BASE_URL}/GeAi9K",
  "original_url": "https://example.com/very/long/url"
}
```

### POST /decode
Get original URL from short URL

**Request:**
```json
{
  "short_url": "{BASE_URL}/GeAi9K"
}
```

**Response:**
```json
{
  "original_url": "https://example.com/very/long/url",
  "short_url": "{BASE_URL}/GeAi9K"
}
```

## Quick Start

```bash
# Start with Docker
docker compose up --build

# Test API
curl -X POST http://localhost:4567/encode \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

## Run Tests

```bash
# Run tests inside Docker container
docker compose exec app ruby run_tests.rb
```

## Issues Identified

### Issue 1: Rate Limiting
**Problem**: No rate limiting protection
**Impact**: Service vulnerable to abuse and resource exhaustion
**Solution**: Implement `rack-attack` gem for IP-based throttling (100 requests/minute per IP)

### Issue 2: Race Conditions
**Problem**: Potential race condition in URL creation
**Analysis**: Actually protected by Redis single-threaded nature
- Redis `INCR` operation is atomic and thread-safe
- Each request gets unique ID, preventing collision
- Database unique constraint provides final safety net
**Conclusion**: No race condition problem given Redis is single-threaded

## Scalability

### Current Capacity
- **Base62 Encoding**: Supports up to 62^6 ≈ 56.8 billion unique URLs with 6-character codes
- **Single Instance**: ~1,000 requests/second

### Scaling Strategy
- **Replicated Servers**: Multiple application instances behind load balancer
- **Database Replication**: Read replicas for decode operations, master for writes
- **Single Global Counter**: Redis remains the single source of truth for ID generation
  - Redis single-threaded nature ensures atomic counter operations
  - All servers share the same Redis instance for consistent ID generation
  - No ID collisions across multiple application instances

### Why Single Global Counter Works
- Redis `INCR` operation is atomic and thread-safe
- Single-threaded execution prevents race conditions
- All application instances get unique, sequential IDs
- Database unique constraint provides final safety net

## Deployment

The service is deployed at: **https://sinatra-url-shortener.fly.dev**

### Live API Examples

```bash
# Encode a URL
curl -X POST https://sinatra-url-shortener.fly.dev/encode \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# Decode a URL (replace GeAi9K with actual short code from above)
curl -X POST https://sinatra-url-shortener.fly.dev/decode \
  -H "Content-Type: application/json" \
  -d '{"short_url": "https://sinatra-url-shortener.fly.dev/GeAi9K"}'
```

See [FLY_DEPLOYMENT.md](FLY_DEPLOYMENT.md) for deployment instructions.