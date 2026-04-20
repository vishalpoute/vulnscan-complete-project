"""Firebase Firestore integration for user data storage."""

import firebase_admin
from firebase_admin import credentials, firestore
from .config import settings
import json
from datetime import datetime


class FirestoreDB:
    """Firestore database manager."""

    db = None
    initialized = False

    @classmethod
    def initialize(cls):
        """Initialize Firebase Admin SDK and Firestore."""
        try:
            if not firebase_admin._apps:
                # Parse Firebase credentials from env
                cred_dict = {
                    "type": "service_account",
                    "project_id": settings.FIREBASE_PROJECT_ID,
                    "private_key_id": "key-id",
                    "private_key": settings.FIREBASE_PRIVATE_KEY.replace('\\n', '\n'),
                    "client_email": settings.FIREBASE_CLIENT_EMAIL,
                    "client_id": "client-id",
                    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                    "token_uri": "https://oauth2.googleapis.com/token",
                    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk.iam.gserviceaccount.com"
                }
                
                cred = credentials.Certificate(cred_dict)
                firebase_admin.initialize_app(cred)
            
            cls.db = firestore.client()
            cls.initialized = True
            print("✓ Firestore initialized")
            return True
        except Exception as e:
            print(f"⚠ Firestore initialization failed: {e}")
            cls.initialized = False
            return False

    @classmethod
    def get_db(cls):
        """Get Firestore client instance."""
        if not cls.initialized:
            cls.initialize()
        return cls.db

    @classmethod
    async def update_user_subscription(cls, user_email: str, tier: str):
        """
        Update user subscription tier in Firestore.
        """
        try:
            if not cls.initialized:
                cls.initialize()
            
            # Query users collection by email
            users_ref = cls.db.collection('users')
            docs = users_ref.where('email', '==', user_email).stream()
            
            found = False
            for doc in docs:
                found = True
                # Update subscription tier
                doc.reference.update({
                    'subscription': tier,
                    'tier': tier,
                    'upgraded_at': datetime.utcnow(),
                    'admin_upgraded': True,
                })
                print(f"✅ Updated {user_email} to {tier} in Firestore")
                return True
            
            if not found:
                print(f"⚠ User {user_email} not found in Firestore")
                # Try to create user document if it doesn't exist
                # This happens when upgrading new users before they log in
                return False
                
        except Exception as e:
            print(f"❌ Firestore error updating subscription: {e}")
            return False

    @classmethod
    async def reset_user_scans(cls, user_email: str):
        """
        Reset user's scan count in Firestore.
        """
        try:
            if not cls.initialized:
                cls.initialize()
            
            # Query users collection by email
            users_ref = cls.db.collection('users')
            docs = users_ref.where('email', '==', user_email).stream()
            
            found = False
            for doc in docs:
                found = True
                # Reset scans_used
                doc.reference.update({
                    'scans_used': 0,
                    'scans_reset_at': datetime.utcnow(),
                })
                print(f"✅ Reset scans for {user_email} in Firestore")
                return True
            
            if not found:
                print(f"⚠ User {user_email} not found in Firestore")
                return False
                
        except Exception as e:
            print(f"❌ Firestore error resetting scans: {e}")
            return False

    @classmethod
    async def create_user_document(cls, uid: str, email: str, display_name: str = None):
        """
        Create a new user document in Firestore.
        """
        try:
            if not cls.initialized:
                cls.initialize()
            
            user_doc = {
                'uid': uid,
                'email': email,
                'displayName': display_name or email.split('@')[0],
                'subscription': 'free',
                'tier': 'free',
                'scans_used': 0,
                'scans_limit': 5,
                'created_at': datetime.utcnow(),
                'updated_at': datetime.utcnow(),
            }
            
            cls.db.collection('users').document(uid).set(user_doc)
            print(f"✅ Created user document for {email} in Firestore")
            return True
            
        except Exception as e:
            print(f"❌ Firestore error creating user: {e}")
            return False

    @classmethod
    async def get_user(cls, uid: str):
        """
        Get user document from Firestore.
        """
        try:
            if not cls.initialized:
                cls.initialize()
            
            doc = cls.db.collection('users').document(uid).get()
            if doc.exists:
                return doc.to_dict()
            return None
            
        except Exception as e:
            print(f"❌ Firestore error fetching user: {e}")
            return None
