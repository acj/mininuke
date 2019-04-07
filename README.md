# mininuke
A small(ish) Nuke image intended for use in Alpine containers

[Nuke](https://www.foundry.com/products/nuke) is an excellent nonlinear video editor and toolkit. While it has native support for Linux, the bundle is fairly large (several gigabytes) and is not optimized for running in containers. It also has hard dependencies on libraries like X11, even when you're running it in headless/terminal mode. These factors make it inefficient to run Nuke in a modern, container-based environment like a public cloud.

Using [Exodus](https://github.com/intoli/exodus), though, we can gather the shared libraries that Nuke needs into a relocatable package that can run on relatively small container images. This image targets Alpine, but it can be ported to others (e.g. minideb) as needed.

### Getting started

Clone this repository. Then:

```
$ docker build -t mininuke --build-arg version=11.1v1 .
$ docker run --rm -it mininuke

Options available when launching from the main Nuke executable:
---------------------------------------------------------------

Usage: ./Nuke <switches>

[...]
```

You will need a license to actually run Nuke. Please give the kind, hard-working folks at Foundry your business.

### What's missing?

To reduce the size of the image, a few things have been removed:

  * Documentation
  * Non-default OCIO color management configurations (ACES, SPI, etc.)
  * Intel Math Kernel Library
  * NVIDIA CUDA Fast Fourier Transform library
  * Python unit tests
  * Translations

If your application needs these, remove the relevant lines from the Dockerfile and build a new image.

### License

See the `LICENSE` file.