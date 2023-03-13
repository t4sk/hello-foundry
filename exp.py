import sys
import math

def encode_to_hex(y):
    h = (("0" * 64) + hex(y)[2:])[-64:]
    return f"0x{h}"

# print(sys.argv)

x = float(sys.argv[1])
y = math.exp(x)

y = encode_to_hex(int(y))
print(y)

