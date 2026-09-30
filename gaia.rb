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
