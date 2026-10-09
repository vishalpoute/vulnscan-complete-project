from fastapi import FastAPI
from fastapi.testclient import TestClient
import unittest
from unittest.mock import patch

from routers import auth


def _client() -> TestClient:
    app = FastAPI()
    app.include_router(auth.router, prefix="/api")
    return TestClient(app)


class TestAuthVerify(unittest.TestCase):
    def test_verify_token_success(self):
        def _mock_verify_id_token(token: str):
            self.assertEqual(token, "valid-token")
            return {"uid": "user-123", "email": "user@example.com"}

        with patch.object(auth.firebase_auth, "verify_id_token", _mock_verify_id_token):
            response = _client().post("/api/auth/verify", json={"token": "valid-token"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"uid": "user-123", "email": "user@example.com"})

    def test_verify_token_invalid_token(self):
        def _mock_verify_id_token(token: str):
            raise ValueError("bad token")

        with patch.object(auth.firebase_auth, "verify_id_token", _mock_verify_id_token):
            response = _client().post("/api/auth/verify", json={"token": "invalid-token"})

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["detail"], "Invalid token: bad token")

    def test_verify_token_rejects_blank_token(self):
        response = _client().post("/api/auth/verify", json={"token": "   "})

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["detail"], "Token is required")
