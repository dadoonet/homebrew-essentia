# Homebrew-Essentia

Homebrew formulas for Essentia and Gaia.

```bash
brew tap dadoonet/essentia
brew install dadoonet/essentia/essentia
```

Essentia is installed from a source archive of `master` commit `7320015a`
(2026-09-30, version `2.1-beta6-dev`). That archive does not include Git
history or the `test/audio` and `test/models` submodules. The newest Git tag
remains `v2.1_beta5` (2019).

Python bindings for Python 3.14 are built by default. Skip them with:

```bash
brew install dadoonet/essentia/essentia --without-python
```

Optional features:

```bash
brew install dadoonet/essentia/essentia --with-gaia
brew install dadoonet/essentia/essentia --with-libtensorflow
```

Gaia is version 2.4.7 and uses Qt 5. Essentia links the current FFmpeg formula.
