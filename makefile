XRES=640
YRES=480
PIECES=64
SLICES=48
NASM=nasm
NASMFLAGS=-dImage_Width=$(XRES) -dImage_Height=$(YRES)

all: raytrace.bmp

demo: demo.bmp

preview: preview.bmp

clean:
	rm -f *.bin
	rm -f concat.asm
	rm -f concat.mk
	rm -f preview.asm
	rm -f preview.bmp
	rm -f parts/part*.bmp

-include concat.mk

concat.asm: makefile
	echo "incbin\"header.bin\"" > $@ ; \
	echo "%assign HeaderSize $$ - \$$\$$" >> $@ ; \
	echo "BitmapStart:" >> $@ ; \
	pitch=$$(((($(XRES) * 3 - 1) / 4 + 1) * 4)); \
	if [ "$(PIECES)" -gt "1" ]; then \
		rc=$$(($(XRES) / $(PIECES))); \
		lc=$$(($(YRES) / $(SLICES))); \
		rl=$$(($$rc * 3)); \
		partpitch=$$(((($$rl - 1) / 4 + 1) * 4)); \
		for y in $$(seq $(YRES)); \
		do \
			j=$$((($$y - 1) / $$lc + 1)); \
			ls=$$(((($$y - 1) % $$lc) * $$partpitch)); \
			echo "Line$$y:" >> $@ ; \
			for i in $$(seq $(PIECES)); \
			do \
				echo "	.Row$$i:" >> $@ ; \
				echo "	incbin\"parts/part$$i,$$j.bmp\", HeaderSize + $$ls, $$rl" >> $@ ; \
			done; \
			echo "	times $$pitch - ($$ - Line$$y ) db 0" >> $@ ; \
		done; \
	else \
		for i in $$(seq $(SLICES)); \
		do \
			echo "incbin\"parts/part$$i.bmp\", HeaderSize" >> $@ ; \
		done; \
	fi

concat.mk: makefile
	mkdir -p parts ; \
	if [ "$(PIECES)" -gt "1" ]; then \
		rc=$$(($(XRES) / $(PIECES))); \
		lc=$$(($(YRES) / $(SLICES))); \
		echo "PARTS=" > $@; \
		for j in $$(seq $(SLICES)); \
		do \
			for i in $$(seq $(PIECES)); \
			do \
				echo "PARTS+=parts/part$$i,$$j.bmp" >> $@; \
			done; \
		done; \
		for j in $$(seq $(SLICES)); \
		do \
			for i in $$(seq $(PIECES)); \
			do \
				echo "parts/part$$i,$$j.bmp: raytrace.asm makefile" >> $@ ; \
				echo "	$(NASM) $(NASMFLAGS) -dRowStart=$$((($$i - 1) * $$rc)) -dLineStart=$$((($$j - 1) * $$lc)) -dRowCount=$$rc -dLineCount=$$lc raytrace.asm -o \$$@" >> $@ ; \
			done; \
		done; \
	else \
		lc=$$(($(YRES) / $(SLICES))); \
		echo "PARTS=" > $@; \
		for i in $$(seq $(SLICES)); \
		do \
			echo "PARTS+=parts/part$$i.bmp" >> $@; \
		done; \
		for i in $$(seq $(SLICES)); \
		do \
			echo "parts/part$$i.bmp: raytrace.asm makefile" >> $@ ; \
			echo "	$(NASM) $(NASMFLAGS) -dLineStart=$$((($$i - 1) * $$lc)) -dLineCount=$$lc raytrace.asm -o \$$@" >> $@ ; \
		done; \
	fi

header.bin: raytrace.asm makefile
	$(NASM) $(NASMFLAGS) -dNo_Bitmap raytrace.asm -o $@

raytrace.bmp: header.bin concat.asm concat.mk $(PARTS)
	$(NASM) concat.asm -o $@

demo.bmp: raytrace.bmp
	rm -f $@
	cp raytrace.bmp $@

preview.bmp: header.bin preview.asm
	$(NASM) preview.asm -o $@
	rm -f preview.asm

preview.asm: makefile
	pitch=$$(((($(XRES) * 3 - 1) / 4 + 1) * 4)); \
	if [ "$(PIECES)" -gt "1" ]; then \
		rc=$$(($(XRES) / $(PIECES))); \
		lc=$$(($(YRES) / $(SLICES))); \
		rl=$$(($$rc * 3)); \
		partpitch=$$(((($$rl - 1) / 4 + 1) * 4)); \
		echo "incbin\"header.bin\"" > $@ ; \
		echo "%assign HeaderSize $$ - \$$\$$" >> $@ ; \
		echo "BitmapStart:" >> $@ ; \
		for y in $$(seq $(YRES)); \
		do \
			j=$$((($$y - 1) / $$lc + 1)); \
			ls=$$(((($$y - 1) % $$lc) * $$partpitch)); \
			echo "Line$$y:" >> $@ ; \
			for i in $$(seq $(PIECES)); \
			do \
				echo "	.Row$$i:" >> $@ ; \
				if [ -f "parts/part$$i,$$j.bmp" ]; then \
					echo "	incbin\"parts/part$$i,$$j.bmp\", HeaderSize + $$ls, $$rl" >> $@ ; \
				fi; \
				echo "	times $$rl - ($$ - .Row$$i ) db 0" >> $@ ; \
			done; \
			echo "	times $$pitch - ($$ - Line$$y ) db 0" >> $@ ; \
		done; \
	else \
		lc=$$(($(YRES) / $(SLICES))); \
		echo "incbin\"header.bin\"" > $@ ; \
		echo "%assign HeaderSize $$ - \$$\$$" >> $@ ; \
		echo "BitmapStart:" >> $@ ; \
		for i in $$(seq $(SLICES)); \
		do \
			echo "Line$$i:" >> $@ ; \
			if [ -f "parts/part$$i.bmp" ]; then \
				echo "incbin\"parts/part$$i.bmp\", HeaderSize" >> $@ ; \
			fi; \
			echo "times $$pitch - ($$ - Line$$i ) db 0" >> $@ ; \
		done; \
	fi
