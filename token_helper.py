"""
Token generator helper for Phoenix Realtime Chat.
Use this snippet in your Python backend (FastAPI, Flask, Django)
to generate connection tokens for your frontend clients.
"""
import time
import json
import base64
import hmac
import hashlib


def generate_chat_token(
    user_id: str,
    username: str,
    name: str,
    is_admin: bool = False,
    secret_key: str = "dev-only-change-me",
    ttl_seconds: int = 3600,
) -> str:
    """
    Generates a secure, time-limited HMAC-SHA256 token expected by RealtimeChatWeb.UserSocket.
    """
    claims = {
        "sub": str(user_id),
        "name": name,
        "username": username,
        "admin": is_admin,
        "exp": int(time.time()) + ttl_seconds,
    }
    part = base64.urlsafe_b64encode(json.dumps(claims).encode()).rstrip(b"=").decode()
    sig = hmac.new(secret_key.encode(), f"chat.{part}".encode(), hashlib.sha256).digest()
    sig_b64 = base64.urlsafe_b64encode(sig).rstrip(b"=").decode()
    return f"{part}.{sig_b64}"


if __name__ == "__main__":
    demo_token = generate_chat_token(
        user_id="11111111-2222-3333-4444-555555555555",
        username="john_doe",
        name="John Doe",
        is_admin=False,
    )
    print("Generated Chat Token:")
    print(demo_token)
    print("\nConnect URL:")
    print(f"ws://localhost:4000/socket?token={demo_token}")
