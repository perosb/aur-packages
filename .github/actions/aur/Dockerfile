FROM docker.io/library/archlinux:base-devel AS base

RUN echo "Server = https://mirror.osbeck.com/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

# PKGEXT without compression; !debug so makepkg does not also emit *-debug.pkg.tar
RUN pacman -Syu --needed --noconfirm pacman-contrib namcap git sudo openssh rsync && \
    echo PKGEXT=.pkg.tar >> /etc/makepkg.conf && \
    sed -i 's/ debug / !debug /' /etc/makepkg.conf

FROM base AS yay

RUN useradd -m builder && \
  echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
  chown builder:builder /home/builder
USER builder
# yay-bin is prebuilt and depends on pacman>6.1 (no pinned libalpm soname like paru-bin).
RUN env -C /home/builder git clone https://aur.archlinux.org/yay-bin.git && \
    env -C /home/builder/yay-bin makepkg -s --noconfirm

FROM base

# Match only yay-bin-<version>…, not yay-bin-debug-… (belt-and-suspenders with !debug)
COPY --from=yay /home/builder/yay-bin/yay-bin-[0-9]*.pkg.tar /tmp/yay.pkg.tar
RUN pacman -U --noconfirm /tmp/yay.pkg.tar && rm -f /tmp/yay.pkg.tar
COPY entrypoint.sh /entrypoint.sh
COPY build.sh /build.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/build.sh" ]
