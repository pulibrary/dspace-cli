# dpace-cli 

This repo contains command line sripts that report on as well as modify the content of a [DSpace](http://dspace.org/) instance.
Scripts are impemented with the help of the [jrdspace gem](https://github.com/akinom/dspace-jruby).

Most of scripts here are actively used at Princeton University; some are tailored to the specific Princeton needs. 


## Installation

### Prerequisite
 * JRuby  [Get Started](http://jruby.org/getting-started)
 * Package Manager  [Bundler](http://bundler.io/)
 * a working [DSPACE installation](https://github.com/DSpace/DSpace)
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

# Usage with Docker 

There is a Docker image on docker hub, but I do not promise to keep it up with this repo; 

If you want to add your own scripts or do changes to the scripts here, you need to build your own image. 

## Build and run your own image 
```
cd into the cloned code directory 

# build an image and name it dspace-cli 
docker build -t dspace-cli .

# run a container based on the image 
# this maps the local /dspace diretory onto  /dspace in the container 
# it also maps the current directory on the host to /dspace/cli in the container 
# it then starts the given jruby script, eg netid/create.rb 
docker run -v '/dspace:/dspace' -v `pwd`:/dspace-cli dspace-cli netid/create.rb

# to run the inertace dspace console 
docker run -it -v '/dspace:/dspace' -v `pwd`:/dspace-cli dspace-cli idspace

# to connect with a bash shell 
# to run the inertace dspace console 
docker run -it -v '/dspace:/dspace' -v `pwd`:/dspace-cli dspace-cli 
# once the shell starts you can run any of the scripts interactively, for example  
> ./print.rb handel1 handle2 handle3
```


## Miscellaneous docker commands 

```
docker save -o dspace-cli.docker  dspace-cli 
docker load -i dspace-cli.docker

@ with given user id 
docker run -it -v '/dspace:/dspace' -v `pwd`:/dspace-cli -u 67381 dspace-cli bash
docker run -it -v '/dspace:/dspace' -v `pwd`:/dspace-cli -u 67381 dspace-cli bash

# leave containers running by Ctrl-C Ctrl-D out of bash 
docker exec  -it dspace-cli  bash
```

# Write your Own 

Have a look at the [jrdspace gem](https://github.com/akinom/dspace-jruby). 
Feel free to send an email to  [akinom](https://github.com/akinom) if you ned help or find bugs. 
