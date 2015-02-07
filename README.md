# Intro

Docker image to run Spotweb. You can find more info on Spotweb here:

* https://github.com/spotweb/spotweb/wiki
* https://github.com/spotweb/spotweb

Disclaimer: do not download illegal stuff!

## Prerequisites

Spotweb has a dependency on MySql. I'm following the advice in this article: https://medium.com/@ramangupta/why-docker-data-containers-are-good-589b3c6c749e

I opted to use a data volume container as opposed to mounting a host directory as a data volume. If you're on linux, you can still try the latter, but on OSX Yosemite I found that there are permission issues: https://github.com/boot2docker/boot2docker/issues/581

Let's set up a data-only container:

    docker run --name docker-spotweb-db -d -v /var/lib/mysql tutum/ubuntu-trusty

Next, set up the mysql server using this volume:

    docker run --name docker-spotweb-mysql -d -p 3306:3306 -e MYSQL_DATABASE=spotweb -e MYSQL_USER=spotweb -e MYSQL_PASSWORD=spotweb -e MYSQL_ROOT_PASSWORD=pw4root --volumes-from docker-spotweb-db centurylink/mysql


The database is still empty at this point. I'll show you how to create backups later, but make sure you understand how the container-as-a-volume pattern works so you don't lose any data: https://docs.docker.com/userguide/dockervolumes/


## Usage

First clone the repository, then build the container:

    docker build -t andyverbunt/docker-spotweb .

And run it. I'm giving it a name so it's easy to reference it when it needs to be stopped:

    docker run --name=docker-spotweb -p 9000:80 -d andyverbunt/docker-spotweb

Point your browser to the install page. Your ip address may vary (use 'boot2docker ip' on OSX):

    http://192.168.59.103:9000/spotweb/install.php

Now configure the system. Make sure the credentials for the database connection match those in the instructions above. Create the system. You will also have to create the dbsettings.inc.php file on your host system with the content as instructed. It will look something like this:

	<?php 
	$dbsettings['engine'] = 'pdo_mysql';
	$dbsettings['host'] = '192.168.59.103';
	$dbsettings['dbname'] = 'spotweb';
	$dbsettings['user'] = 'spotweb';
	$dbsettings['pass'] = 'spotweb';


Then start it again with the settings file mounted as a data volume. Make sure you use the correct path to dbsettings.inc.php as the command will not fail but you'll get some weird errors in your browser:

    docker stop docker-spotweb && docker rm docker-spotweb
    docker run --name=docker-spotweb -p 9000:80 -v /path/to/dbsettings.inc.php:/var/www/site/spotweb/dbsettings.inc.php -d andyverbunt/docker-spotweb

Point your browser to the running spotweb:

    http://192.168.59.103:9000/spotweb

Login with the credentials you provided during install. Take the time to configure the preferences and the settings.
Once this is done, you still don't have any spots, but all the settings are persisted in the database. This is a good time to make a backup:

    docker run -rm --volumes-from docker-spotweb-db -v $(pwd):/backup busybox tar cvf /backup/backup-docker-spotweb-db.tar /var/lib/mysql

The container will retrieve new spots every hour. If you don't want to wait for it to start automatically, you can start it now: 

    docker exec -t -i docker-spotweb /usr/bin/php /var/www/site/spotweb/retrieve.php

If needed, you can simply restart the script and it will pick up where it left. It will take a while (hours, days, ...) depending on your settings.

## Summary

When you followed the instructions above, you should have three containers running:

- docker-spotweb-db
- docker-spotweb-mysql
- docker-spotweb

This is where you need to be (ip address may be different):

    http://192.168.59.103:9000/spotweb

If you ever reboot your machine, only restart the last two containers! The first one does not need to run since it contains only the data.

## Tips and tricks

Should you lose your database you can easily restore it if you still have the backup:

    docker run -rm --volumes-from docker-spotweb-db -v $(pwd):/backup busybox tar xvf /backup/backup-docker-spotweb-db.tar

If you have a machine that goes to sleep, you'll have to sync the clock periodically because the clock of the host will go out of sync with the clock of the container.
On OSX you can do this:

    boot2docker ssh sudo ntpclient -s -h pool.ntp.org

