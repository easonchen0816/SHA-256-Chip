import hashlib

f = open("input1.txt", "r")
inputs = f.readlines()
f.close
f = open("output1.txt", "w")
for i in range(len(inputs)):
    if i == len(inputs)-1:
        data = inputs[i]
        s = hashlib.sha256()
        s.update(data.encode("utf-8"))
        h = s.hexdigest()
        f.write(h)
        break
    data = inputs[i][0:-1]
    s = hashlib.sha256()
    s.update(data.encode("utf-8"))
    h = s.hexdigest()
    f.write(h + "\n")
f.close


