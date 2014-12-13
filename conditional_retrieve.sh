#!/bin/bash

if [ "$ACTIVATE_AUTO_RETRIEVE" == "true" ]; then echo "Retrieving spots"; /usr/bin/php /var/www/site/spotweb/retrieve.php; fi