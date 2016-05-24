FROM jruby:latest

RUN apt-get update && apt-get install -y vim tcsh

VOLUME /dspace
VOLUME /dspace-cli
VOLUME /dspace-jruby

ENV DSPACE_HOME /dspace 
RUN useradd -m dspace 
USER dspace  

WORKDIR /tmp
ADD Gemfile .
RUN bundle install
RUN bundle update

ENV RUBYLIB /dspace-cli:/dspace-cli/dspace-jruby/lib  

WORKDIR /dspace-cli
CMD bash
