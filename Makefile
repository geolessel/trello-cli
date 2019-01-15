make: src/trello.cr
	mkdir -p bin
	shards
	crystal build --release --stats --progress --time src/trello.cr -o bin/trello
install:
	make
	cp bin/trello /usr/local/bin
uninstall:
	rm /usr/local/bin/trello
clean:
	rm bin/*
run:
	LDFLAGS="-L/usr/local/opt/ncurses/lib" PKG_CONFIG_PATH="/usr/local/opt/ncurses/lib/pkgconfig:/usr/local/opt/openssl/lib/pkgconfig" crystal run src/trello.cr
