FROM buildpack-deps:stretch AS build

ARG version=11.1v1
ENV NUKE_VERSION=${version}

RUN apt-get install -y wget

RUN mkdir /Nuke && \
    wget -q -O - https://thefoundry.s3.amazonaws.com/products/nuke/releases/${NUKE_VERSION}/Nuke${NUKE_VERSION}-linux-x86-release-64.tgz | \
    tar -C / -zxf -

WORKDIR /Nuke

# Exclude optional documentation, libraries, and tests to reduce bundle size
RUN unzip -q /Nuke${NUKE_VERSION}-linux-x86-release-64-installer && \
    rm -rf \
       Documentation \
       plugins/OCIOConfigs/configs/aces* plugins/OCIOConfigs/configs/spi* \
       plugins/icons \
       libcufft* \
       MKL \
       lib/python2.7/test \
       translations \
       && \
    rm -f /Nuke${NUKE_VERSION}-linux-x86-release-64-installer

RUN apt-get -qq update && apt-get install -y \
    # exodus deps
    musl musl-dev musl-tools python-pip \
    # Nuke deps
    libgl1-mesa-glx libglu1-mesa libxft2 libpulse0 libxmu6 libasound2
RUN pip install exodus-bundler

# For convenience, remove the version number from the binary's name
RUN NUKE_PATH=$(find . -name "Nuke*" -executable -type f) \
    bash -c 'mv ${NUKE_PATH} nuke'

RUN mkdir -p /tmp/exodus_root && \
    NO_SYMLINK_ARGS=$(find . -name "*.so*" | xargs printf -- '--no-symlink %s ') \
    bash -c 'exodus -a . ${NO_SYMLINK_ARGS} --tarball nuke | tar -C /tmp/exodus_root --absolute-names -zxf -'

FROM alpine:3.9 AS final

COPY --from=build /tmp/exodus_root /opt

# FIXME: After running exodus, Nuke fails to find some shared libraries (e.g.
# libX11.so.*). Symlinking them into the Nuke directory helps it to find them.
#
# It would be nice if we didn't need to do this.
RUN NUKE_PATH="$(find /opt/exodus/bundles -name "Nuke" | head -1)" \
    LIB_PATH="${NUKE_PATH}/../usr/lib/x86_64-linux-gnu" \
    sh -c 'for path in $(find "${LIB_PATH}" -name "*.so*"); do ln -fs "${path}" "${NUKE_PATH}"; done'

RUN addgroup -S app && \
    adduser -S -G app app
RUN chown app:app /opt
USER app

ENV PATH="/opt/exodus/bin:${PATH}"

ENTRYPOINT ["/opt/exodus/bin/nuke"]
CMD ["--help"]
