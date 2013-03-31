CC = /usr/local/share/npm/bin/coffee

all:	source/*.coffee
	$(CC) -c -m -o compiled source/*.coffee
	cp source/*.coffee compiled/

