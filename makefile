XRES=640
YRES=480
NASM=nasm
NASMFLAGS=-dImage_Width=$(XRES) -dImage_Height=$(YRES)
SLICES=480

all: raytrace.bmp

demo: demo.bmp

preview: preview.bmp

-include concat.mk

concat.asm: header.bin $(PARTS)
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
		echo "part$$i.bin: raytrace.asm makefile" >> $@ ; \
		echo "	$(NASM) $(NASMFLAGS) -dNo_Header -dLineStart=$$((($$i - 1) * $$lc)) -dLineCount=$$lc raytrace.asm -o \$$@" >> $@ ; \
	done

header.bin: raytrace.asm makefile
	$(NASM) $(NASMFLAGS) -dNo_Bitmap raytrace.asm -o $@

raytrace.bmp: header.bin concat.asm concat.mk
	$(NASM) concat.asm -o $@
	rm -f *.bin

demo.bmp: raytrace.bmp
	rm -f $@
	mv raytrace.bmp $@

preview.bmp: header.bin preview.asm
	$(NASM) preview.asm -o $@
	rm -f preview.asm

preview.asm: makefile
	lc=$$(($(YRES) / $(SLICES))); \
	echo "incbin\"header.bin\"" > $@ ; \
	echo "BitmapStart:" >> $@ ; \
	for i in $$(seq $(SLICES)); \
	do \
		if [ -f "part$$i.bin" ]; then \
			echo "incbin\"part$$i.bin\"" >> $@ ; \
		fi; \
		echo "times ($$i * $$lc * $(XRES) * 3) - ($$ - BitmapStart) db 0" >> $@ ; \
		echo "times 3 - ($$ - BitmapStart - 1) % 4 db 0" >> $@ ; \
	done

clean:
	rm -f *.bin
	rm -f concat.asm
	rm -f concat.mk
	rm -f preview.asm
	rm -f preview.bmp
