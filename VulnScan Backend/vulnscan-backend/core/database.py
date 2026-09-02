"""MongoDB connection management."""

from typing import Optional

from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from .config import settings


class MongoDB:
    """MongoDB connection manager using Motor async driver."""

    client: Optional[AsyncIOMotorClient] = None
    db: Optional[AsyncIOMotorDatabase] = None
    connected: bool = False
    last_error: Optional[str] = None

    @classmethod
    async def connect_db(cls) -> None:
        """Connect to MongoDB and verify the connection with ping."""
        try:
            cls.client = AsyncIOMotorClient(
                settings.MONGODB_URI,
                serverSelectionTimeoutMS=5000,
            )
            cls.db = cls.client[settings.MONGODB_DB_NAME]
            await cls.db.command("ping")
            cls.connected = True
            cls.last_error = None
            print("✓ MongoDB connected")
        except Exception as exc:
            print(f"⚠ MongoDB connection failed: {exc}")
            print("⚠ Starting backend without database - database endpoints will return 503")
            cls.connected = False
            cls.last_error = str(exc)

    @classmethod
    async def close_db(cls) -> None:
        """Close MongoDB connection."""
        if cls.client is not None:
            cls.client.close()
            print("✓ MongoDB disconnected")
        cls.client = None
        cls.db = None
        cls.connected = False

    @classmethod
    def get_db(cls) -> AsyncIOMotorDatabase:
        """Get the database instance or raise HTTP 503 if unavailable."""
        if cls.db is None or not cls.connected:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"MongoDB is not connected: {cls.last_error or 'unknown error'}",
            )
        return cls.db

    @classmethod
    def is_connected(cls) -> bool:
        """Check if connected to MongoDB."""
        return cls.connected
