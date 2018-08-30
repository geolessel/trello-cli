make: src/trello.cr
	mkdir -p bin
	crystal build --release --stats --progress --time src/trello.cr -o bin/trello
install:
	make
	cp bin/trello /usr/local/bin
uninstall:
	rm /usr/local/bin/trello
clean:
	rm bin/*
