#!/bin/bash
set -e

#==============================================================================
#  Installation: (This can be done using the YMAP commandline admin interface.)
#       (run by: "bash YMAPcl.sh" and then use the green highlighted command option.)
#
#	1. Adjust this to the location of your "ymap_daemon.php" file.
DAEMON_OPTS_temp
#
#	2. Save this file to: "/etc/init.d/ymap_daemon"
#
#	3. chmod +x "/etc/init.d/ymap_daemon"
#
#------------------------------------------------------------------------------
#
# Reload units:
#	systemctl daemon-reload
#
# Starting and stopping the daemon:
#	Start: `service ymap_daemon start` or `/etc/init.d/ymap_daemon start`
#	Stop: `service ymap_daemon stop` or `/etc/init.d/ymap_daemon stop`
#
# Daemon status:
#	systemctl status ymap_daemon.service
#------------------------------------------------------------------------------
#
# References for this code.
#	http://till.klampaeckel.de/blog/archives/94-start-stop-daemon,-Gearman-and-a-little-PHP.html
#	http://unix.stackexchange.com/questions/85033/use-start-stop-daemon-for-a-php-server/85570#85570
#	http://serverfault.com/questions/229759/launching-a-php-daemon-from-an-lsb-init-script-w-start-stop-daemon
#	https://www.bram.us/2013/11/11/run-a-php-script-as-a-servicedaemon-using-start-stop-daemon/
#
#------------------------------------------------------------------------------

NAME="ymap_daemon";
DESC="Daemon for the YMAP data processing queue.";
PIDFILE="/var/run/${NAME}.pid";
LOGFILE="/var/log/${NAME}.log";

DAEMON="/usr/bin/php";

START_OPTS="--start --background --make-pidfile --pidfile ${PIDFILE} --chuid www-data:www-data --exec ${DAEMON} ${DAEMON_OPTS}";
STOP_OPTS="--stop --pidfile ${PIDFILE}";

test -x $DAEMON || exit 0

set -E

case "$1" in
    start)
        echo -n "Starting ${DESC}: ";
        start-stop-daemon $START_OPTS >> $LOGFILE;
        echo -e "$NAME.";
	;;
    stop)
        echo -n "Stopping $DESC: ";
        start-stop-daemon $STOP_OPTS >> $LOGFILE;
        echo -e "$NAME.";
        rm -f $PIDFILE;
	;;
    restart|force-reload)
        echo -n "Restarting $DESC: "
        start-stop-daemon $STOP_OPTS >> $LOGFILE;
        sleep 1;
        start-stop-daemon $START_OPTS >> $LOGFILE;
        echo -e "$NAME.";
	;;
    *)
        N=/etc/init.d/$NAME
        echo -e "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
    ;;
esac

exit 0
