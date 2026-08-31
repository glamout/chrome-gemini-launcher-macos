.PHONY: test install uninstall

test:
	bash -n bin/chrome-gemini install.sh uninstall.sh tests/test.sh
	./tests/test.sh

install:
	./install.sh

uninstall:
	./uninstall.sh

