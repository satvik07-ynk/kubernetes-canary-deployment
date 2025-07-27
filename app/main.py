from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import os
import time
import random
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = FastAPI()

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')

# App version from environment variable
APP_VERSION = os.getenv('APP_VERSION', 'v1')
FAILURE_RATE = float(os.getenv('FAILURE_RATE', '0.0'))

@app.middleware("http")
async def metrics_middleware(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    REQUEST_DURATION.observe(duration)
    
    return response

@app.get("/")
async def root():
    # Simulate failures based on failure rate
    if random.random() < FAILURE_RATE:
        REQUEST_COUNT.labels(method="GET", endpoint="/", status=500).inc()
        raise HTTPException(status_code=500, detail="Simulated failure")
    
    return {
        "message": f"Welcome to FastAPI v2 from {APP_VERSION}!",
        "version": APP_VERSION,
        "timestamp": time.time()
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": APP_VERSION}

@app.get("/version")
async def get_version():
    return {"version": APP_VERSION}

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
