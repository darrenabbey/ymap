#! /bin/sh

# Installation
# - Move this to /etc/init.d/ymap_daemon
# - chmod +x this
#
# Starting and stopping
# - Start: `service ymap_daemon start` or `/etc/init.d/ymap_daemon start`
# - Stop: `service ymap_daemon stop` or `/etc/init.d/ymap_daemon stop`

#ref http://till.klampaeckel.de/blog/archives/94-start-stop-daemon,-Gearman-and-a-little-PHP.html
#ref http://unix.stackexchange.com/questions/85033/use-start-stop-daemon-for-a-php-server/85570#85570
#ref http://serverfault.com/questions/229759/launching-a-php-daemon-from-an-lsb-init-script-w-start-stop-daemon
#ref https://www.bram.us/2013/11/11/run-a-php-script-as-a-servicedaemon-using-start-stop-daemon/

NAME="ymap_daemon";
DESC="Daemon for the YMAP data processing queue.";
PIDFILE="/var/run/${NAME}.pid";
LOGFILE="/var/log/${NAME}.log";

DAEMON="/usr/bin/php"
DAEMON_OPTS="/var/www/html/ymap/ymap_daemon.php"

START_OPTS="--start --background --make-pidfile --pidfile ${PIDFILE} --exec ${DAEMON} ${DAEMON_OPTS}"
STOP_OPTS="--stop --pidfile ${PIDFILE}"

test -x $DAEMON || exit 0

set -e

case "$1" in
    start)
        echo -n "Starting ${DESC}: "
        start-stop-daemon $START_OPTS >> $LOGFILE
        echo "$NAME."
        ;;
    stop)
        echo -n "Stopping $DESC: "
        start-stop-daemon $STOP_OPTS
        echo "$NAME."
        rm -f $PIDFILE
        ;;
    restart|force-reload)
        echo -n "Restarting $DESC: "
        start-stop-daemon $STOP_OPTS
        sleep 1
        start-stop-daemon $START_OPTS >> $LOGFILE
        echo "$NAME."
        ;;
    *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0
