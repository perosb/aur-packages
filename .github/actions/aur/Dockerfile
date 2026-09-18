FROM docker.io/library/archlinux:base-devel AS base

RUN echo "Server = https://mirror.osbeck.com/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

# PKGEXT without compression; !debug so makepkg does not also emit *-debug.pkg.tar
RUN pacman -Syu --needed --noconfirm pacman-contrib namcap git sudo openssh rsync && \
    echo PKGEXT=.pkg.tar >> /etc/makepkg.conf && \
    sed -i 's/ debug / !debug /' /etc/makepkg.conf

FROM base AS paru

RUN useradd -m builder && \
  echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
  chown builder:builder /home/builder
USER builder
# Build from source so paru links against this image's libalpm (paru-bin is
# prebuilt and breaks on libalpm soname bumps, e.g. libalpm.so.15 missing).
RUN env -C /home/builder git clone https://aur.archlinux.org/paru.git && \
    env -C /home/builder/paru makepkg -s --noconfirm

FROM base

# Match only paru-<version>…, not paru-debug-… (belt-and-suspenders with !debug)
COPY --from=paru /home/builder/paru/paru-[0-9]*.pkg.tar /tmp/paru.pkg.tar
RUN pacman -U --noconfirm /tmp/paru.pkg.tar && rm -f /tmp/paru.pkg.tar
COPY entrypoint.sh /entrypoint.sh
COPY build.sh /build.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/build.sh" ]
