FROM "jhthorsen/mojopaste"
MAINTAINER sklkin@cpan.org

RUN apk add -U make \
  && cpanm -M https://cpan.metacpan.org Mojolicious::Plugin::Mango --no-wget

