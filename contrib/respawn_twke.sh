#!/bin/bash
#
# Runs TWKE. If it fails/exits, restart with the latest version
#
# This script assumes that you've created a user account e.g. `twke`
# whose home directory can be used for log files. Either this user
# or the system should have an rvm installation with Ruby 1.9.2. Copy
# this script into that user's ~/bin
#
# You can then put a command such as the following in your
# /etc/inittab to ensure twke always restarts with the latest
# code, including through the 'twke respawn' command:
#
# # Run twke
# twke:345:respawn:/bin/su -c '/home/twke/bin/respawn_twke.sh' twke


# The repo you want to clone your twke from, override to use
# your own fork (suggested)
REPO="git@github.com:josephruscio/twke.git"

# This is where we'll run twke from
BASEDIR="/tmp/twke_run"

# monit uses this
PIDFILE="$BASEDIR/twkerun.pid"

# The API key of your bot's campfire user
APIKEY=""

# The domain of your campfire account
DOMAIN="ohai"

# The initial room you'd like to connect to
ROOM="470001"

RUNLOG="$HOME/runtwke.log"
LOG="$HOME/twke.log"

BUNDLE_DIR="/tmp/twke_bundle_cache"

export PATH="$PATH:/usr/local/bin:$HOME/git/awsam/bin"

# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
	# First try to load from a user install
	source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
	# Then try to load from a root install
	source "/usr/local/rvm/scripts/rvm"
else
	printf "ERROR: An RVM installation was not found.\n"
	exit 1
fi

rvm use ruby-1.9.2 >> $RUNLOG 2>&1 || \
	{ echo "Failed to switch to Ruby 1.9.2" >> $RUNLOG ; exit 1; }

mkdir -p $BASEDIR

rm -rf $BASEDIR/*

REPODIR=`mktemp -d $BASEDIR/repo.XXXXXX`

git clone -q $REPO $REPODIR >> $RUNLOG 2>&1 || \
	{ echo "Failed to clone twke repo!" >> $RUNLOG; exit 1; }

pushd $REPODIR >> $RUNLOG

mkdir -p $BUNDLE_DIR || \
	{ echo "Failed to create bundler cache: $BUNDLE_DIR" >> $RUNLOG; exit 1; }

bundle install --path $BUNDLE_DIR/gems >> $RUNLOG 2>&1 || \
	{ echo "Failed to install twke gems"; exit 1; }

# Use this directory as Twke's base temporary directory
TMPDIR=`mktemp -d $BASEDIR/runtmp.XXXXXX`

export TMPDIR
bundle exec ./bin/twke -k "$APIKEY" -s "$DOMAIN" -r "$ROOM" >> $LOG 2>&1

#echo $! > $PIDFILE

popd > /dev/null
