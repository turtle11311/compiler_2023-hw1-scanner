SCANNER = scanner
CC      = gcc
CFLAGS  = -Wall -Wextra -pedantic -g3
LEX     = flex
LIBS    = -lfl

all: $(SCANNER)

$(SCANNER): src/$(SCANNER)
	cp $^ $@

src/$(SCANNER):
	make $(SCANNER) -C src/

prepare:
	# we have installed the package meet the basic needs
	# you can prepare the extra package you need here, e.g.
	#apt install clang
	#apt install g++

test: all
	make test -C test/

pack:
	make clean
	zip -r icd22-hw1.zip . -x ".*" -x "*.zip" -x "test/*"

.PHONY: clean

clean:
	make clean -C test/
	make clean -C src/
	$(RM) $(SCANNER)

DOCKERHUB_ACCOUNT=plaslab
IMAGE_NAME = compiler-f20-hw1
DOCKER_IMG = ${DOCKERHUB_ACCOUNT}/${IMAGE_NAME}:latest

pull:
	docker pull ${DOCKER_IMG}
