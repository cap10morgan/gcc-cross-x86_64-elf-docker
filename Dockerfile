FROM debian:bookworm

RUN apt-get update && apt-get upgrade -y

ARG BINUTILS_VERSION=2.41
ARG GCC_VERSION=13.2.0

# GCC cross-compiler built and installed according to https://wiki.osdev.org/GCC_Cross-Compiler

RUN apt-get install -y wget gcc libgmp3-dev libmpfr-dev libisl-dev \
  libmpc-dev texinfo bison flex make bzip2 patch build-essential

RUN mkdir -p /usr/local/src && cd /usr/local/src && \
  wget -q https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz && \
  wget -q https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz && \
  tar -zxf binutils-${BINUTILS_VERSION}.tar.gz && tar -zxf gcc-${GCC_VERSION}.tar.gz && \
  rm binutils-${BINUTILS_VERSION}.tar.gz gcc-${GCC_VERSION}.tar.gz && \
  chown -R root:root binutils-${BINUTILS_VERSION} && chown -R root:root gcc-${GCC_VERSION} && \
  chmod -R o-w,g+w binutils-${BINUTILS_VERSION} && chmod -R o-w,g+w gcc-${GCC_VERSION}

ENV PREFIX="/usr/local/cross" TARGET="x86_64-elf" PATH="$PREFIX/bin:$PATH"

RUN cd /usr/local/src && mkdir build-binutils && cd build-binutils && \
  ../binutils-${BINUTILS_VERSION}/configure --target=$TARGET --prefix="$PREFIX" \
  --with-sysroot --disable-nls --disable-werror && make && make install

# Disable libgcc red-zone
# From https://wiki.osdev.org/Libgcc_without_red_zone
COPY t-x86_64-elf /usr/local/src/gcc-${GCC_VERSION}/gcc/config/i386/
RUN sed -i "/x86_64-\*-elf\*)/a \
  \\\ttmake_file=\"\\\${tmake_file} i386/t-x86_64-elf\"" /usr/local/src/gcc-${GCC_VERSION}/gcc/config.gcc

RUN cd /usr/local/src && mkdir build-gcc && cd build-gcc && \
  ../gcc-${GCC_VERSION}/configure --target=$TARGET --prefix="$PREFIX" \
  --disable-nls --enable-languages=c,c++ --without-headers && \
  make all-gcc && make all-target-libgcc && make install-gcc && make install-target-libgcc

RUN echo "export PATH=$PREFIX/bin:\$PATH" >> /root/.bashrc
