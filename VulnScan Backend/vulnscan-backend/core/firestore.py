"""Firebase Firestore integration for user data storage."""

from datetime import datetime

from firebase_admin import firestore

from .security import initialize_firebase_admin


class FirestoreDB:
    """Firestore database manager."""

    db = None
    initialized = False

    @classmethod
    def initialize(cls) -> bool:
        """Initialize Firebase Admin SDK and Firestore."""
        if cls.initialized and cls.db is not None:
            return True

        try:
            if not initialize_firebase_admin():
                cls.initialized = False
                return False

            cls.db = firestore.client()
            cls.initialized = True
            print("✓ Firestore initialized")
            return True
        except Exception as exc:
            print(f"⚠ Firestore initialization failed: {exc}")
            cls.db = None
            cls.initialized = False
            return False

    @classmethod
    def get_db(cls):
        """Get Firestore client instance, initializing it if possible."""
        if not cls.initialized:
            cls.initialize()
        return cls.db

    @classmethod
    async def update_user_subscription(cls, user_email: str, tier: str) -> bool:
        """Update user subscription tier in Firestore."""
        try:
            if not cls.initialize():
                return False

            users_ref = cls.db.collection("users")
            docs = users_ref.where("email", "==", user_email).stream()

            for doc in docs:
                doc.reference.update(
                    {
                        "subscription": tier,
                        "tier": tier,
                        "upgraded_at": datetime.utcnow(),
                        "admin_upgraded": True,
                    }
                )
                print(f"✅ Updated {user_email} to {tier} in Firestore")
                return True

            print(f"⚠ User {user_email} not found in Firestore")
            return False

        except Exception as exc:
            print(f"❌ Firestore error updating subscription: {exc}")
            return False

    @classmethod
    async def reset_user_scans(cls, user_email: str) -> bool:
        """Reset user's scan count in Firestore."""
        try:
            if not cls.initialize():
                return False

            users_ref = cls.db.collection("users")
            docs = users_ref.where("email", "==", user_email).stream()

            for doc in docs:
                doc.reference.update(
                    {
                        "scans_used": 0,
                        "scans_reset_at": datetime.utcnow(),
                    }
                )
                print(f"✅ Reset scans for {user_email} in Firestore")
                return True

            print(f"⚠ User {user_email} not found in Firestore")
            return False

        except Exception as exc:
            print(f"❌ Firestore error resetting scans: {exc}")
            return False

    @classmethod
    async def create_user_document(cls, uid: str, email: str, display_name: str | None = None) -> bool:
        """Create or update a user document in Firestore."""
        try:
            if not cls.initialize():
                return False

            user_doc = {
                "uid": uid,
                "email": email,
                "displayName": display_name or email.split("@")[0],
                "subscription": "free",
                "tier": "free",
                "scans_used": 0,
                "scans_limit": 5,
                "updated_at": datetime.utcnow(),
            }

            doc_ref = cls.db.collection("users").document(uid)
            existing = doc_ref.get()
            if existing.exists:
                doc_ref.update(user_doc)
            else:
                user_doc["created_at"] = datetime.utcnow()
                doc_ref.set(user_doc)

            print(f"✅ Synced user document for {email} in Firestore")
            return True

        except Exception as exc:
            print(f"❌ Firestore error creating user: {exc}")
            return False

    @classmethod
    async def get_user(cls, uid: str):
        """Get user document from Firestore."""
        try:
            if not cls.initialize():
                return None

            doc = cls.db.collection("users").document(uid).get()
            if doc.exists:
                return doc.to_dict()
            return None

        except Exception as exc:
            print(f"❌ Firestore error fetching user: {exc}")
            return None
