FROM ruby:alpine
MAINTAINER ankita.gupta@honestbee.com

RUN apk --update add build-base
RUN gem install sinatra thin

COPY . /var/scripts
WORKDIR /var/scripts

CMD ruby cancel_duplicate_builds.rb
