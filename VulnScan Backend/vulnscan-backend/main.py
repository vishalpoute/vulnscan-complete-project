"""VulnScan Backend API - Main FastAPI Application."""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.config import settings
from core.database import MongoDB
from core.firestore import FirestoreDB
from routers import auth, scans, users, payments, admin, feedback


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    # Startup
    print("🚀 Starting VulnScan Backend API...")
    await MongoDB.connect_db()
    FirestoreDB.initialize()  # Initialize Firestore
    yield
    # Shutdown
    print("🛑 Shutting down...")
    await MongoDB.close_db()


# Create FastAPI app
app = FastAPI(
    title="VulnScan Backend API",
    description="Security vulnerability scanning backend",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure based on frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers with /api prefix
app.include_router(auth.router, prefix="/api")
app.include_router(scans.router, prefix="/api")
app.include_router(users.router, prefix="/api")
app.include_router(payments.router, prefix="/api")
app.include_router(admin.router, prefix="/api")
app.include_router(feedback.router, prefix="/api")


@app.get("/", tags=["health"])
async def root():
    """Health check endpoint."""
    return {
        "status": "ok",
        "service": "VulnScan Backend API",
        "version": "1.0.0",
    }


@app.get("/api/health/diagnostic", tags=["health"])
async def diagnostic():
    """Diagnostic endpoint to check backend status and connectivity."""
    from core.database import MongoDB
    from core.firestore import FirestoreDB
    
    db_status = "❌ NOT CONNECTED"
    db_connected = MongoDB.is_connected()
    if db_connected:
        db_status = "✅ CONNECTED"
    
    fs_status = "❌ NOT INITIALIZED"
    if FirestoreDB.initialized:
        fs_status = "✅ INITIALIZED"
    
    # Try to count users
    user_count = 0
    try:
        if db_connected:
            db = MongoDB.get_db()
            user_count = await db["users"].count_documents({})
    except Exception as e:
        user_count = f"Error: {str(e)}"
    
    return {
        "status": "ok",
        "timestamp": __import__('datetime').datetime.utcnow().isoformat(),
        "mongodb": {
            "status": db_status,
            "connected": db_connected,
            "users_in_database": user_count,
        },
        "firestore": {
            "status": fs_status,
            "initialized": FirestoreDB.initialized,
        },
        "message": "Use this endpoint to diagnose backend connectivity issues",
    }


@app.get("/health", tags=["health"])
async def health():
    """Detailed health check."""
    return {
        "status": "healthy",
        "debug": settings.DEBUG,
        "database": "connected",
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host=settings.HOST,
        port=settings.PORT,
        log_level="info",
    )
