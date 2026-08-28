FROM ruby:3.3-alpine
ENV WORKSPACE=/rsyntaxtree
WORKDIR $WORKSPACE

RUN apk update && \
    apk upgrade && \
    apk add --no-cache linux-headers libxml2-dev make gcc libc-dev bash && \
    apk add --no-cache librsvg librsvg-dev pango-dev xz-dev libbz2 && \
    apk add --no-cache gobject-introspection gobject-introspection-dev && \
    apk add --no-cache -t .build-packages --no-cache build-base curl-dev wget gcompat && \
    apk add --no-cache font-noto font-noto-cjk font-noto-cjk-extra \
        font-noto-arabic font-noto-naskh-arabic font-noto-hebrew \
        font-noto-devanagari font-noto-thai font-noto-khmer \
        font-dejavu

# Noto Sans Math (pulled in by font-noto) claims the Arabic block but carries no
# joining rules, and fontconfig ranks it above Noto Sans Arabic — Arabic then
# renders as isolated letterforms. Keep the font, since trees use its
# mathematical alphanumerics (the little v of vP), but drop Arabic from it.
COPY dev/fontconfig/99-noto-math-no-arabic.conf /etc/fonts/conf.d/99-noto-math-no-arabic.conf

# Emoji: the monochrome Noto Emoji, not Alpine's font-noto-emoji (which is the
# colour NotoColorEmoji). Cairo does not rasterise its bitmap glyphs in this
# pipeline, so emoji would silently fall back to whatever outline font happens
# to cover them. Pinned to a google/fonts commit so the gallery stays stable.
ARG NOTO_EMOJI_SHA=b979dba422e445492b0eb9951ac52ee0b4d648c3
ARG NOTO_EMOJI_SHA256=de6c18832938afc99caf132b39d6a30a19bac7f2e812e28db2535b4608d27551
RUN mkdir -p /usr/share/fonts/noto-emoji && \
    wget -q -O /usr/share/fonts/noto-emoji/NotoEmoji-Regular.ttf \
      "https://raw.githubusercontent.com/google/fonts/${NOTO_EMOJI_SHA}/ofl/notoemoji/NotoEmoji%5Bwght%5D.ttf" && \
    echo "${NOTO_EMOJI_SHA256}  /usr/share/fonts/noto-emoji/NotoEmoji-Regular.ttf" | sha256sum -c -


ADD Gemfile $WORKSPACE
ADD rsyntaxtree.gemspec $WORKSPACE
RUN bundle install -j4

RUN fc-cache -fv

ADD . $WORKSPACE
CMD ["/bin/bash"]
