FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b AS builder
ARG VERSION
SHELL ["/bin/bash", "-c"]
RUN export DEBIAN_FRONTEND=noninteractive
RUN echo "deb http://archive.ubuntu.com/ubuntu resolute-backports main restricted universe multiverse" >/etc/apt/sources.list.d/resolute-backports.list
RUN apt-get -y update
RUN apt-get install -y --no-install-recommends \
    automake \
    build-essential \
    ca-certificates \
    git \
    libtool \
    make \
    pkg-config \
    libcurl4-openssl-dev \
    libogg-dev \
    libspeex-dev \
    libssl-dev \
    libtheora-dev \
    libvorbis-dev \
    libxml2-dev \
    libxslt1-dev \
    librhash-dev
RUN apt-get install -y --no-install-recommends -t resolute-backports \
    libigloo-dev
RUN rm -rf /var/lib/apt/lists/*

WORKDIR /build
ADD icecast-$VERSION.tar.gz .
RUN if test ! -d icecast-$VERSION; then mkdir -p /build && cd /build && git clone --recursive https://github.com/xiph/Icecast-Server.git icecast; fi

WORKDIR /build/icecast
RUN /build/icecast/autogen.sh \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var
RUN /build/icecast/configure
RUN make
RUN make install DESTDIR=/build/output

FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b
SHELL ["/bin/bash", "-c"]
RUN export DEBIAN_FRONTEND=noninteractive
RUN echo "deb http://archive.ubuntu.com/ubuntu resolute-backports main restricted universe multiverse" >/etc/apt/sources.list.d/resolute-backports.list
RUN apt-get -y update
RUN apt-get install -y --no-install-recommends \
    ca-certificates \
    media-types \
    libcurl4 \
    libogg0 \
    libspeex1 \
    libssl3t64 \
    libtheora* \
    libvorbis0a \
    libxml*  \
    libxslt1.1 \
    librhash1
RUN apt-get install -y --no-install-recommends -t resolute-backports \
    libigloo0t64
RUN rm -rf /var/lib/apt/lists/*

ENV USER=icecast
RUN groupadd --gid 1011 $USER
RUN useradd -g $USER -s /bin/bash -r -M $USER

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1 AS runtime
SHELL ["/bin/bash", "-c"]
RUN echo "$(openssl version)"
RUN openssl req \
-x509 \
-out /etc/cert.pem \
-keyout /etc/key.pem \
-newkey rsa:2048 \
-nodes \
-sha256 \
-subj "/CN=localhost" \
-extensions EXT \
-config <(printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")


COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
COPY icecast.xml /etc/icecast.xml
COPY xml-edit.sh /usr/local/bin/xml-edit
RUN chmod +x \
    /usr/local/bin/docker-entrypoint \
    /usr/local/bin/xml-edit
RUN chmod 0650 \
    /etc/cert.pem \
    /etc/key.pem
RUN chown $USER:$USER \
    /etc/cert.pem \
    /etc/key.pem

COPY --from=builder /build/output /usr/local/bin
RUN xml-edit errorlog - /etc/icecast.xml

RUN mkdir -p /var/log/icecast && \
    chown $USER:$USER /etc/icecast.xml /var/log/icecast

EXPOSE 8000
ENTRYPOINT ["docker-entrypoint"]
USER $USER
CMD ["icecast", "-c", "/etc/icecast.xml"]
