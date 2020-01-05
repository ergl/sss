.PHONY: compile clean

all: compile

compile:
	ponyc -o _build -b sss sss/

clean:
	rm -rf _build
