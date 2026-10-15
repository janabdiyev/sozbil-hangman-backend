"""Verifies Sign in with Apple / Google ID tokens (2026-10-14).

Both providers sign their ID tokens (JWTs) with rotating keys published as a
JWKS. We check signature, issuer, audience and expiry, and return the stable
`sub` claim, which is what we store — never the email as an identifier.

Configure with environment variables on Render:
  GOOGLE_CLIENT_IDS  comma-separated OAuth client IDs whose tokens we accept
                     (iOS client ID + Android/web "server" client ID)
  APPLE_AUDIENCES    comma-separated; the iOS bundle id
                     (com.sozbil.app.SozBil) plus the Services ID used for
                     Sign in with Apple on Android, if any
"""
import os

import jwt
from jwt import PyJWKClient
from rest_framework.exceptions import AuthenticationFailed, ValidationError

_PROVIDERS = {
    'google': {
        'jwks': 'https://www.googleapis.com/oauth2/v3/certs',
        'issuers': ['https://accounts.google.com', 'accounts.google.com'],
        'env': 'GOOGLE_CLIENT_IDS',
        'default': '',
    },
    'apple': {
        'jwks': 'https://appleid.apple.com/auth/keys',
        'issuers': ['https://appleid.apple.com'],
        'env': 'APPLE_AUDIENCES',
        'default': 'com.sozbil.app.SozBil',
    },
}
_clients = {}


def _audiences(provider):
    cfg = _PROVIDERS[provider]
    return [a.strip() for a in os.environ.get(cfg['env'], cfg['default']).split(',') if a.strip()]


def verify_id_token(provider, token):
    """Returns (subject, email). Raises AuthenticationFailed on any problem."""
    if provider not in _PROVIDERS:
        raise ValidationError({'provider': 'Use apple or google.'})
    if not isinstance(token, str) or len(token) < 20:
        raise ValidationError({'id_token': 'Missing token.'})
    audiences = _audiences(provider)
    if not audiences:
        raise AuthenticationFailed(f'{provider} sign-in is not configured on the server.')
    cfg = _PROVIDERS[provider]
    client = _clients.get(provider)
    if client is None:
        client = _clients[provider] = PyJWKClient(cfg['jwks'], cache_keys=True, lifespan=3600)
    try:
        key = client.get_signing_key_from_jwt(token).key
        claims = jwt.decode(token, key, algorithms=['RS256'], audience=audiences,
                            issuer=cfg['issuers'], options={'require': ['exp', 'iat', 'sub']},
                            leeway=60)
    except jwt.PyJWTError as e:
        raise AuthenticationFailed(f'Invalid {provider} token: {e}')
    return str(claims['sub']), str(claims.get('email') or '')
