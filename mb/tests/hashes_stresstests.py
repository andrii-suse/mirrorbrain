import unittest

import mb.hashes
import time

class TestStressHashBag(unittest.TestCase):

    def test_Hashbag200M(self):
        hb = mb.hashes.HashBag('tests/data/file200M')
        hb.do_zsync_hashes = False
        hb.do_chunked_hashes = True
        hb.do_chunked_with_zsync = False

        hb.chunk_size = mb.hashes.DEFAULT_PIECESIZE
        hb.fill()
        print(hb.dump_raw())

if __name__ == '__main__':
    unittest.main()
