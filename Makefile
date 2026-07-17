.PHONY: test build install

test:
	./test.sh

build:
	./build.sh

install:
	./build.sh --install
