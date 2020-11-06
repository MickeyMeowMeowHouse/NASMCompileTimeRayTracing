# NASM Compile-Time Ray-Tracing Demo
Ray-tracing rendering technique achieved by using NASM macros. Rendering is done during compile time. The compiler outputs a BMP file.

![Demo](https://raw.githubusercontent.com/0xAA55/NASMCompileTimeRayTracing/main/demo.bmp)

# How to compile
## Prerequisite
First, you need the [NASM](https://nasm.us/) compiler. To install the NASM compiler under Linux you can use `apt-get`, `yum`, `pacman`, etc.

The source code was designed to be compiled by using `makefile` under `bash` in order to compile the file concurrently. If you don't have the environment, simply running `nasm raytrace.asm -o raytrace.bmp` to compile if you have `nasm` available.

The NASM compiler here isn't used for compiling machine codes. It's used to generate a BMP file struct directly, and it renders the scene during compiling.

## Concurrent compiling and memory usage
During compiling/rendering, there will be a huge amount of RAM consumed by the compiler. You have to check out the first few lines of `makefile` to adjust the configurations.

Pay attention to the option `SLICES` of `makefile`, it's used for the ability to run multiple NASM compiler together to produce the scene quickly, and the option `SLICES` is the maximum count of the running processes of the compiler when the makefile is able to do concurrent compiling by having `-j` option. But since the compilation consumes huge memory, more slices with a lower `-j` number is suggested. **Note** that `YRES` must be integer times of `SLICES` to produce a correct BMP file.

For example, set the resolution to 640x480, and set `SLICES` to 480, then run `make -j4`, the scene will be generated and the usage of memory is up to 32GB.

## Preview
When compiling is slowly proceeding, it's able to check the preview of the scene by running `make preview`. The script tries to composite the picture by concatenating the pieces and create a picture file out of them. You can then view `preview.bmp` to have a quick peek of the rendering picture.
