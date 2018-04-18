using BinDeps

@BinDeps.setup

const version = "3.0.0"
rtmidi_lib = library_dependency("rtmidi_lib", aliases = ["rtmidi","rtmidi-64","librtmidi","librtmidi-0"])
provides(Sources, URI("https://github.com/thestk/rtmidi/archive/v$version.tar.gz"), rtmidi_lib, unpacked_dir = "rtmidi-$version")
prefix = joinpath(BinDeps.depsdir(rtmidi_lib), "usr")
srcdir = joinpath(BinDeps.depsdir(rtmidi_lib), "src", "rtmidi-$version")
provides(SimpleBuild,
          (@build_steps begin
              GetSources(rtmidi_lib)
              @build_steps begin
                  ChangeDirectory(srcdir)
                  `./autogen.sh`
                  `./configure --prefix=$prefix`
                  `make`
                  `make install`
              end
           end), rtmidi_lib, os = :Unix)

@BinDeps.install Dict(:rtmidi_lib => :rtmidi_lib)
