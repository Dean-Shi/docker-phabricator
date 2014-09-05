#!/bin/sh

docker run -i -d -p 3306:3306 -p 80:80 -p 22:22 -v /data/phabricator/mysql:/var/lib/mysql -v /data/phabricator/repo:/var/repo -v /data/phabricator/conf:/opt/phabricator/conf yesnault/docker-phabricator

