OUT = main

all:  $(OUT) clean

$(OUT):  $(wildcard *.tex *.bib *.cls *.eps *.jpg)
	xelatex $@
#	bibtex $@
	xelatex $@
	xelatex $@
	evince main.pdf&

clean:
	rm -f *~ *.toc *.aux *.dvi *.bbl *.blg *.log *.out  
