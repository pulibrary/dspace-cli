FROM jruby:latest

ENV GIT_URL https://raw.githubusercontent.com/akinom
ENV GIT_DIR  dspace-cli
ENV GIT_BRANCH master 

RUN apt-get update && apt-get install -y git  wget
VOLUME /dspace
ENV DSPACE_HOME /dspace 
RUN useradd -m dspace 
USER dspace  

WORKDIR /tmp 
RUN wget ${GIT_URL}/${GIT_DIR}/${GIT_BRANCH}/Gemfile 
#ADD Gemfile .
RUN bundle install

WORKDIR /home/dspace
RUN git clone --depth 1   --branch  ${GIT_BRANCH} ${GIT_URL}/${GIT_DIR}
WORKDIR ${GIT_DIR} 
CMD idspace
