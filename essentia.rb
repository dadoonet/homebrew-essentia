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
  # This snapshot uses FFmpeg 5.1's channel layout API and still calls
  # av_init_packet, removed in FFmpeg 6. ffmpeg@5 is the newest formula it
  # can compile against.
  depends_on "ffmpeg@5"
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
