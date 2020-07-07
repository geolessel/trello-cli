OPENSSL_DIR = $(shell brew --prefix openssl)
NCURSES_DIR = $(shell brew --prefix ncurses)
PKG_CONFIG_PATH = "$(NCURSES_DIR)/lib/pkgconfig:$(OPENSSL_DIR)/lib/pkgconfig"
LDFLAGS = "-L$(NCURSES_DIR)/lib"

make: src/trello.cr
	mkdir -p bin
	shards
	LDFLAGS=$(LDFLAGS) PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) crystal build --release --stats --progress --time src/trello.cr -o bin/trello
install:
	make
	cp bin/trello /usr/local/bin
uninstall:
	rm /usr/local/bin/trello
clean:
	rm bin/*
run:
	LDFLAGS=$(LDFLAGS) PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) crystal run src/trello.cr
