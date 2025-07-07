FROM docker.io/library/archlinux:base-devel AS base

RUN pacman -Syu --needed --noconfirm pacman-contrib namcap git sudo openssh rsync && \
    echo PKGEXT=.pkg.tar >> /etc/makepkg.conf

FROM base AS paru

RUN useradd -m builder && \
  echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
  chown builder:builder /home/builder
USER builder
RUN env -C /home/builder git clone https://aur.archlinux.org/paru-bin.git && \
    env -C /home/builder/paru-bin makepkg -s OPTIONS=-debug

FROM base

COPY --from=paru /home/builder/paru-bin/paru-*.pkg.tar /tmp/paru.pkg.tar
RUN pacman -U --noconfirm /tmp/paru.pkg.tar && rm -f /tmp/paru.pkg.tar
COPY entrypoint.sh /entrypoint.sh
COPY build.sh /build.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/build.sh" ]
