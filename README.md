## Docker Begins


### Installations
docker
docker-compose
docker-machine (from docker toolbox)

#### docker desktop for mac

> Find symlinks `find $(which docker) -type l -ls`

> Mac native application, that you install in /Applications `find /var/run/docker.sock -type l -ls`

> hyperkit does not use docker-machine to create VM. docker-machine and docker desktop for mac can co-exist.

> gives only one VM to run a docker daemon

### docker toolbox on mac
```
docker-machine create -d "virtualbox" project1
docker-machine env project1
docker-machine create -d "virtualbox" project2
docker-machine env project2
eval $(docker-machine env project1)
```
> notice docker_host URL. IP address for each VM is different

##### switch between docker desktop and docker toolbox

```
unset ${!DOCKER_*} #stop using docker-machine if any
eval $(docker-machine env project1) #set env variables to use a docker-machine
```
[SKIP]
##### Run docker command on mac but connect to docker daemon running in docker-machine
`docker -H tcp://192.168.99.102:2376 --tlsverify --tlscert /Users/shadjachaudhari13/.docker/machine/machines/project1/cert.pem --tlscacert /Users/shadjachaudhari13/.docker/machine/machines/project1/ca.pem --tlskey /Users/shadjachaudhari13/.docker/machine/machines/project1/key.pem --tls ps`
[SKIP]

##### To SSH into docker-machine
```
eval $(docker-machine env project1)
docker run -d -p 8000:80 nginx  # browse <daemon ip>:8000 on mac's browser
docker-machine ssh project1
ping <docker-ip> # works
docker run -d nginx
ping <docker-ip> # works without exposing ports
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
ctrl+c
```
> stops container by exiting --tty

[TIP]
#### Daemonize foreground container
```
docker run -it ubuntu
ctrl+p Ctrl+q
```
> tty exits but container still runs in background

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
ctrl+c
type 'exit'

#### stop container
1. docker stop <id>
2. docker -it exec <id> bash # stopping PID1 is stopping container
    $ kill 1

#### Write dockerfile and build image: nginx with telnet,git
- upper case for DIRECTIVEs

[SKIP]
- each Directive is considered as difference in file system(RUN ADD COPY contribute to layer creation), is run in an intermediate container. notice docker build log lines:
            1. running in intermediate container <container-id>
            2. removing intermediate container
            3. using cache
NOTE: Because of portability reasons, folders on host CAN'T be mounted in Dockerfile because the Dockerfile should run anywhere, it shouldnt be dependent on host.            
[SKIP]

```
docker build . -f-<<EOF
FROM nginx
RUN apt-get update
RUN apt-get install telnet git -y
EOF

docker build <remote context> -f-<<EOF
EOF
[TIP] remote context will always copy latest code.
```
#### BUILD
##### build context
```
docker build https://github.com/shadjachaudhari13/nodefun.git -f-<<EOF
FROM node:8
ARG PORT=8080
COPY . .
RUN npm install
ENV PORT 8080
EOF

docker run -d -p 9000:8080 6b43e2004c34 npm start
```
> access 192.168.99.100:9000 in REST client

> note build context

#### COPY
> COPY . . will always invalidate cache if file being copied are changed.
> COPY src dest
> COPY copies files along with their permissions
> src is relative to Dockerfile, dest is absolute path inside container. 
> Can't COPY from parent directory COPY ../ . is invalid. use WORKDIR to set $(pwd)

#### WORKDIR
> sets current working directory for instructions RUN, CMD, ENTRYPOINT, COPY and ADD while building Dockerfile
> WORKDIR(pwd for all subsequent instructions IN Dockerfile) and build context(is where Dockerfile is) are different from each other
> WORKDIR will be created if not existing already, could be a blank folder too
> useful if the executable/artifacts you want to run when container starts are located somewhere in subdirectories
> not recommended to use RUN cd .. like commands
> keep app files in separate dir than root, avoid clutter

[build context continued..]
```
cd ~/Downloads
docker build . -f-<<EOF
FROM node:8
RUN git clone https://github.com/shadjachaudhari13/nodefun
WORKDIR nodefun
RUN npm install
EOF
```
> note build context. Current directory and sub directories are set to build context. keep only required files along with Dockerfile

> make changes to nodefun repository foo=bar1

##### cache: reuse existing layers
[run previous command twice to observe cached lines]
```
docker build . -f-<<EOF
FROM node:8
RUN git clone https://github.com/shadjachaudhari13/nodefun
WORKDIR nodefun
RUN npm install
EOF
``
> sample output

Sending build context to Docker daemon    125kB
Step 1/4 : FROM node:8
 ---> 1f6c34f7921c
Step 2/4 : RUN git clone https://github.com/shadjachaudhari13/nodefun
 ---> *Using cache*
 ---> 1eef8c4feaca
Step 3/4 : WORKDIR nodefun
 ---> Using cache
 ---> 28f94c66a848
Step 4/4 : RUN npm install
 ---> Using cache
 ---> ff3438c4324d
Successfully built ff3438c4324d
```

TIP:
1. share code from local
2. set remote context
3. keep instructions that are likely to bring bring change at the end of file
4. trick the Dockerfile!!! (add instruction that will invalidate cache at correct moment)

```
docker build . -f-<<EOF
FROM node:8
RUN echo $(date)>trick.log
RUN git clone https://github.com/shadjachaudhari13/nodefun
WORKDIR nodefun
RUN npm install
EOF
```

#### Push/Pull image:tag to repository
```
docker tag <image-id> shadjachaudhari/nodefun:mydemo
docker login
docker push shadjachaudhari/nodefun:mydemo
docker tag <image-id> shadjachaudhari/nodefun
docker push shadjachaudhari/nodefun
```
> docker pull fetches independent layers in parallel

> when tag not mentioned latest tag is applied,replaced

##### Use your own image as base image
```
docker build . -f-<<EOF
FROM shadjachaudhari/nodefun:mydemo #checks local repository first then remote. "IfNotExist PullPolicy"
RUN echo hello
```
#### VOLUME
> share code repo on the host with docker container, dynamic changes to app and test quickly

> store gems/requirements in volume and share such volume with app container. this way dependencies can be cached and reused while only new ones will be added/removed

> VOLUME directive in dockerfile makes sure a mount point is initialized when container runs

> containers can share volumes with each other

> sharing data is not same as copying data into containers


## Docker Compose Rises


#### docker compose volumes: use case: dependencies in separate container from app
```
git clone https://github.com/shadjachaudhari13/rubyfun.git
cd rubyfun
docker-compose -f docker-compose-v1.yaml up --build
```
> source code shared at /rubyfun

> dependency are getting installed everytime. can they be reused?
```
docker-compose -f docker-compose-v2.yaml up --build
docker-compose -f docker-compose-v2.yaml up --build
docker volume ls
docker images
```
> name of docker image built by docker-compose
Note: ruby image is 900mb. Lets save it offline.

```
docker save -o rubyfun.tar <image-id>
docker rmi -f $(docker images -q)
docker-compose -f docker-compose-v2.yaml up --build # kill process when you see layers are being pulled freshly
docker load -i rubyfun.tar
docker-compose -f docker-compose-v2.yaml up # all layers exists
```

#### ENV
- variables used in Dockerfiles
[PORT nodefun ARG vs ENV demo] (https://github.com/shadjachaudhari13/nodefun/blob/master/Dockerfile)

#### Modify app dynamically using volumes: nodefun
[Dynamic update demo] (https://github.com/shadjachaudhari13/nodefun/blob/master/index.js)

```
https://github.com/shadjachaudhari13/nodefun.git
cd nodefun
docker-compose up --build --force-recreate
# change index.js
docker-compose up --force-recreate

##### give up sudo privilleges
[why not to run container as root](./uid-demo-Dockerfile)
```
sudo chmod 600 secrets.txt
docker build -f uid-demo-Dockerfile --no-cache .
docker run <image-id>
```
#### write docker compose with networks
[demo nginx with host network] (./docker-compose-nginx.yaml)
[keep changing PORT] (./default.conf)
[demo docker-compose networks] (./docker-compose-networks.yaml)
> multiple networks in one compose file
> one container can get multiple IPs as it can belong to multiple networks

#### How to build parent image? Ways to create images?
> Build from scratch: your first layer of fs

> debootstrap to tar
example https://github.com/tianon/docker-brew-ubuntu-core/blob/185c5e23efaa8c7c857683e6dcf4d886acda3cba/trusty/Dockerfile

> docker commit <container-id> shadjachaudhari/rubyfun:latest
