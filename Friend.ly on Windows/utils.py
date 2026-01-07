import base64


def xor_encrypt(text, SECRET_KEY):
    encrypted = "".join(
        chr(ord(c) ^ ord(SECRET_KEY[i % len(SECRET_KEY)]))
        for i, c in enumerate(text)
    )
    return base64.b64encode(encrypted.encode()).decode()

def xor_decrypt(encoded, SECRET_KEY):
    decoded = base64.b64decode(encoded).decode()
    return "".join(
        chr(ord(c) ^ ord(SECRET_KEY[i % len(SECRET_KEY)]))
        for i, c in enumerate(decoded)
    )
