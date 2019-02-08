#!/usr/bin/env python
import sys
import Crypto
import traceback
from Crypto.PublicKey import RSA
for fname in sys.argv[1:]:
    with open (fname, 'rt') as fh:
        pem = fh.read() # slurp
        try:
            rsa = Crypto.PublicKey.RSA.importKey(pem, passphrase=None)
        except Exception as e:
            #traceback.print_exc()
            print fname, "bad", e
            sys.exit(1)

        else:
            print fname, "ok", rsa.size()
sys.exit(0)
