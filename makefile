CC = /usr/local/share/npm/bin/coffee

all:	source/*.coffee
	$(CC) -c -m -o compiled source/*.coffee shaders/*.coffee
	cp source/*.coffee shaders/*.coffee compiled/

dist:	all
	mkdir -p dist/compiled
	mkdir -p dist/external
	cp index.html index.js style.css dist/
	cp compiled/*.js dist/compiled/
	cp external/*.js dist/external/
	cp LICENSE dist/
