name 	= Backpack
version = $(shell  git describe master| cut -d- -f1,2)
archive = $(name)-$(version).zip


all: $(archive)

$(archive): 
	git archive --format zip --output $(archive) --prefix=Backpack/ master
	
.PHONY: clean
clean:
	rm -f $(archive)