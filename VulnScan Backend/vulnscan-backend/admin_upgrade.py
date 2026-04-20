#!/usr/bin/env python3
"""
Simple admin utility script to upgrade users directly in MongoDB.
Run: python admin_upgrade.py <email> <tier>
Example: python admin_upgrade.py test@example.com pro
"""

import sys
import asyncio
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient

# MongoDB connection settings
MONGODB_URI = "mongodb+srv://vulnscan_user:Vulnscan1234@vulnscan.jxbrz.mongodb.net/?retryWrites=true&w=majority"
MONGODB_DB = "vulnscan"


async def upgrade_user(email: str, tier: str):
    """Upgrade a user to a specific tier."""
    
    if tier not in ["free", "pro", "enterprise"]:
        print(f"❌ Invalid tier: {tier}")
        print("   Valid tiers: free, pro, enterprise")
        return False
    
    try:
        # Connect to MongoDB
        print(f"🔄 Connecting to MongoDB...")
        client = AsyncIOMotorClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
        db = client[MONGODB_DB]
        
        # Verify connection
        await db.command("ping")
        print(f"✅ Connected to MongoDB")
        
        # Find user
        users_collection = db["users"]
        user = await users_collection.find_one({"email": email})
        
        if not user:
            print(f"❌ User not found: {email}")
            return False
        
        # Update user
        result = await users_collection.update_one(
            {"email": email},
            {
                "$set": {
                    "subscription_tier": tier,
                    "upgraded_at": datetime.utcnow(),
                    "admin_upgraded": True,
                }
            }
        )
        
        if result.modified_count > 0:
            print(f"✅ SUCCESS! User {email} upgraded to {tier}")
            print(f"   Updated at: {datetime.utcnow().isoformat()}")
            return True
        else:
            print(f"❌ Failed to update user")
            return False
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False
    finally:
        client.close()


async def reset_scans(email: str):
    """Reset scan count for a user."""
    
    try:
        # Connect to MongoDB
        print(f"🔄 Connecting to MongoDB...")
        client = AsyncIOMotorClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
        db = client[MONGODB_DB]
        
        # Verify connection
        await db.command("ping")
        print(f"✅ Connected to MongoDB")
        
        # Find user
        users_collection = db["users"]
        user = await users_collection.find_one({"email": email})
        
        if not user:
            print(f"❌ User not found: {email}")
            return False
        
        # Reset scans
        result = await users_collection.update_one(
            {"email": email},
            {
                "$set": {
                    "scans_used": 0,
                    "scans_reset_at": datetime.utcnow(),
                }
            }
        )
        
        if result.modified_count > 0:
            print(f"✅ SUCCESS! Scans reset to 0 for {email}")
            print(f"   Reset at: {datetime.utcnow().isoformat()}")
            return True
        else:
            print(f"❌ Failed to reset scans")
            return False
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False
    finally:
        client.close()


def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python admin_upgrade.py <email> <tier>     # Upgrade user")
        print("  python admin_upgrade.py <email> --reset    # Reset scans to 0")
        print()
        print("Examples:")
        print("  python admin_upgrade.py test@example.com pro")
        print("  python admin_upgrade.py test@example.com enterprise")
        print("  python admin_upgrade.py test@example.com --reset")
        sys.exit(1)
    
    email = sys.argv[1]
    
    if len(sys.argv) >= 3 and sys.argv[2] == "--reset":
        print(f"🔄 Resetting scans for {email}...")
        success = asyncio.run(reset_scans(email))
    else:
        tier = sys.argv[2] if len(sys.argv) >= 3 else "pro"
        print(f"🔄 Upgrading {email} to {tier}...")
        success = asyncio.run(upgrade_user(email, tier))
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
