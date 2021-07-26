FROM node:14.17.1-buster-slim as node
FROM ruby:2.7.4-slim-buster

COPY --from=node /opt/yarn-v* /opt/yarn/
COPY --from=node /usr/local/bin/node /usr/local/bin/
RUN ln -s /opt/yarn/bin/yarn /usr/local/bin/ && \
    ln -s /opt/yarn/bin/yarnpkg /usr/local/bin/

# update bundler
RUN gem install bundler --no-document -v 2.1.4

# Common dependencies
RUN apt-get update -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  build-essential \
  gnupg2 \
  tzdata \
  curl \
  git && \
  apt-get clean && \
  rm -rf /var/cache/apt/archives/* && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  truncate -s 0 /var/log/*log

# Install dependencies
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  libpq-dev \
  imagemagick \
  python \
  shared-mime-info && \
  apt-get clean && \
  rm -rf /var/cache/apt/archives/* && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  truncate -s 0 /var/log/*log

# Configure bundler
ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

# Uncomment this line if you store Bundler settings in the project's root
# ENV BUNDLE_APP_CONFIG=.bundle

# Uncomment this line if you want to run binstubs without prefixing with `bin/` or `bundle exec`
ENV PATH /app/bin:$PATH

# Create a directory for the app code
RUN mkdir -p /app

WORKDIR /app
RUN mkdir -p tmp/sockets
RUN mkdir -p tmp/pids
ENV BUNDLE_DEPLOYMENT true
ENV BUNDLE_PATH vendor/bundle
ENV BUNDLE_WITHOUT development:test

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf $BUNDLE_PATH/ruby/2.7.0/cache/*

# Install npm packages
COPY package.json yarn.lock ./
RUN yarn install --production --frozen-lockfile && \
    yarn cache clean

# list up env variables needed for build process of this docker image
ARG RAILS_ENV="production"
ARG NODE_ENV="production"

# run assets:precompile
COPY . .
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile && \
    rm -rf tmp/cache/*

ENV PORT 3000
EXPOSE 3000

#CMD bundle exec puma -C config/puma.rb
CMD bin/rails server --port $PORT -b '0.0.0.0'
