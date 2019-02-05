## Docker Begins

## Installations
docker
docker-compose
docker-machine (from docker toolbox)
### docker toolbox on mac
```
docker-machine create -d "virtualbox" project1
docker-machine env project1
docker-machine create -d "virtualbox" project2
docker-machine env project2
eval $(docker-machine env project1)
```
> notice docker_host URL. IP address for each VM is different
##### Run docker command on mac but connect to docker daemon running in docker-machine
`docker -H tcp://192.168.99.102:2376 --tlsverify --tlscert /Users/shadjachaudhari13/.docker/machine/machines/project1/cert.pem --tlscacert /Users/shadjachaudhari13/.docker/machine/machines/project1/ca.pem --tlskey /Users/shadjachaudhari13/.docker/machine/machines/project1/key.pem --tls ps`
##### To SSH into docker-machine
```
docker-machine ssh project1
ifconfig #Notice docker0 interface
docker run -d nginx
ping 192.168.99.102:80 # without publishing port on container
ping 172.17.0.2 
```
#### docker desktop for mac
> Find symlinks
`find $(which docker) -type l -ls`
> Mac native application, that you install in /Applications
`find /var/run/docker.sock -type l -ls`
> hyperkit does not use docker-machine to create VM. docker-machine and docker desktop for mac can co-exist.
> gives only one VM to run a docker daemon
##### switch between docker desktop and docker toolbox
```
unset ${!DOCKER_*} #stop using docker-machine if any
eval $(docker-machine env project1) #set env variables to use a docker-machine
```

#### Run a container:busybox and start first process -  PID 1
syntax `docker run <image>`
```bash
docker run busybox echo hello
docker run busybox cat /etc/hostname
```
> container exits as PID 1 has done its job and terminated
```
docker run busybox sleep 300
containerid=$(docker ps | awk 'NR > 1 {print $1}')
docker top $containerid
```
> PID 1 would be 'sleep 300'
#### Exit foreground container in different ways
exit
ctrl+c
#### Run a container:busybox in interactive mode
Interactive containers are useful when you are putting together your own image. You can run a container and verify all the steps you need to deploy your app, and capture them in a Dockerfile
```
docker run --interactive --tty ubuntu
apt-get update && apt-get install telnet git -y
```
> stops container by exiting --tty
#### Run container in background - detached mode
```
docker run -d ubuntu
```
#### Enter container running in detached mode
```
containerid=$(docker ps | awk 'NR > 1 {print $1}')
docker exec --interactive --tty $containerid bash
apt-get update
```
#### Exit background container in different ways
kill PID 1 and exit are not same
docker stop
#### Daemonize foreground container
```
docker run -it ubuntu
ctrl+p Ctrl+q
```
> tty exits but container still runs in background
#### Write dockerfile and build image: nginx with telnet,git
- upper case for DIRECTIVEs
- each Directive is considered as difference in file system, is run in an intermediate container. notice docker build log lines:
            running in intermediate container <container-id>
            removing intermediate container
            using cache
- Because of portability reasons, folders on host CAN'T be mounted in Dockerfile because the Dockerfile should run anywhere, it shouldnt be dependent on host.

```
docker build . -f-<<EOF
FROM nginx
RUN apt-get update
RUN apt-get install telnet git -y
EOF
```
#### BUILD
##### build context
```
cd ~/Downloads
docker build . -f-<<EOF
FROM nginx
RUN apt-get update
RUN apt-get install telnet git -y
RUN git clone https://github.com/shadjachaudhari13/nodefun
EOF
```
> note build context is 100s of KBs
```
cd ..
mkdir testDir && cd testDir
docker build . -f-<<EOF
FROM nginx
RUN apt-get update
RUN apt-get install telnet git -y
RUN git clone https://github.com/shadjachaudhari13/nodefun
EOF
```
> note build context is couple of KBs. Current directory and sub directories are set to build context. keep only required files along with Dockerfile
##### cache: reuse existing layers
```
docker build . -f-<<EOF
FROM nginx
# compare with previous build log. intermediate container ID is same
# using cache
RUN apt-get update
# using cache
RUN apt-get install telnet git -y
# new layer is generated every time
RUN echo $(date) > hack
# not using cache, as cache got invalidated by previous instruction
RUN git clone https://github.com/shadjachaudhari13/nodefun
EOF
```
#### Push/Pull image:tag to repository
```
docker tag <image-id> shadjachaudhari/nginx:mydemo
docker push shadjachaudhari/nginx:mydemo
docker tag <image-id> shadjachaudhari/nginx
docker push shadjachaudhari/nginx
```
> when tag not mentioned latest tag is applied,replaced
##### Use your own image as base image
```
docker build . -f-<<EOF
FROM shadjachaudhari/nginx:mydemo
RUN echo hello
```
#### VOLUME
> share code repo on the host with docker container, dynamic changes to app and test quickly
> store gems/requirements in volume and share such volume with app container. this way dependencies can be cached and reused while only new ones will be added/removed
> VOLUME directive in dockerfile makes sure a mount point is initialized when container runs
> containers can share volumes with each other
> sharing data is not same as copying data into containers
```
docker run -d -v /Users/shadjachaudhari13/my-github/default.conf:/etc/nginx/conf.d/default.conf shadjachaudhari/nginx:mydemo
docker commit <container id> shadjachaudhari/nginx:mynewdemo
docker run -it shadjachaudhari/nginx:mynewdemo bash
cat /data/default.conf
```
#### docker compose volumes: quick look
```
git clone https://github.com/shadjachaudhari13/rubyfun.git
docker-compose build
docker-compose up
```
> volume "bundle" is shared by container "box" at path /box and container "app" at path /gems. Note that the mount paths are different

#### COPY
```
docker build . -f-<<EOF
FROM shadjachaudhari/nginx:mydemo
COPY default.conf /etc/nginx/conf.d/default.conf
EOF
docker run -d <image-id>
docker commit <container id> shadjachaudhari/nginx:mynewdemo
docker run -it shadjachaudhari/nginx:mynewdemo cat /etc/nginx/conf.d/default.conf
```
> COPY src dest
> COPY copies files along with their permissions
> src is relative to Dockerfile, dest is absolute path inside container
#### WORKDIR
> sets current working directory for instructions RUN, CMD, ENTRYPOINT, COPY and ADD while building Dockerfile
> WORKDIR and build context are different from each other
> WORKDIR will be created if not existing already, could be a blank folder too
> useful if the executable/artifacts you want to run when container starts are located somewhere in subdirectories
> not recommended to use RUN cd .. like commands
> keep app files in separate dir than root, avoid clutter
#### ENV
- variables used in Dockerfiles
[PORT nodefun ARG vs ENV demo] (https://github.com/shadjachaudhari13/nodefun/blob/master/Dockerfile)
#### Modify app dynamically using volumes: nodefun
[Dynamic update demo] (https://github.com/shadjachaudhari13/nodefun/blob/master/index.js)
##### give up sudo privilleges
[why not to run container as root](./uid-demo-Dockerfile)
```
sudo chmod 600 secrets.txt
docker build -f uid-demo-Dockerfile --no-cache .
docker run <image-id>
```
#### write docker compose for single container app
- docker-compose ps
- docker-compose down/up/build/kill/rm
build dockerfile in some other directory
> write docker compose for nodefun
#### write docker compose with networks
[demo nginx with host network] (./docker-compose-nginx.yaml)
[keep changing PORT] (./default.conf)
[demo docker-compose networks] (./docker-compose-networks.yaml)
> multiple networks in one compose file
> one container can get multiple IPs as it can belong to multiple networks
#### How to build parent image?
Build from scratch: your first layer of fs
debootstrap to tar
example https://github.com/tianon/docker-brew-ubuntu-core/blob/185c5e23efaa8c7c857683e6dcf4d886acda3cba/trusty/Dockerfile


