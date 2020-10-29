XRES=640
YRES=480
ASMFLAGS=-dImage_Width=$(XRES) -dImage_Height=$(YRES) -Z report.log
SLICES=240

all: raytrace.bmp

-include concat.mk

concat.asm: makefile header.bin $(PARTS)
	echo "incbin\"header.bin\"" > $@
	for i in $$(seq $(SLICES)); \
	do \
		echo "incbin\"part$$i.bin\"" >> $@ ; \
	done

concat.mk: makefile
	lc=$$(($(YRES) / $(SLICES))); \
	echo "PARTS=" > $@; \
	for i in $$(seq $(SLICES)); \
	do \
		echo "PARTS+=part$$i.bin" >> $@; \
	done; \
	for i in $$(seq $(SLICES)); \
	do \
		echo "part$$i.bin: raytrace.asm" >> $@ ; \
		echo "	nasm $(ASMFLAGS) -dNo_Header -dLineStart=$$((($$i - 1) * $$lc)) -dLineCount=$$lc $$^ -o \$$@" >> $@ ; \
	done

header.bin: raytrace.asm
	nasm $(ASMFLAGS) -dNo_Bitmap $^ -o $@

raytrace.bmp: header.bin concat.asm concat.mk
	nasm concat.asm -o $@
	rm -f *.bin

clean:
	rm -f *.bin
	rm -f concat.asm
	rm -f concat.mk
