import sys
import math
from eth_abi import encode

x = float(sys.argv[1]) / 2**64
y = math.exp(x)

assert y < 2**64, f"x = {x}"
y = int(y * 2**64)

y = "0x" + encode(["int128"], [y]).hex()
print(y)

