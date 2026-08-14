FROM ruby:3.3-alpine
ENV WORKSPACE=/rsyntaxtree
WORKDIR $WORKSPACE

RUN apk update && \
    apk upgrade && \
    apk add --no-cache linux-headers libxml2-dev make gcc libc-dev bash && \
    apk add --no-cache librsvg librsvg-dev pango-dev imagemagick imagemagick-dev xz-dev libbz2 && \
    apk add --no-cache gobject-introspection gobject-introspection-dev && \
    apk add --no-cache -t .build-packages --no-cache build-base curl-dev wget gcompat && \
    apk add --no-cache font-noto font-noto-cjk font-noto-cjk-extra font-noto-emoji \
        font-noto-arabic font-noto-devanagari font-noto-thai


ADD Gemfile $WORKSPACE
ADD rsyntaxtree.gemspec $WORKSPACE
RUN bundle install -j4

ADD fonts $WORKSPACE
RUN mkdir -p /usr/share/fonts/yh
COPY ./fonts/* /usr/share/fonts/yh/
RUN fc-cache -fv

ADD . $WORKSPACE
CMD ["/bin/bash"]
