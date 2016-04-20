FROM jruby:latest

RUN apt-get update && apt-get install -y vim tcsh

ENV GIT_URL https://raw.githubusercontent.com/akinom
ENV GIT_DIR  dspace-cli
ENV GIT_BRANCH master

VOLUME /dspace
VOLUME /dspace-cli

ENV DSPACE_HOME /dspace 
RUN useradd -m dspace 
USER dspace  

WORKDIR /tmp
#RUN wget ${GIT_URL}/${GIT_DIR}/${GIT_BRANCH}/Gemfile
ADD Gemfile .
RUN bundle install

WORKDIR /dspace-cli
CMD bash
