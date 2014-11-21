Dependencies
=============

A Mac, Linux and Windows build script for a couple of open source libraries that I often
use when working on interactive installations or just applications. Goal of this repository
is to create a command line based build solution that gives you a real cross platform 
build solution where you compile all dependencies from source on the system itself. 

Directory layout
----------------

All my repositories try to follow the directory structure as described below:

````sh
  build/
  src/
  include/
  extern/
  install/
````

The **build** directory is used for out of source builds. We build the source 
files from the `src` directory in there but also all dependencies. **install**
is the path into which I install the compiled executables per platform triplet
(e.g. install\win-vs2013-x86_64\bin\). The **extern** directory contains all
the compiled libraries under a triplet. 

How to use
----------

1. Create a `build` directory 
2. Checkout this dependencies repository in `build/dependencies/`
3. Create a file called `build/dependencies.sh`
4. In `build/dependencies.sh` list the libraries you want to compile (see below).
5. Create a shell script in `build/release.sh` with something like:

   ````sh
     vs="2013"
     source ./dependencies/build.sh
   ````

6. Execute the script from a Git Bash or console.


build/dependencies.sh
----------------------

````sh
build_m4=n
build_autoconf=n        # needs an updated m4 
build_libtool=n
build_automake=n      
build_pkgconfig=n
build_gtkdoc=n         
build_pixman=n
build_gettext=n
build_libxml=n
build_ffi=n              
build_fontconfig=n      # needs freetype, libxml
build_libpng=y
build_libjpg=n
build_colm=n
build_ragel=n           # needs colm
build_harfbuzz=n        # needs ragel
build_freetype=n        # needs automake, autoconf, libtool
build_glib=n            # needs ffi 
build_cairo=n           # needs png, freetype, harfbuzz 
build_pango=n           # needs glib, ffi, gtkdoc, fontconfig, freetype, libxml, harfbuzz
build_libz=y
build_yasm=y
build_libuv=n
build_mongoose=n
build_netskeleton=n
build_sslwrapper=n
build_rapidxml=y
build_glad=y
build_glfw=y
build_tinylib=y
build_videocapture=y
build_imagemagick=n
build_graphicsmagick=n
build_libav=n
build_microprofile=n
build_ogg=n
build_theora=n
build_vorbis=n
build_rxpplayer=n       # ogg,theora,vorbis player
build_tracker=n         # openGL/openCV based video tracking
build_opencv=n
build_curl=n
build_jannson=n
build_x264=y            # needs yasm 
build_flvmeta=n         
build_videogenerator=y
build_nasm=n           
build_lame=y            # needs nasm, mp3 encoding
build_portaudio=y
build_libyuv=y           
build_nanovg=n
build_liblo=n           # needs autotools/make, OSC implementation.
build_remoxly=y         # needs tinylib
build_h264bitstream=y   # h264 bitstream parser
````