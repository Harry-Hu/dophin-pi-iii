#!/bin/bash

#
# For build dophin-pi linux qt system
#
# Author : Harry
#

echo "Dophin-PI Linux-QT build system!"

# Env
TOP_DIR=`pwd`
KERNE_DIR=$TOP_DIR/linux-3.4
MODULE_DIR=$TOP_DIR/vendor/module
QT_DIR=$TOP_DIR/qt-everywhere-opensource-src-4.8.6
QT_INSTALL_DIR=$QT_DIR/instal
MINIGUI_DIR=$TOP_DIR/minigui-3.0.12
MINIGUI_CORE_DIR=$MINIGUI_DIR/libminigui
MINIGUI_SAMPLE_DIR=$MINIGUI_DIR/mg-samples
MINIGUI_RES_DIR=$MINIGUI_DIR/minigui-res-be
UBOOT_DIR=$TOP_DIR/u-boot-2011.09
TSLIB_DIR=$TOP_DIR/tslib
NCNN_DIR=$TOP_DIR/ncnn
LIBPNG_DIR=$TOP_DIR/libpng
MP4V2_DIR=$TOP_DIR/mp4v2-2.0.0
FFMPEG_DIR=$TOP_DIR/ffmpeg
MEDIA_LIBS_DIR=$TOP_DIR/libs
MEDIA_CORE_LIBS_DIR=$TOP_DIR/libs/core_server
ZLIB_DIR=$TOP_DIR/zlib
CORE_SERVER_DIR=$TOP_DIR/core
BUSYBOX_DIR=$TOP_DIR/busybox-1.27.2
LIBGCC_DIR=$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/arm-linux-gnueabi/libc/lib
PACK_DIR=$TOP_DIR/tools/pack
APP_DIR=$TOP_DIR/app
OUT_DIR=$TOP_DIR/target
BIN_OUT_DIR=$OUT_DIR/bin
LIB_OUT_DIR=$OUT_DIR/lib
INC_OUT_DIR=$OUT_DIR/include
ROOTFS_DIR=$OUT_DIR/rootfs

echo $TOP_DIR

# Export the gcc tools
export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$PATH
#$TOP_DIR/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin
#$TOP_DIR/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabi/bin:
#$TOP_DIR/gcc-linaro/bin:
##$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin

# Make a dir to save image
rm -rf $OUT_DIR
mkdir $OUT_DIR
mkdir $BIN_OUT_DIR
mkdir $LIB_OUT_DIR
mkdir $INC_OUT_DIR
mkdir $ROOTFS_DIR


#
# Build busybox
#
function build_busybox()
{
	echo "==========Start Build busybox=========="

	cd $BUSYBOX_DIR

	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin:$PATH

	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- distclean
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- dophin_pi_defconfig
	if [ $? != "0" ] ; then 
		echo "Build busybox error"
		exit 1
	fi

	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4
	
	if [ $? != "0" ] ; then 
		echo -e '\033[0;31;1m'
		echo "Build busybox error"
		echo -e '\033[0m'
		exit 1
	fi
	
	make install
	if [ $? != "0" ] ; then 
		echo "Build busybox error"
		exit 1
	fi

	# Only busybox file will copy to rootfs dir after build
	cp -r ./_install/*  $ROOTFS_DIR
	# Copy etc
	cp -r ./examples/bootfloppy/etc $ROOTFS_DIR

	echo "==========Build busybox success=========="
}

#
# Build uboot
#
function build_uboot()
{
	cd $UBOOT_DIR
	echo `pwd`

	echo "==========Start Build u-boot=========="

	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro/bin:$PATH
#$TOP_DIR/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin
#$TOP_DIR/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabi/bin:
#$TOP_DIR/gcc-linaro/bin:
##$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin


	make distclean CROSS_COMPILE=arm-linux-gnueabi-
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- sun8iw8p1_nor_config
	if [ $? != "0" ] ; then
		echo "Build u-boot error!!"
		exit
	fi

	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4
	if [ $? != "0" ] ; then
		echo "Build u-boot error!!"
		exit
	fi

	make distclean CROSS_COMPILE=arm-linux-gnueabi-
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- sun8iw8p1_config
	if [ $? != "0" ] ; then
		echo "Build u-boot error!!"
		exit
	fi

	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j4
	if [ $? != "0" ] ; then
		echo "Build u-boot error!!"
		exit
	fi


	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- spl
	if [ $? != "0" ] ; then
		echo "Build u-boot error!!"
		exit
	fi

	make -j4 fes CROSS_COMPILE=arm-linux-gnueabi-
	if [ $? != "0" ] ; then
		echo "Build u-boot error!!"
		exit
	fi


	echo "==========Build u-boot Success=========="
}

#
# Build kernel
#
function build_kernel()
{
	cd $KERNE_DIR
	echo "==========Start Build Kernel=========="

#	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin:$PATH
	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro/bin:$PATH
#$TOP_DIR/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin
#$TOP_DIR/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabi/bin:
#$TOP_DIR/gcc-linaro/bin
##$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin

	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- sun8iw8p1smp_tiger_cdr_defconfig
	if [ $? != "0" ] ; then
		echo "Build kernel error!!"
		exit
	fi

	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- clean
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- uImage -j4
#	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- all -j4

	if [ $? != "0" ] ; then
		echo "Build kernel error!!"
		exit
	fi

	cp arch/arm/boot/uImage $BIN_OUT_DIR

	echo "==========Build kernel Success=========="
}

#
# Build ts-lib
#
function build_tslib()
{
	echo "==========Start Build tslib=========="

	cd $TSLIB_DIR
	
	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin:$PATH
	
	rm -rf instal
    mkdir instal

	./autogen.sh
        ./configure --host=arm-linux ac_cv_func_malloc_0_nonnull=yes \
		 --enable-linear=static --enable-input=static \
		 --enable-pthres=static --enable-variance=static --enable-dejitter=static \
		-prefix=$TSLIB_DIR/instal CC=arm-linux-gnueabi-gcc 

	make clean
	make -j4
	make install

	if [ $? = "0" ] ; then
		echo "Build tslib success"
		cp -r instal/lib/*  $LIB_OUT_DIR
		cp -r instal/include/*  $INC_OUT_DIR
		cp -r instal/bin/*  $BIN_OUT_DIR
	else
		echo "Build ts lib error!!"
		exit 1
	fi
} 

#
# Build qt
#
function build_qt()
{
	echo "==========Start Build QT=========="

	if [ ! -d "$QT_DIR" ]; then
		tar xzvf qt-everywhere-opensource-src-4.8.6.gz
	fi
	
	cd $QT_DIR

	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin:$PATH

	rm -rf instal
	mkdir instal
#	make distclean

	./configure \
	-prefix $QT_DIR/instal \
	-confirm-license \
	-embedded arm \
	-xplatform qws/arm-linux-gnueabi-g++ \
	-release \
	-opensource  \
	-fast  \
	-no-accessibility  \
	-no-scripttools  \
	-no-mmx  \
	-no-declarative-debug \
	-no-multimedia  \
	-no-svg  \
	-no-3dnow  \
	-no-avx \
	-no-sse  \
	-no-sse2  \
	-no-libmng  \
	-no-libtiff  \
	-no-multimedia  \
	-silent  \
	-qt-libpng  \
	-qt-libjpeg  \
	-make libs  \
	-nomake translations \
	-no-nis \
	-no-cups \
	-no-iconv  \
	-no-pch \
	-no-dbus  \
	-no-gtkstyle \
	-no-nas-sound \
	-no-openvg \
	-no-openssl  \
	-no-opengl \
	-little-endian \
	-qt-freetype  \
	-depths all \
	-qt-gfx-linuxfb  \
	-no-gfx-transformed  \
	-no-gfx-multiscreen  \
	-no-gfx-vnc  \
	-no-gfx-qvfb  \
	-qt-kbd-linuxinput  \
	-no-glib  \
	-qt-zlib \
	-no-phonon \
	-no-phonon-backend \
	-no-javascript-jit \
	-no-sql-db2  \
	-no-sql-ibase \
	-no-sql-oci \
	-no-sql-odbc \
	-no-sql-psql \
	-qt-sql-sqlite \
	-plugin-sql-sqlite \
	-no-sql-sqlite2 \
	-no-sql-mysql \
	-no-sql-tds \
	-no-qt3support \
	-no-xmlpatterns \
	-qt-mouse-linuxinput \
	-no-mouse-linuxtp \
	-no-script \
	-no-largefile \
	-no-exceptions \
	-nomake docs  \
	-I$INC_OUT_DIR \
	-L$LIB_OUT_DIR \
	-D QT_QWS_CLIENTBLIT \
	-qt-mouse-tslib \
	-plugin-mouse-tslib \
	-nomake tools \
	-nomake docs  \
	-no-webkit \
	-stl \

#	-nomake demos \
#	-nomake examples \
#       -no-separate-debug-inf \


	make clean
	make -j4
	make install

	if [ $? != "0" ] ; then
		echo "Make QT error!!"
		exit
	fi
	
}

function build_pnglib()
{
	echo "===========Build MiniGUI core lib================"

	cd $LIBPNG_DIR

	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin:$PATH
	
	./configure --prefix=$OUT_DIR \
		CC=arm-linux-gnueabi-gcc \
		 --host=arm-linux --build=i386-linux --enable-shared\
		 LDFLAGS=-L$LIB_OUT_DIR \
		 CFLAGS=-I$INC_OUT_DIR \
		 LIBS=-lz
		

	make clean
	make -j4
	
	if [ $? != "0" ] ; then
		echo "Make png lib error!!"
		exit
	fi

	make install
}

function build_zlib()
{
	echo "===========Zlib================"

	cd $ZLIB_DIR	

	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin:$PATH

	export CC=arm-linux-gnueabi-gcc
	./configure --shared --prefix=$OUT_DIR --libdir=$LIB_OUT_DIR --includedir=$INC_OUT_DIR
	make clean
	make -j4

	if [ $? != "0" ] ; then
		echo "Make zlib lib error!!"
		exit
	fi

	make install
}

function build_minigui()
{
	echo "===========Build MiniGUI core lib================"

	cd $MINIGUI_CORE_DIR

	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin:$PATH

	./configure --prefix=$OUT_DIR --enable-procs \
		CC=arm-linux-gnueabi-gcc \
		 --host=arm-linux --build=i386-linux --target=arm-linux --with-osname=linux \
                 --with-targetname=fbcon \
		 --enable-videofbcon \
		 --enable-autoial  \
		 --disable-vbfsupport  \
		 --disable-screensaver \
		 --disable-pcxvfb \
	   	 --disable-dlcustomial \
		 --disable-cursor \
		 --enable-pngsupport \
		 CFLAGS=-I$INC_OUT_DIR \
		 LDFLAGS=-L$LIB_OUT_DIR 

	if [ $? != "0" ] ; then
		echo "Configure MiniGUI error!!"
		exit
	fi
		
	make clean
	make -j4

	if [ $? != "0" ] ; then
		echo "Build MiniGUI error!!"
		exit
	fi

	make install

#	echo "===========Build MiniGUI Sample ================"
#	cd $MINIGUI_SAMPLE_DIR
#
#	./configure --prefix=$OUT_DIR \
#		CC=arm-linux-gnueabi-gcc \
#		 --host=arm-linux --build=i386-linux --target=arm-linux \
#		 --with-lang=zhcn \
#		 CFLAGS=-I$INC_OUT_DIR -lpng  \
#		 LDFLAGS=-L$LIB_OUT_DIR \
#		 MINIGUI_CFLAGS=-I$INC_OUT_DIR \
#		 MINIGUI_LIBS=-lminigui_procs \
#		 PKG_CONFIG_PATH=$LIB_OUT_DIR/pkgconfig \
#		 LIBS=-lm 
#	
#	make clean
#	make -j4
#
#	if [ $? != "0" ] ; then
#		echo "Build MiniGUI Sample error!!"
#		exit
#	fi
#	make install

	echo "===========Build MiniGUI Res ================"
	cd $MINIGUI_RES_DIR

	./configure --prefix=$OUT_DIR 

	make clean
	make -j4
	make install

	if [ $? != "0" ] ; then
		echo "Build MiniGUI Res error!!"
		exit
	fi
	
}

function build_ffmpeg()
{
	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin:$PATH

	cd $FFMPEG_DIR
	./configure --disable-static --enable-small --disable-runtime-cpudetect --enable-shared \
		--disable-swscale-alpha --disable-doc --disable-avdevice --disable-swresample \
		--disable-swscale --disable-postproc --disable-avfilter --enable-avresample --disable-dct \
		--disable-dwt --disable-fft --disable-faan --disable-pixelutils --disable-d3d11va --disable-dxva2 \
		--disable-vaapi --disable-vda  --disable-vdpau --disable-debug --disable-everything --enable-cross-compile \
		--enable-encoder=h264 --enable-decoder=h264 --enable-muxer=mp4 --enable-demuxer=mpegvideo \
		--cross-prefix=arm-linux-gnueabi- --cc=arm-linux-gnueabi-gcc --cxx=arm-linux-gnueabi-g++ --arch=armv7 --target-os=linux

	make clean
	make
}

function build_ncnn()
{
	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin:$PATH

	cd $NCNN_DIR

	mkdir -p build-arm-gcc-armv7
	cd build-arm-gcc-armv7
	cmake -DNCNN_OPENMP=OFF -DCMAKE_TOOLCHAIN_FILE=../arm-gcc.toolchain.cmake ..
	make clean
	make
}



function build_app()
{
	echo "==========Start Pack APP=========="

	cd $APP_DIR

	export PATH=$TOP_DIR/tools:$TOP_DIR/tools/bin:$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin:$PATH
#$TOP_DIR/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin
#$TOP_DIR/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabi/bin:
#$TOP_DIR/gcc-linaro/bin:
##$TOP_DIR/gcc-linaro-5.3.1-2016.05-linux/bin


	rm -rf build
	mkdir build
	cd build
	cmake ../
	make

	if [ $? != "0" ] ; then
		echo "build_app error!!"
		exit
	fi

	cp camera/camera_test $BIN_OUT_DIR
#	cp adas/adastest $BIN_OUT_DIR
	cp dpplayer/dpplayer $BIN_OUT_DIR
	cp ../dpplayer/test1.264 $BIN_OUT_DIR

}

function pack_image()
{
	echo "==========Start Pack Image=========="
	cd $PACK_DIR
	./pack
}


function pack_rootfs()
{
	echo "==========Start Pack Rootfs=========="

	# Copy gcc lib image
	echo "Copy gcc lib"

	cd $ROOTFS_DIR
	
	rm -rf lib
	rm -rf proc
	rm -rf dev
	rm -rf sys
	rm -rf root
	rm -rf home
	rm -rf mnt
	rm -rf var
	rm -rf vendor/module

	mkdir lib
	mkdir proc
	mkdir dev
	mkdir sys
	mkdir root
	mkdir home
	mkdir mnt

	mkdir -p usr/lib
	mkdir -p etc/res
	mkdir -p etc/res/font
	mkdir -p var/tmp
	mkdir -p etc/udhcpc
	mkdir -p vendor/module
	


	# Copy GCC LIB
	cp -r $MEDIA_LIBS_DIR/gcc/* ./lib/
	cp -r $MEDIA_LIBS_DIR/*.so  ./lib/
	cp -r $MODULE_DIR/*.ko ./vendor/module

	cp $BUSYBOX_DIR/examples/udhcp/simple.script ./etc/udhcpc/default.script

#	cp $BIN_OUT_DIR/camera_test ./bin/
#	cp $BIN_OUT_DIR/adastest ./bin/
	cp $BIN_OUT_DIR/dpplayer ./bin/
	cp $BIN_OUT_DIR/test1.264 ./usr/	
	
	cd ../
	mkfs.jffs2 -d rootfs -l –e 0x20000 -o rootfs_spi_nor.img
	mv rootfs_spi_nor.img $BIN_OUT_DIR
	
}




function showhelp()
{
	echo "===================================================="
	echo "Dophin PI Linux QT build help :"
	echo "help  --- show this help"
	echo "uboot  --- build uboot"
	echo "kernel --- build kernel"
	echo "===================================================="
}



# Change follow order carefull
#build_uboot
#build_kernel
#build_tslib
#build_zlib
#build_pnglib
#build_qt
#build_busybox
#build_minigui
#build_app
#pack_rootfs
#pack_image

function build()
{
	case "$1"  in
	"uboot")
	build_uboot
	;;

	"kernel")
	build_kernel
	;;

	"busybox")
	build_busybox
	;;

	"minigui")
	build_zlib
	build_pnglib
	build_minigui
	;;

	"tslib")
	build_tslib
	;;

	"qt")
	build_qt
	;;

	"rootfs")
	pack_rootfs
	;;

	"image")
	pack_image
	;;

	"app")
	build_app
	;;

	"ffmpeg")
	build_ffmpeg
	;;

	"ncnn")
	build_ncnn
	;;

	"all")
	build_uboot 
	build_kernel
	build_tslib 
	build_zlib
	build_pnglib
	build_qt
	build_busybox 
	build_minigui 
	build_app
	pack_rootfs 
	pack_image
	;;

	"help")
	showhelp
	;;

	*)
	showhelp
	;;

	esac	
}

build $1








