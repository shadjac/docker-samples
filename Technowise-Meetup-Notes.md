# Technowise Docker Meetup Notes

#### <create new shell session : tab 1>

`$ git clone https://github.com/shadjachaudhari13/nodeshark.git`

`$ cd nodeshark`

`$ docker run node:10-alpine`

`$ docker ps # see no running containers`

`$ docker ps -a. # see one stopped container`

`$ docker run node:10-alpine sh` # runs process 'sh' once container is running, exits once process is complete

`$ docker ps` # see no running containers

`$ docker ps -a`  # see two stopped containers

`$ docker run -it node:10-alpine sh`  # this is your first running {container 1}

#### <create new shell session : tab 2>

`$ pwd` # nodeshark directory from Line 4

`$ docker ps # get ID of a running container

`$ docker cp . <container 1>:/.`  # copy contents from current dir nodeshark to container root filesystem at /

#### <switch to shell session: tab 1 from Line 2>

`$ ls` # contents copied can be seen here

`$ pwd` # should show  just /. as its a the root filesystem for container

`$ npm install` # to fetch dependencies using package.json

`$ export PORT=5050`

`$ node app.js` # app is now running at port 5050

#### <switch to shell session: tab 2 from Line 12>

`$ docker exec -it <container 1> sh` # opens door to already running container

`$ wget http://localhost:5050` # index.html is downloaded

`$ exit` # come out of container, this also stops the container

`$ docker rm <container 1 ID>` # removes the stopped container

"CMD node app.js" add this as last line in crude.Dockerfile

`$ docker build -f crude.Dockerfile .`

`$ docker run -d -p 5050:5050 <image-id>.`  # this is {container 2}

[access application in web browser localhost:5050]

`$ docker exec -it <container 2> sh`

`$ whoami` # show "root" default user is root unless specified otherwise

`$ ls` # contents of nodeshark dir

`$ pwd` # shows just "/"

`$ uname -a` # shows alpine linux distribution

`$ printenv` # show PORT as environment variable set 

`$ ls node_modules` # node packages downloaded by "npm install"

`$ exit`

[Let's build same dockerfile again.]

`$ docker build -f crude.Dockerfile .`

[all build log lines say "using cache"]

add "RUN ls -la node_modules" before "CMD node app.js" in crude.Dockerfile

`$ docker build -f crude.Dockerfile .`

`$ docker build . --no-cache`

`$ docker build <git repo url>`

`$ docker tag <image-id> <repo-name>:<tag>`

`$ docker tag 12345678 your-name/nodeshark:mydemo`

`$ docker push your-name/nodeshark:mydemo`

`$ which docker` # see what you installed where you installed

`$ git clone https://github.com/shadjachaudhari13/expense-tracker-nodejs.git`

`$ cd expense-tracker-nodejs`

`$ docker-compose up`

`$ docker-compose -f docker-compose-with-persist-data.yaml up`

`$ docker-compose -f docker-compose-node-dependencies.yaml up`

