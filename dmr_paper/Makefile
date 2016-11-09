OUT = main

all: $(OUT).ps $(OUT).pdf clean

$(OUT).dvi: $(wildcard *.tex *.bib *.cls *.eps *.jpg) 
	latex $*
	bibtex $*
	latex $*
	latex $*

# -j0 -G0: embed all fonts
$(OUT).ps: $(OUT).dvi 
	dvips -Ppdf -t letter -j0 -G0 -o $@ $<

# -d options: embed all fonts (use 'pdffonts' util to verify)
$(OUT).pdf: $(OUT).ps
	ps2pdf -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress $<

clean:
	rm -f *~ *.aux *.dvi *.bbl *.blg *.log *.ps
