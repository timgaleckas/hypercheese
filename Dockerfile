FROM ruby:2.3

RUN apt-get update -qq && apt-get install -y libsqlite3-dev build-essential nodejs libcurl4-openssl-dev imagemagick libjpeg-turbo-progs exiftool ffmpeg

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN rake secret > .secret_key_base
RUN cp config/database.yml.docker config/database.yml

CMD ["rails", "server", "-b", "0.0.0.0"]
