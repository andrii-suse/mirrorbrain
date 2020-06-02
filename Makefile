
test_mb:
	 ( cd mb && PYTHONPATH=. python3 -m unittest discover -p '*_tests.py' tests -v )

# this needs to generate big file
test_mb_stress:
	 [ -f mb/tests/data/file200M ] || ! which fallocate || fallocate -l 200M mb/tests/data/file200M
	 [ -f mb/tests/data/file200M ] || dd if=/dev/zero of=./mb/tests/data/file200M bs=4K iflag=fullblock,count_bytes count=200M
	 ( cd mb && PYTHONPATH=. python3 -m unittest discover -p '*stresstests.py' tests -v )

test_docker:
	bash t/test_docker.sh

test_environs:
	bash t/test_environs.sh

build_install:
	meson setup build
	meson configure --prefix=/usr --datadir=/usr/share -Dmemcached=false -Dinstall-icons=false build
	ninja -v -C build
	rm -rf build
	meson setup build
	meson configure --prefix=/usr --datadir=/usr/share -Dmemcached=true -Dinstall-icons=false build
	ninja -v -C build
	DESTDIR=$(DESTDIR) ninja -v -C build install
