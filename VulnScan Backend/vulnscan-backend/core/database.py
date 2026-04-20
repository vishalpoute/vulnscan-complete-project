from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from .config import settings


class MongoDB:
    """MongoDB connection manager using Motor async driver."""

    client: AsyncIOMotorClient = None
    db: AsyncIOMotorDatabase = None
    connected: bool = False

    @classmethod
    async def connect_db(cls):
        """Connect to MongoDB."""
        try:
            cls.client = AsyncIOMotorClient(settings.MONGODB_URI, serverSelectionTimeoutMS=5000)
            cls.db = cls.client[settings.MONGODB_DB_NAME]
            # Verify connection
            await cls.db.command("ping")
            cls.connected = True
            print("✓ MongoDB connected")
        except Exception as e:
            print(f"⚠ MongoDB connection failed: {e}")
            print("⚠ Starting backend without database - will retry on next request")
            cls.connected = False

    @classmethod
    async def close_db(cls):
        """Close MongoDB connection."""
        if cls.client:
            cls.client.close()
            print("✓ MongoDB disconnected")

    @classmethod
    def get_db(cls) -> AsyncIOMotorDatabase:
        """Get the database instance."""
        return cls.db
    
    @classmethod
    def is_connected(cls) -> bool:
        """Check if connected to MongoDB."""
        return cls.connected
