
%ifndef Image_Width
%define Image_Width 640
%endif

%ifndef Image_Height
%define Image_Height 480
%endif

%ifndef LineStart
%define LineStart 0
%endif

%ifndef LineCount
%define LineCount Image_Height
%endif

%ifndef RowStart
%define RowStart 0
%endif

%ifndef RowCount
%define RowCount Image_Width
%endif

%ifndef FixedBits
%define FixedBits 16
%endif

%ifndef RayStepCount
%define RayStepCount 160
%endif

%ifndef SampleDepth
%define SampleDepth 12
%endif

%ifndef GroundOnly
%define GroundOnly 0
%endif

%ifndef No_Header
BITMAPFILEHEADER:
	.bfType			db "BM"
	.bfSize			dd EOF - BITMAPFILEHEADER
	.bfReserved1	dw 0
	.bfReserved2	dw 0
	.bfOffBits		dd BitmapStart

BITMAPINFOHEADER:
	.biSize				dd 40
	.biWidth			dd Image_Width
	.biHeight			dd Image_Height
	.biPlanes			dw 1
	.biBitCount			dw 24
	.biCompression		dd 0
	.biSizeImage		dd 0
	.biXPelsPerMeter	dd 0
	.biYPelsPerMeter	dd 0
	.biClrUsed			dd 0
	.biClrImportant		dd 0
%endif ;No_Header

BitmapStart:
%ifndef No_Bitmap

%assign FixedBase 1 << FixedBits
%assign SqrtBase (1 << (FixedBits / 2))
%define MakeFixed(i) ((i) * FixedBase)
%define FixedToInt(i) ((i) // FixedBase)
%define FixedMul(a,b) (((a) * (b)) // FixedBase)
%define FixedDiv(a,b) (((a) * FixedBase) // (b))

%assign FixedMax ((-1) / 2)
%assign CastEpsilon FixedDiv(1, 20)
%assign CastEpsilon2 FixedDiv(1, 10)

%assign sphere1_x MakeFixed(0)
%assign sphere1_y MakeFixed(2)
%assign sphere1_z MakeFixed(0)
%assign sphere1_r MakeFixed(2)
%assign sphere1_visible 1

%assign sphere2_x MakeFixed(1)
%assign sphere2_y MakeFixed(1)
%assign sphere2_z MakeFixed(2)
%assign sphere2_r MakeFixed(1)
%assign sphere2_visible 1

%assign sphere3_x MakeFixed(-3)
%assign sphere3_y MakeFixed(1)
%assign sphere3_z MakeFixed(0)
%assign sphere3_r MakeFixed(1)
%assign sphere3_visible 1

%assign boundbox_xn MakeFixed(-5)
%assign boundbox_yn MakeFixed(-1)
%assign boundbox_zn MakeFixed(-3)
%assign boundbox_xp MakeFixed(3)
%assign boundbox_yp MakeFixed(5)
%assign boundbox_zp MakeFixed(4)

%define isinisde_bb(x,y,z) (((x) >= boundbox_xn) && ((x) <= boundbox_xp) \
							((y) >= boundbox_yn) && ((y) <= boundbox_yp) \
							((z) >= boundbox_zn) && ((z) <= boundbox_zp))

%if GroundOnly
	%assign sphere1_visible 0
	%assign sphere2_visible 0
	%assign sphere3_visible 0
%elif sphere1_visible == 0 && sphere2_visible == 0 && sphere3_visible == 0
	%assign GroundOnly 1
%endif

%assign result 0
%assign result_index 0

%assign result_r 0
%assign result_g 0
%assign result_b 0

%assign result_x 0
%assign result_y 0
%assign result_z 0
%assign result_w 0

%macro testawayfrom_bb 6
%if GroundOnly
	%assign result 1
%else
	%if %1 < boundbox_xn && %4 <= 0
		%assign result 1
	%elif %1 > boundbox_xp && %4 >= 0
		%assign result 1
	%elif %2 < boundbox_yn && %5 <= 0
		%assign result 1
	%elif %2 > boundbox_yp && %5 >= 0
		%assign result 1
	%elif %3 < boundbox_zn && %6 <= 0
		%assign result 1
	%elif %3 > boundbox_zp && %6 >= 0
		%assign result 1
	%else
		%assign result 0
	%endif
%endif
%endmacro

%macro IntSqrt 1
	%assign %%sqrt_v_bit 15
	%assign %%sqrt_n 0
	%assign %%sqrt_b 0x8000
	%assign %%sqrt_x %1

	%if %%sqrt_x <= 1
		%assign result %1
	%else
		%rep 16
			%assign %%sqrt_temp ((%%sqrt_n <<  1) + %%sqrt_b) << (%%sqrt_v_bit)
			%assign %%sqrt_v_bit %%sqrt_v_bit - 1

			%if %%sqrt_x >= %%sqrt_temp
				%assign %%sqrt_n %%sqrt_n + %%sqrt_b
				%assign %%sqrt_x %%sqrt_x - %%sqrt_temp
			%endif

			%assign %%sqrt_b %%sqrt_b >> 1
		%endrep
		%assign result %%sqrt_n
	%endif
%endmacro

%macro FixedSqrt 1
	IntSqrt %1
	%assign result result * SqrtBase
%endmacro

%macro Min 2
	%if %1 < %2
		%assign result %1
	%else
		%assign result %2
	%endif
%endmacro

%macro Max 2
	%if %1 > %2
		%assign result %1
	%else
		%assign result %2
	%endif
%endmacro

%macro Dot 4-8
	%if %0 == 4
		%assign result FixedMul(%1, %3) + FixedMul(%2, %4)
	%elif %0 == 6
		%assign result FixedMul(%1, %4) + FixedMul(%2, %5) + FixedMul(%3, %6)
	%elif %0 == 8
		%assign result FixedMul(%1, %5) + FixedMul(%2, %6) + FixedMul(%3, %7) + FixedMul(%4, %8)
	%endif
%endmacro

%macro Length 2-4
	%if %0 == 2
		Dot %1, %2, %1, %2
	%elif %0 == 3
		Dot %1, %2, %3, %1, %2, %3
	%elif %0 == 4
		Dot %1, %2, %3, %4, %1, %2, %3, %4
	%endif
	FixedSqrt result
%endmacro

%macro Distance 4-8
	%if %0 == 4
		Length %3 - %1, %4 - %2
	%elif %0 == 6
		Length %4 - %1, %5 - %2, %6 - %3
	%elif %0 == 8
		Length %5 - %1, %6 - %2, %7 - %3, %8 - %4
	%endif
%endmacro

%macro Normalize 2-4
	%if %0 == 2
		Length %1, %2
		Max result, 1
		%assign result_x FixedDiv(%1, result)
		%assign result_y FixedDiv(%2, result)
	%elif %0 == 3
		Length %1, %2, %3
		Max result, 1
		%assign result_x FixedDiv(%1, result)
		%assign result_y FixedDiv(%2, result)
		%assign result_z FixedDiv(%3, result)
	%elif %0 == 4
		Length %1, %2, %3, %4
		Max result, 1
		%assign result_x FixedDiv(%1, result)
		%assign result_y FixedDiv(%2, result)
		%assign result_z FixedDiv(%3, result)
		%assign result_w FixedDiv(%4, result)
	%endif
%endmacro

%macro SDF_Sphere 4
	Length %1, %2, %3
	%assign result - %4
%endmacro

%macro Map_Dist 3
	%assign %%Dist_1 %2
	%assign %%Dist_4 FixedMax
	%assign result_index 0

	%if sphere1_visible
		Distance %1, %2, %3, sphere1_x, sphere1_y, sphere1_z
		%assign %%Dist_2 result - sphere1_r
	%else
		%assign %%Dist_2 FixedMax
	%endif

	%if sphere2_visible
		Distance %1, %2, %3, sphere2_x, sphere2_y, sphere2_z
		%assign %%Dist_3 result - sphere2_r
	%else
		%assign %%Dist_3 FixedMax
	%endif

	%if sphere3_visible
		Distance %1, %2, %3, sphere3_x, sphere3_y, sphere3_z
		%assign %%Dist_4 result - sphere3_r
	%else
		%assign %%Dist_4 FixedMax
	%endif

	%assign result FixedMax
	%if %%Dist_1 < result
		%assign result %%Dist_1
		%if ((%1 / (FixedBase / 2)) & 1) ^ ((%3 / (FixedBase / 2)) & 1)
			%assign result_index 1
		%else
			%assign result_index 5
		%endif
	%endif
	%if %%Dist_2 < result
		%assign result %%Dist_2
		%assign result_index 2
	%endif
	%if %%Dist_3 < result
		%assign result %%Dist_3
		%assign result_index 3
	%endif
	%if %%Dist_4 < result
		%assign result %%Dist_4
		%assign result_index 4
	%endif
%endmacro

%macro Map_Normal 3
	Map_Dist %1, %2, %3
	%if result_index == 1 || result_index == 5
		%assign result_x 0
		%assign result_y FixedBase
		%assign result_z 0
	%elif result_index == 2
		%assign %%normal_x %1 - sphere1_x
		%assign %%normal_y %2 - sphere1_y
		%assign %%normal_z %3 - sphere1_z
		Normalize %%normal_x, %%normal_y, %%normal_z
	%elif result_index == 3
		%assign %%normal_x %1 - sphere2_x
		%assign %%normal_y %2 - sphere2_y
		%assign %%normal_z %3 - sphere2_z
		Normalize %%normal_x, %%normal_y, %%normal_z
	%elif result_index == 4
		%assign %%normal_x %1 - sphere3_x
		%assign %%normal_y %2 - sphere3_y
		%assign %%normal_z %3 - sphere3_z
		Normalize %%normal_x, %%normal_y, %%normal_z
	%endif
%endmacro

%macro Map_Color 3
	Map_Dist %1, %2, %3
	%if result_index == 1
		%assign result_r FixedBase
		%assign result_g FixedBase
		%assign result_b FixedBase
	%elif result_index == 2
		%assign result_r FixedDiv(192,256)
		%assign result_g FixedDiv(256,256)
		%assign result_b 0
	%elif result_index == 3
		%assign result_r 0
		%assign result_g FixedDiv(192,256)
		%assign result_b FixedDiv(256,256)
	%elif result_index == 4
		%assign result_r FixedDiv(256,256)
		%assign result_g 0
		%assign result_b FixedDiv(192,256)
	%elif result_index == 5
		%assign result_r FixedDiv(5, 10)
		%assign result_g FixedDiv(5, 10)
		%assign result_b FixedDiv(5, 10)
	%endif
%endmacro

%macro Ground_Cast 6
	%if %5 == 0
		%assign result -1
	%else
		%assign result FixedDiv(%2, -%5)
	%endif
%endmacro

%macro Map_Cast 6
	%assign %%dist 0
	%assign %%StepCounter 0
	%rep RayStepCount
		testawayfrom_bb %1, %2, %3, %4, %5, %6
		%if result
			%if %5 < 0
				Ground_Cast %1, %2, %3, %4, %5, %6
				%if result < 0
					%assign %%dist -1
				%else
					%assign %%dist %%dist + result
				%endif
			%else
				%assign %%dist -1
			%endif
			%exitrep
		%else
			%assign %%cur_x %1 + FixedMul(%4, %%dist)
			%assign %%cur_y %2 + FixedMul(%5, %%dist)
			%assign %%cur_z %3 + FixedMul(%6, %%dist)
			Map_Dist %%cur_x, %%cur_y, %%cur_z
			%assign %%dist %%dist + result
			%if result <= CastEpsilon
				%exitrep
			%endif
		%endif
		%assign %%StepCounter %%StepCounter + 1
	%endrep
	%if %%StepCounter < RayStepCount
		%assign result %%dist
	%else
		%assign result -1
	%endif
%endmacro

%macro Reflect 6
	Dot %1,%2,%3,%4,%5,%6
	%assign %%n_2 FixedMul(result, MakeFixed(2))
	%assign result_x %1 - FixedMul(%4, %%n_2)
	%assign result_y %2 - FixedMul(%5, %%n_2)
	%assign result_z %3 - FixedMul(%6, %%n_2)
%endmacro

%macro SkyColor 3
	%assign %%y FixedDiv(%2 + FixedBase, MakeFixed(2))
	%assign result_r %%y
	%assign result_g %%y
	%assign result_b %%y
%endmacro

%macro Saturate 3
	%if %1 < 0
		%assign result_r 0
	%elif %1 > FixedBase
		%assign result_r FixedBase
	%else
		%assign result_r %1
	%endif
	%if %2 < 0
		%assign result_g 0
	%elif %2 > FixedBase
		%assign result_g FixedBase
	%else
		%assign result_g %2
	%endif
	%if %3 < 0
		%assign result_b 0
	%elif %3 > FixedBase
		%assign result_b FixedBase
	%else
		%assign result_b %3
	%endif
%endmacro

%macro RenderScene 6
	%assign %%cro_x %1
	%assign %%cro_y %2
	%assign %%cro_z %3
	%assign %%crd_x %4
	%assign %%crd_y %5
	%assign %%crd_z %6
	%assign %%mask_r FixedBase
	%assign %%mask_g FixedBase
	%assign %%mask_b FixedBase
	%rep SampleDepth
		Map_Cast %%cro_x, %%cro_y, %%cro_z, %%crd_x, %%crd_y, %%crd_z
		%if result < 0
			%exitrep
		%else
			%assign %%cast_x %%cro_x + FixedMul(%%crd_x, result)
			%assign %%cast_y %%cro_y + FixedMul(%%crd_y, result)
			%assign %%cast_z %%cro_z + FixedMul(%%crd_z, result)
			Map_Normal %%cast_x, %%cast_y, %%cast_z
			%assign %%cast_nx result_x
			%assign %%cast_ny result_y
			%assign %%cast_nz result_z
			Map_Color %%cast_x, %%cast_y, %%cast_z
			%assign %%mask_r FixedMul(%%mask_r, result_r)
			%assign %%mask_g FixedMul(%%mask_g, result_g)
			%assign %%mask_b FixedMul(%%mask_b, result_b)

			%assign %%cro_x %%cast_x
			%assign %%cro_y %%cast_y
			%assign %%cro_z %%cast_z
			Reflect %%crd_x, %%crd_y, %%crd_z, %%cast_nx, %%cast_ny, %%cast_nz
			Normalize result_x, result_y, result_z
			%assign %%crd_x result_x
			%assign %%crd_y result_y
			%assign %%crd_z result_z

			%assign %%cro_x %%cro_x + FixedMul(%%crd_x, CastEpsilon2)
			%assign %%cro_y %%cro_y + FixedMul(%%crd_y, CastEpsilon2)
			%assign %%cro_z %%cro_z + FixedMul(%%crd_z, CastEpsilon2)
		%endif
	%endrep
	SkyColor %%crd_x, %%crd_y, %%crd_z
	%assign result_r FixedMul(result_r, %%mask_r)
	%assign result_g FixedMul(result_g, %%mask_g)
	%assign result_b FixedMul(result_b, %%mask_b)
	Saturate result_r, result_g, result_b
%endmacro

%assign y LineStart
%rep LineCount
	%assign x RowStart
	%rep RowCount
		%assign ro_x MakeFixed(0)
		%assign ro_y MakeFixed(2)
		%assign ro_z MakeFixed(7)

		%assign iu (x * 2 - Image_Width)
		%assign iv (y * 2 - Image_Height)

		%assign rd_x FixedDiv(iu, Image_Height)
		%assign rd_y FixedDiv(iv, Image_Height)
		%assign rd_z -FixedDiv(175, 100)

		Normalize rd_x, rd_y, rd_z
		%assign rd_x result_x
		%assign rd_y result_y
		%assign rd_z result_z

		RenderScene ro_x, ro_y, ro_z, rd_x, rd_y, rd_z
		db FixedToInt(result_b * 255)
		db FixedToInt(result_g * 255)
		db FixedToInt(result_r * 255)

		%assign x x+1
	%endrep
	times 3 - ($ - $$ - 1) % 4 db 0
	%assign y y+1
%endrep

%endif ; No_Bitmap
EOF:

