---
layout:   post
title:    "PHP Web Development with Docker"
date:     2016-01-22 00:00:00
author:   "Manuele Menozzi"
tags:     [devops, docker]
---

As web developer I always have to deal with the fact that every project has its own dependencies and requirements. At application level a good dependency management tool does the job (as PHP developer I love [Composer](https://getcomposer.org/)) but a web project has not only application dependencies, there are also system/infrastructure requirements. On the production or test environment we can setup project's specific dependencies because these environments are often dedicated to that project but this may not be true for local development environment. This is especially true for me because I have to deal with many different projects.

Anyway, until few days ago, I always developed my applications with the classic [LAMP stack](https://en.wikipedia.org/wiki/LAMP_(software_bundle)) running directly on my local (and phisical) machine. In the past I tried [Vagrant](https://www.vagrantup.com/) but then I always come back to my local machine. Why? Because I always wanted to use my host’s IDE to edit project source files but run applications inside a virtual machine and keep source files on the host machine it’s not as easy as it seems. One of the most commonly used approach is to have the project’s directory on the host system mounted inside the virtual machine. This is, for example, the standard approach for Vagrant which mounts current working directory of the host in `/vagrant` path of the virtual machine. I always found that this approach has performance issues because the mounted file system is very slow even with an NFS mount. This is especially true for PHP which does much filesystem access for class loading. Besides this a virtual machine for each projects requires much disk space. So, as I said, I always come back to my local machine.

But things changes and few days ago I decided to take time to find a good solution that allows to have different development environments, each one specific for each project. Why now? Because on these days many different technologies are changing in the PHP world (Magento 2, Symfony 3, Drupal 8 and PHP 7 to say some of them) and I want to be able to work on these amazing new technologies while continuing to support old legacy projects.

So I decided to try [Docker](https://www.docker.com/) and I want to share my experience in this blog post.

Docker
------

What is Docker? Let's take its definition on the official [Docker website](https://www.docker.com/what-docker):

> Docker allows you to package an application with all of its dependencies into a standardized unit for software development.

> Docker containers wrap up a piece of software in a complete filesystem that contains everything it needs to run: code, runtime, system tools, system libraries – anything you can install on a server. This guarantees that it will always run the same, regardless of the environment it is running in.

Starting from its definition it seems perfect! It isn’t?

Docker is available for Linux, Mac OS X and Windows but because is based on Linux kernel features it requires a Linux virtual machine in Mac OS X and Windows. I work on a Mac Book Pro so is this the case for me and I have to download a package called [Docker Toolbox](https://www.docker.com/docker-toolbox) which installs different components including [Oracle VM Virtual Box](https://www.virtualbox.org/) that is used by Docker to run a Linux virtual machine where Docker directly runs.

Docker Images & Docker Hub
--------------------------

Basically Docker allows to run several isolated containers. You can think a container like as a virtual machine even if it isn't a virtual machine. Containers can be built from scratch or from a base Docker image. You can think an image as a VM snapshot. Images can be found on a central public repository called [Docker Hub](https://hub.docker.com/). Here you can find many images developed by the community; there are also official images, provided by Docker, for mostly used technologies.
Containers can also be built from a local [Dockerfile](https://docs.docker.com/engine/reference/builder/) which contains directives on how to build the container.

PHP (with Apache) Container
---------------------------

I'm a PHP web developer so I need a PHP container to run my applications and I also need a web server. Even if, with Docker, I could use two different containers I prefer, for semplicity, to use a single container with Apache and PHP together. This is a very simple solution because on Docker Hub there's the [official PHP image](https://hub.docker.com/_/php/) with Apache ready to use.
Unfortunately this is only a basic image, for example it misses most commonly used PHP extensions like gd, mysql or xdebug. So I decided to build my own image starting from the official PHP-Apache image. The result is the [webgriffe/php-apache-base](https://hub.docker.com/r/webgriffe/php-apache-base/) image, available on Docker Hub, which we use in [Webgriffe®](http://www.webgriffe.com/) as base image for development of PHP projects. We support PHP 5.5, 5.6 and 7; for more information about features of this image have a look at the [repository's readme](https://github.com/webgriffe/docker-php-apache-base).
So, for example, I can run the container image with the following command:

	$ docker run -p 80:80 webgriffe/php-apache-base

The `-p` option allows to map a port of the host to a port of the container. As you know Apache, by default, exposes port 80 so with `-p 80:80` I can connect to port 80 of my host and "see" Apache running on the container.
Thanks to the Dockerfile I can also build a custom container for a project with specific needs. For example, if in another project I need PHP 5.5 and the PHP mongodb extension then I can place a Dockerfile in my project directory with something like this:

	FROM webgriffe/php-apache-base:5.5
	RUN docker-php-ext-install mongo // I have not really tested this line (it's only an example)

Then I can build the container from the Dockerfile (assuming it’s in the current working directory):

	$ docker build -t my-container-name .
	$ docker run -p 80:80 my-container-name
	
Developing PHP applications doesn't consist only into running it from Apache but also from running it from command line. I may also need to run automated tests or install dependencies with Composer. When I need to do this, with Docker I can easily access to the PHP-Apache container through SSH:

	manuele@host$ docker exec -ti php-apache-container-name /bin/bash

And then run commands inside the development environment:

	root@container$ php myapp.php
	root@container$ phpunit -c phpunit.xml
	root@container$ composer install


Project source files on the container 
-------------------------------------

Docker containers are, by default, isolated because they have to be portable. To achieve this isolation and portability Docker containers's file system is volatile. This means that you lose every change to container's files when you stop it. So Docker containers are not designed to be "editable", them should be "immutable".

As you may notice, this isolation isn't indicated for development purposes because I would like to edit project source files on my host system and then immediately run that change on the Docker container.
Fortunately Docker has a [data volume feature](https://docs.docker.com/engine/userguide/dockervolumes/) which allows to mount an host folder inside the container. For example, given that the current working directory is `/path/to/my/project` I can run:

	$ docker run -p 80:80 -v .:/var/www/html image

And Docker mounts my project files in the `/var/www/html` path of the container which is also the document root path of Apache. So in this way I can edit project files on the host and run it on the container.

Performance improvements on OS X 
--------------------------------

As said before, on OS X Docker runs on a Oracle VirtualBox Linux virtual machine (also known as [docker machine](https://docs.docker.com/machine/)). To make work the data volume feature the docker machine mounts the user's home directory from the host to the docker machine itself. This mount is done through the vboxsf which is terribly slow! I think that performances are important even for development environments because allows people to be more productive. With this setup I found that a [Magento](http://magentocommerce.com) 1.x application running on Docker was over 10 times slower than the same application running on my host. So I decided to keep searching a more performant solution.

First I tried [dinghy](https://github.com/codekitchen/dinghy) which is basically an alternative docker machine but with an NFS mount instead of vboxsf. NFS is much faster so, with dinghy, things have improved a lot (4/5 times slower than host) but it wasn't enough for me because I didn’t want a performance loss by switching to Docker as dev environment.

So I finally found [Docker Unison](https://github.com/leighmcculloch/docker-unison) which is a two-way fast file sync system. Basically I have to start a special Docker container which runs the Unison server:

	$ CID=$(docker run -d -p 5000:5000 -e UNISON_VERSION=2.48.3 leighmcculloch/unison)

Then I have to run the Unison client command from the project directory of my host so files will be synced to the `/unison` path of the Unison server Docker container:

	$ unison . socket://<docker>:5000/ -auto -batch

Combining Unison with fswatch (`brew install fswatch`) I can continuously sync my project files:

	$ fswatch -o . | xargs -n1 -I{} unison . socket://<docker>:5000/ -ignore 'Path .git' -auto -batch

Also notice that Unison is two-way sync, so not only host changes will be pushed to Docker but also the viceversa. This is important because many frameworks have code generation features while running so I want back this files to my host to better read code and debug during development.
Then I can use the `--volumes-from` feature of Docker to mount the `/unison` path of Unison container as a volume inside the docker container which runs the application.

	$ docker run --volumes-from $CID webgriffe/php-apache-base

With this setup my project files are under the `/unison` path of the `webgriffe/php-apache-base` container and not under `/var/www/html` which is the default Apache document root.
Fortunately `webgriffe/php-apache-base` image allows to change the Apache document root through the `APACHE_DOC_ROOT` environment variable so I can do:

	$ docker run --volumes-from $CID -e "APACHE_DOC_ROOT=/unison" webgriffe/php-apache-base
	
Et voilà! I have a PHP-Apache container with project files continuously synchronized with my host. With this setup I have the same performances of my host and this is great!

MySQL and data-only containers
------------------------------

Almost every PHP web application needs a database for data persistence. Most of the times this database is MySQL. With Docker is very easy to start a MySQL container because there are official images ready to use without configuration:

	$ docker run mariadb

Notice that I use [mariadb](https://hub.docker.com/_/mariadb/) instead of Oracle’s [mysql](https://hub.docker.com/_/mysql/) image because I found that is quite faster and is completely open source.
But as I said before Docker containers filesystem is volatile and, of course, database data are stored on the filesystem (precisely under `/var/lib/mysql`) so what happens with Docker is that, with this setup, if I stop the MySQL container I lose all of my database changes. I don't want this so, as before, Docker’s volumes feature is the solution:

	$ docker run -v /var/lib/mysql mariadb

With this command Docker mounts a folder of the host system of its choice into the `/var/lib/mysql` path of the container so I can restart it without losing my database data.

But what if I need to update MySQL container? Notice that when you update a Docker container (for example because you want an upgraded version of the `mariadb` image) it’s recreated and volume data will be lost so if I update the mysql container I'd lose database data.
Fortunately I can do a [data-only container](https://medium.com/@ramangupta/why-docker-data-containers-are-good-589b3c6c749e):

	$ CID=$(docker run -d -v /var/lib/mysql tianon/true)

and then mount the volume from the data-only container into the mysql container:

	$ docker run --volumes-from $CID mariadb

The advantage of this approach is that `tianon/true` is a super minimal Docker image created specifically for data-only containers and likely won't ever need to be updated so database data won’t be lost.

Other components
----------------

Ok, now I have PHP-Apache container with my project files and a MySQL container with persistent data storage. So I have a LAMP stack built with Docker containers and I could have different version of the stack for every project. Isn’t it cool?
But with Docker I can easily go over and build more complex environments. I mainly work with Magento which have a [Memcached](http://memcached.org/) cache adapter and it’s common to use it with a Memcached instance in production for performances reasons. With Docker I can have the same setup even for development environment which is a great thing:

	$ docker run memcached

I start a new container from the official [memcached](https://hub.docker.com/_/memcached/) image and I’m done!
For another project I may need a NoSQL database like [MongoDB](https://www.mongodb.org/):

	$ docker run —volumes_from $MONGO_DATA_CONTAINER_NAME mongo

Again I can start another container from official [mongo](https://hub.docker.com/_/mongo/) image keeping in mind that, as MySQL, we need a data-only container.
And so on, we can go over and have a container for every component that our application may need. Indeed, one of the best practices that Docker documentation suggests is to keep each component on a separate container.

Putting it all together - Docker Compose
----------------------------------------

As you may understand, it could be very unconfortable to start several containers every time that we have to start our development environment. To overcome this there's [Docker Compose](https://docs.docker.com/compose/) which allows to specify a multiple containers setup in a single YML file (`docker-compose.yml`). Then it’s possible to start all the required containers with a single command.
For example, this is my `docker-compose.yml` for a Magento 1.x application:

    php:
      image: webgriffe/magento1-dev
      container_name: application-container
      volumes_from:
        - unison
      volumes:
        - "~/.composer:/root/.composer"
        - "~/.ssh:/root/.ssh"
      links:
        - memcached
        - mariadb
        - blackfire_agent:blackfire
      ports:
        - "80:80"
      environment:
        HOST_IP: 192.168.99.1
        APACHE_DOC_ROOT: /unison
      working_dir: /unison

    unison:
      image: leighmcculloch/unison
      environment:
        - UNISON_VERSION=2.48.3
      ports:
        - "5000:5000"

    mariadb-data:
      image: tianon/true
      volumes:
        - /var/lib/mysql

    mariadb:
      image: mariadb:10.1.10
      volumes_from:
        - "mariadb-data"
      environment:
          MYSQL_ROOT_PASSWORD: p4ssw0rd

    memcached:
      image: memcached

    blackfire_agent:
        image: blackfire/blackfire
        environment:
            - BLACKFIRE_SERVER_ID
            - BLACKFIRE_SERVER_TOKEN
            - BLACKFIRE_CLIENT_ID
            - BLACKFIRE_CLIENT_TOKEN

Explaination:

* `php` is the PHP-Apache container built from `webgriffe/magento1-dev` (which is a Magento 1.x dev image based on `webgriffe/php-apache-base`, currently supporting only PHP 5.5) with `/unison` volume mounted from Unison container. The `HOST_IP` environment variable is used by `webgriffe/php-apache-base` image to configure the xdebug remote host so I'm able to use xdebug from my host machine. The `container_name` is a custom and fixed container name because I have configured on my local shell the alias `alias dar="docker exec -ti application-container"` so I can quickly run commands inside my Docker application container with `$ dar <command>`. The volume mappings `~/.composer:/root/.composer` and `~/.ssh:/root/.ssh` allows Composer and SSH to successfully authenticate with credentials and keys from my host machine.
* `unison`, as explained before, is the Unison container which keeps in sync project files with my host
* `mariadb` and `mariadb-data` are the MySQL and related data-only containers.
* `memcached` is the Memcached container used by Magento for caching and sessions.
* `blackfire_agent` is a [Blackfire.io](https://blackfire.io/) container used for application profiling. The Blackfire Probe (the PHP extension) is installed in the PHP-Apache container by the `webgriffe/php-apache-base` image.

With this `docker-compose.yml` file I can run a single command:

	$ docker-compose up -d
	
And all the containers are automatically created and started. Then I have to start file sync with Unison (replacing `<docker>` with my docker machine IP address):

    $ fswatch -o . | xargs -n1 -I{} unison . 'socket://<docker>:5000/' -ignore 'Path .git' -auto -batch

And I'm done!

Conclusion
----------

So, let's recap. With Docker I can start my project-specific development environment at any time, I can edit project files on my host and immediately see the change. I can also run commands inside my application container so I can run automated tests, static code analysis tools and, of course, CLI applications. Last but not least I can continously improve Docker development environment images like `webgriffe/php-apache-base` and `webgriffe/magento1-dev` using GIT versioning and [Docker Automated Builds](https://docs.docker.com/docker-hub/builds/). Not bad!
