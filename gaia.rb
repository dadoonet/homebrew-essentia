class Gaia < Formula
  include Language::Python::Virtualenv

  desc "Audio similarity and classification library"
  homepage "https://essentia.upf.edu"
  url "https://github.com/MTG/gaia/archive/refs/tags/v2.4.7.tar.gz"
  sha256 "77493c8db258612a774a5c3e60ad220e10768fcdd87a839f9b0048beffe42184"
  license "AGPL-3.0-only"

  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  depends_on "eigen"
  depends_on "libyaml"
  depends_on "python@3.14"
  # Gaia loads the Qt5 waf tool. qt@5 5.15.19 matches the Qt version
  # referenced by current Essentia.
  depends_on "qt@5"

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  def python3
    formula_opt_bin("python@3.14")/"python3.14"
  end

  def install
    # Python 3.12 removed distutils. The bundled waf 2.0.19 still imports it
    # while configuring the bindings.
    shim = buildpath/"distutils-shim"
    (shim/"distutils").mkpath
    (shim/"distutils/__init__.py").write("")
    (shim/"distutils/sysconfig.py").write <<~PYTHON
      import sysconfig as _sysconfig

      def get_config_var(name):
          if name == "SO":
              return _sysconfig.get_config_var("EXT_SUFFIX") or ".so"
          if name == "INCLUDEPY":
              return _sysconfig.get_path("include")
          value = _sysconfig.get_config_var(name)
          return "" if value is None else value

      def get_python_lib(plat_specific=0, standard_lib=0, prefix=None):
          if standard_lib:
              name = "platstdlib" if plat_specific else "stdlib"
          else:
              name = "platlib" if plat_specific else "purelib"
          scheme = "posix_prefix" if prefix else None
          vars = {"base": prefix, "platbase": prefix} if prefix else None
          return _sysconfig.get_path(name, scheme, vars) or ""
    PYTHON
    # Release builds pass -msse2, which Apple Silicon clang rejects.
    # Eigen 5 needs C++14. Gaia still asks for C++11, and the Darwin flags
    # repeat that standard, so both occurrences have to move.
    inreplace "wscript", "c++11", "c++14"
    inreplace "wscript",
              "conf.env.CXXFLAGS += [ '-O2', '-msse2' ]",
              "conf.env.CXXFLAGS += [ '-O2' ]\n" \
              "        if conf.env.DEST_CPU in ('x86_64', 'x86'):\n" \
              "            conf.env.CXXFLAGS += [ '-msse2' ]"
    # The SWIG interfaces call the Python 2 C API.
    inreplace "src/bindings/wscript",
              "swig_flags = '-c++ -python -w451',",
              "swig_flags = '-c++ -python -w451',\n" \
              "        cxxflags = ['-DPyString_FromString=PyUnicode_FromString', " \
              "'-DPyInt_FromLong=PyLong_FromLong'],"

    ENV.prepend_path "PYTHONPATH", shim

    # waf only registers --pythondir after the python tool is loaded, which is
    # too late for the command line. check_python_version reads these instead.
    python_site = prefix/"lib/python3.14/site-packages"
    ENV["PYTHONDIR"] = python_site
    ENV["PYTHONARCHDIR"] = python_site
    system python3, "waf", "configure", "--with-python-bindings", "--prefix=#{prefix}"
    system python3, "waf"
    system python3, "waf", "install"

    venv = virtualenv_create(libexec, python3)
    venv.pip_install resource("pyyaml")
  end

  test do
    system "pkg-config", "--exists", "gaia2"
  end
end
