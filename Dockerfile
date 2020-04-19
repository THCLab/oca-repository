FROM ruby:2.4

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./

RUN gem install bundler && bundle install

COPY config/ ./config
COPY lib/ ./lib
COPY plugins/ ./plugins
COPY config.ru web.rb README.md swagger.json ./

EXPOSE 9292
