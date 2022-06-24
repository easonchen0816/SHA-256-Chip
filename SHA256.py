import hashlib

s = hashlib.sha256()

data = ""
s.update(data)
h = s.hexdigest()
print(h)
