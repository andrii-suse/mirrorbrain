#!lib/test-in-container-systemd.sh lib/init/install-from-source.sh

set -ex
source lib/common.sh

mb new karneval --http http://mirror.karneval.cz --rsync rsync://mirror.karneval.cz/opensuse/repositories/network:/ldap --region NA --country us
mb new gwdg --http http://gwdg.de --rsync rsync://ftp.gwdg.de/pub/opensuse/repositories/network:/ldap --region NA --country us
mb new liq --http http://opensuse.mirror.liquidtelecom.com --rsync rsync://opensuse.mirror.liquidtelecom.com/opensuse-full/repositories/network:/ldap --region NA --country us

mb scan --enable karneval &
mb scan --enable gwdg &
mb scan --enable liq &

for site in $mirrors; do
    ( mb scan $site )&
    echo $! : $site
done

FAIL=0
jobs -l
for job in $(jobs -p); do
    wait $job || {
        let "FAIL+=1"
        echo "FAILED: $job"
    }
done

[ -z $FAIL ] || echo failures: $FAIL

if grep -r 'ERROR:  deadlock detected' /var/lib/pgsql/data/log; then
   exit 1
fi

