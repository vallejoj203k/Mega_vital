#!/usr/bin/env python3
"""Upload an app preview video to App Store Connect via the REST API.

Required environment variables:
  APP_STORE_CONNECT_KEY_IDENTIFIER  - Key ID de la API key
  APP_STORE_CONNECT_ISSUER_ID       - Issuer ID de App Store Connect
  APP_STORE_CONNECT_PRIVATE_KEY     - Contenido del archivo .p8
  BUNDLE_ID                          - Bundle identifier (ej. com.vallejoj.megavital)
  VIDEO_PATH                         - Ruta local al archivo de video (.mp4 / .mov)

Optional:
  APP_LOCALE          - Locale del listing (default: es-MX)
  PREVIEW_SCREEN_SIZE - Tipo de dispositivo (default: APP_IPHONE_67)
"""

import hashlib
import json
import os
import subprocess
import sys
import time

import requests


BASE_URL = "https://api.appstoreconnect.apple.com/v1"

REQUIRED_VARS = [
    "APP_STORE_CONNECT_KEY_IDENTIFIER",
    "APP_STORE_CONNECT_ISSUER_ID",
    "APP_STORE_CONNECT_PRIVATE_KEY",
    "BUNDLE_ID",
    "VIDEO_PATH",
]

# Tamaños de pantalla válidos para App Preview en App Store Connect
VALID_SCREEN_SIZES = {
    "APP_IPHONE_67",   # iPhone 6.7" (iPhone 14 Pro Max, 15 Pro Max)
    "APP_IPHONE_65",   # iPhone 6.5" (iPhone 11 Pro Max, XS Max)
    "APP_IPHONE_61",   # iPhone 6.1"
    "APP_IPHONE_58",   # iPhone 5.8" (iPhone X, XS)
    "APP_IPHONE_55",   # iPhone 5.5" (iPhone 8 Plus)
    "APP_IPHONE_47",   # iPhone 4.7" (iPhone 8)
    "APP_IPAD_PRO_3GEN_129",  # iPad Pro 12.9" 3rd gen
    "APP_IPAD_PRO_129",       # iPad Pro 12.9"
}


def _install_pyjwt():
    subprocess.check_call(
        [sys.executable, "-m", "pip", "install", "--quiet", "PyJWT", "cryptography"],
    )


def generate_token() -> str:
    try:
        import jwt
    except ImportError:
        print("Instalando PyJWT y cryptography...")
        _install_pyjwt()
        import jwt

    key_id = os.environ["APP_STORE_CONNECT_KEY_IDENTIFIER"]
    issuer_id = os.environ["APP_STORE_CONNECT_ISSUER_ID"]
    private_key = os.environ["APP_STORE_CONNECT_PRIVATE_KEY"]

    return jwt.encode(
        {
            "iss": issuer_id,
            "exp": int(time.time()) + 1200,
            "aud": "appstoreconnect-v1",
        },
        private_key,
        algorithm="ES256",
        headers={"kid": key_id},
    )


def _api(method: str, path: str, token: str, **kwargs):
    url = f"{BASE_URL}/{path}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    resp = getattr(requests, method)(url, headers=headers, **kwargs)
    if not resp.ok:
        print(f"Error {resp.status_code} en {method.upper()} {path}:")
        print(resp.text[:500])
        sys.exit(1)
    return resp.json() if resp.content else None


def get_app_id(token: str, bundle_id: str) -> str:
    data = _api("get", f"apps?filter[bundleId]={bundle_id}", token)
    apps = data.get("data", [])
    if not apps:
        print(f"No se encontró la app con bundle ID: {bundle_id}")
        sys.exit(1)
    return apps[0]["id"]


def get_editable_version_id(token: str, app_id: str) -> str:
    """Retorna el ID de la versión de iOS que esté en edición (no publicada)."""
    read_only_states = {"READY_FOR_SALE", "PROCESSING_FOR_APP_STORE", "PENDING_APPLE_RELEASE"}
    data = _api("get", f"apps/{app_id}/appStoreVersions?filter[platform]=IOS", token)
    versions = data.get("data", [])
    for v in versions:
        if v["attributes"]["appStoreState"] not in read_only_states:
            return v["id"]
    if versions:
        # Tomar la más reciente aunque sea read-only (para casos de primera subida)
        return versions[0]["id"]
    print("No se encontró ninguna versión de App Store para iOS.")
    sys.exit(1)


def get_localization_id(token: str, version_id: str, locale: str) -> str:
    data = _api(
        "get",
        f"appStoreVersions/{version_id}/appStoreVersionLocalizations",
        token,
    )
    locs = data.get("data", [])
    # Buscar el locale exacto, luego cualquier variante de idioma, luego el primero
    for loc in locs:
        if loc["attributes"]["locale"] == locale:
            return loc["id"]
    lang = locale.split("-")[0]
    for loc in locs:
        if loc["attributes"]["locale"].startswith(lang):
            return loc["id"]
    if locs:
        print(f"Locale '{locale}' no encontrado, usando '{locs[0]['attributes']['locale']}'")
        return locs[0]["id"]
    print("No se encontró ninguna localización.")
    sys.exit(1)


def get_or_create_preview_set(token: str, localization_id: str, screen_size: str) -> str:
    data = _api(
        "get",
        f"appStoreVersionLocalizations/{localization_id}/appPreviewSets",
        token,
    )
    for ps in data.get("data", []):
        if ps["attributes"]["previewType"] == screen_size:
            return ps["id"]

    body = {
        "data": {
            "type": "appPreviewSets",
            "attributes": {"previewType": screen_size},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": localization_id}
                }
            },
        }
    }
    result = _api("post", "appPreviewSets", token, json=body)
    return result["data"]["id"]


def reserve_preview_slot(
    token: str, preview_set_id: str, filename: str, file_size: int
) -> dict:
    body = {
        "data": {
            "type": "appPreviews",
            "attributes": {"fileName": filename, "fileSize": file_size},
            "relationships": {
                "appPreviewSet": {
                    "data": {"type": "appPreviewSets", "id": preview_set_id}
                }
            },
        }
    }
    result = _api("post", "appPreviews", token, json=body)
    return result["data"]


def upload_chunks(upload_operations: list, video_path: str):
    with open(video_path, "rb") as f:
        video_bytes = f.read()

    for i, op in enumerate(upload_operations, 1):
        offset = op["offset"]
        length = op["length"]
        url = op["url"]
        req_headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}

        chunk = video_bytes[offset: offset + length]
        resp = requests.put(url, data=chunk, headers=req_headers, timeout=120)
        if not resp.ok:
            print(f"Error subiendo chunk {i}: {resp.status_code}")
            sys.exit(1)
        print(f"  Chunk {i}/{len(upload_operations)} ({length:,} bytes) ✓")


def commit_preview(token: str, preview_id: str, checksum: str):
    body = {
        "data": {
            "type": "appPreviews",
            "id": preview_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
        }
    }
    _api("patch", f"appPreviews/{preview_id}", token, json=body)


def md5_file(path: str) -> str:
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    missing = [v for v in REQUIRED_VARS if not os.environ.get(v)]
    if missing:
        print(f"Faltan variables de entorno: {', '.join(missing)}")
        sys.exit(1)

    video_path = os.environ["VIDEO_PATH"]
    bundle_id = os.environ["BUNDLE_ID"]
    locale = os.environ.get("APP_LOCALE", "es-MX")
    screen_size = os.environ.get("PREVIEW_SCREEN_SIZE", "APP_IPHONE_67")

    if screen_size not in VALID_SCREEN_SIZES:
        print(f"PREVIEW_SCREEN_SIZE inválido: '{screen_size}'")
        print(f"Valores válidos: {', '.join(sorted(VALID_SCREEN_SIZES))}")
        sys.exit(1)

    if not os.path.exists(video_path):
        print(f"Archivo de video no encontrado: {video_path}")
        sys.exit(1)

    file_size = os.path.getsize(video_path)
    filename = os.path.basename(video_path)
    checksum = md5_file(video_path)

    print(f"Video    : {filename}")
    print(f"Tamaño   : {file_size:,} bytes ({file_size / 1_048_576:.1f} MB)")
    print(f"Checksum : {checksum}")
    print(f"Bundle ID: {bundle_id}")
    print(f"Locale   : {locale}")
    print(f"Pantalla : {screen_size}")
    print()

    token = generate_token()
    print("Token JWT generado.")

    app_id = get_app_id(token, bundle_id)
    print(f"App ID          : {app_id}")

    version_id = get_editable_version_id(token, app_id)
    print(f"Version ID      : {version_id}")

    loc_id = get_localization_id(token, version_id, locale)
    print(f"Localization ID : {loc_id}")

    preview_set_id = get_or_create_preview_set(token, loc_id, screen_size)
    print(f"Preview Set ID  : {preview_set_id}")

    preview = reserve_preview_slot(token, preview_set_id, filename, file_size)
    preview_id = preview["id"]
    upload_ops = preview["attributes"]["uploadOperations"]
    print(f"Preview ID      : {preview_id}")
    print(f"Chunks a subir  : {len(upload_ops)}")
    print()

    print("Subiendo video...")
    upload_chunks(upload_ops, video_path)

    commit_preview(token, preview_id, checksum)
    print()
    print(f"Video '{filename}' subido exitosamente a App Store Connect.")
    print(f"Ya puedes verlo en App Store Connect → Tu App → Distribución de la App.")


if __name__ == "__main__":
    main()
