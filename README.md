# dpace-cli 

This repo contains command line sripts that report on as well as modify the content of a [DSpace](https://github.com/DSpace/DSpace) repository. 

Scripts are impemented with the help of the [jrdspace gem](https://github.com/akinom/dspace-jruby).

Most of the scripts here are actively used at Princeton University; some are tailored to the specific Princeton needs. 


## Installation

### Prerequisite
 * JRuby  [Get Started](http://jruby.org/getting-started)
 * Package Manager  [Bundler](http://bundler.io/)
 * optional - but useful [RVM](https://rvm.io/)

### Installation 

clone  this repository 

Install the gems used by the scripts:
```
bundle install
```

##  Usage 

set the DSPACE_HOME environment variable to point to the installation directory of your DSpace repository 

run a scripts
```
bundle exec script_file
```

Scripts either prompt for input or have a --help option 

# Docker 

```
docker build -t dspace-cli .
docker save -o dspace-cli.docker  dspace-cli 
docker load -i dspace-cli.docker

docker run  -it --name dspace-cli   -v '/dspace:/dspace'  dspace-cli
docker run  -it --name dspace-cli   -v '/Users/monikam/DSpaces/installs/updatespace:/dspace'  dspace-cli
docker run  -it --name dspace-cli   -v '/Users/monikam/DSpaces/installs/updatespace:/dspace'  -u dspace dspace-cli
docker attach dspace-cli   #CTRL-p CTRL-q
docker exec  -it dspace-cli  bash
```

# Write your Own 

Have a look at the the [jrdspace gem](https://github.com/akinom/dspace-jruby), look at any of the included scripts in this repo, and if you need help feel free to send an email to  [akinom](https://github.com/akinom)
