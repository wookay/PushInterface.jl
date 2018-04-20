using BinDeps

@BinDeps.setup

const rtmidi_version = "3.0.0"
librtmidi = library_dependency("librtmidi", aliases = ["librtmidi"])
provides(Sources, URI("https://github.com/thestk/rtmidi/archive/v$rtmidi_version.tar.gz"), librtmidi, unpacked_dir = "rtmidi-$rtmidi_version")
prefix = joinpath(BinDeps.depsdir(librtmidi), "usr")
srcdir = joinpath(BinDeps.depsdir(librtmidi), "src", "rtmidi-$rtmidi_version")
provides(SimpleBuild,
    (@build_steps begin
        GetSources(librtmidi)
        @build_steps begin
            ChangeDirectory(srcdir)
            `./autogen.sh`
            `./configure --prefix=$prefix`
            `make`
            `make install`
        end
     end), librtmidi, os = :Unix)

const libusb_version = "1.0.22"
libusb = library_dependency("libusb", aliases = ["libusb-1.0"])
provides(Sources, URI("https://github.com/libusb/libusb/releases/download/v$libusb_version/libusb-$libusb_version.tar.bz2"), libusb, unpacked_dir = "libusb-$libusb_version")
prefix = joinpath(BinDeps.depsdir(libusb), "usr")
srcdir = joinpath(BinDeps.depsdir(libusb), "src", "libusb-$libusb_version")
provides(SimpleBuild,
    (@build_steps begin
        GetSources(libusb)
        @build_steps begin
            ChangeDirectory(srcdir)
            `./configure --prefix=$prefix`
            `make`
            `make install`
        end
    end), libusb, os = :Unix)

@BinDeps.install Dict(:librtmidi => :librtmidi, :libusb => :libusb)
