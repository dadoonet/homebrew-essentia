class Essentia < Formula
  desc "Library for audio analysis and audio-based music information retrieval"
  homepage "https://essentia.upf.edu"
  # Snapshot of master @ 7320015a (2026-09-30). The newest Git tag is v2.1_beta5
  # from 2019. A source archive skips Git history and the test submodules
  # (essentia-audio, essentia-models), which are not required to build.
  url "https://github.com/MTG/essentia/archive/7320015a1cad3ac1dc038b52ef94803587d09986.tar.gz"
  version "2.1-beta6-dev.20260930"
  sha256 "bd087a181f1ffedbae318eea458566ce1e63c7012162a785d3c3aa7bcad18af5"
  license "AGPL-3.0-only"

  option "without-python", "Build without Python bindings"

  depends_on "pkg-config" => :build
  depends_on "chromaprint"
  depends_on "eigen"
  depends_on "ffmpeg"
  depends_on "fftw"
  depends_on "libsamplerate"
  depends_on "libyaml"
  depends_on "numpy" if build.with?("python")
  depends_on "python@3.14"
  depends_on "taglib"

  depends_on "gaia" => :optional
  depends_on "libtensorflow" => :optional

  def python3
    formula_opt_bin("python@3.14")/"python3.14"
  end

  def install
    # Python 3.12 removed distutils. This import is unused.
    inreplace "src/examples/wscript", "import distutils.sysconfig\n", ""

    # FFmpeg 7 removed AVCodec::sample_fmts. Chromaprint pulls in current FFmpeg,
    # whose headers are the ones this build sees.
    inreplace "src/essentia/utils/audiocontext.cpp" do |s|
      s.gsub!(/if \(audioCodec->sample_fmts\) \{.*?sample_fmts\[0\];\n\s+\}\n\s+\}/m, <<~CPP)
        const enum AVSampleFormat* sample_fmts = nullptr;
        if (avcodec_get_supported_config(nullptr, audioCodec, AV_CODEC_CONFIG_SAMPLE_FORMAT,
                                         0, reinterpret_cast<const void**>(&sample_fmts), nullptr) >= 0
            && sample_fmts) {
          const enum AVSampleFormat* p = sample_fmts;
          bool found = false;
          while (*p != AV_SAMPLE_FMT_NONE) {
            if (*p == desired_fmt) { found = true; break; }
            ++p;
          }
          if (!found)
            desired_fmt = sample_fmts[0];
        }
      CPP
    end

    python_site = prefix/"lib/python3.14/site-packages"
    args = %W[
      --mode=release
      --with-examples
      --with-vamp
      --prefix=#{prefix}
    ]
    if build.with?("python")
      args << "--with-python"
      args << "--pythondir=#{python_site}"
    end
    args << "--with-gaia" if build.with?("gaia")
    args << "--with-tensorflow" if build.with?("libtensorflow")

    system python3, "waf", "configure", *args
    system python3, "waf"
    system python3, "waf", "install"

    # waf records the build-directory dylib path into executables. Point them
    # at the installed library; Homebrew then rewrites that cellar path to opt.
    libessentia = lib/"libessentia.dylib"
    mach_files = Pathname.glob("#{bin}/*") + Pathname.glob("#{lib}/**/*.{dylib,so}")
    mach_files.each do |file|
      next unless file.file?

      old = Utils.popen_read("otool", "-L", file).lines.filter_map { |line| line.strip.split.first }
                 .find { |path| path.end_with?("/libessentia.dylib") && path != libessentia.to_s }
      next if old.nil?

      system "install_name_tool", "-change", old, libessentia, file
    end
  end

  test do
    system bin/"essentia_streaming_extractor_music",
           "/System/Library/Sounds/Glass.aiff",
           "Glass.json"

    if build.with?("python")
      ENV["PYTHONPATH"] = lib/"python3.14/site-packages"
      system python3, "-c", <<~PYTHON
        import essentia.standard as estd
        import essentia.streaming as estr
        estd.MusicExtractor()("/System/Library/Sounds/Glass.aiff")
      PYTHON
    end
  end
end
