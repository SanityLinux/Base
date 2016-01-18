#!/bin/sh
echo "Updating Ports..."
cd /usr/ports && env CVS_RSH=ssh cvs up -dP
