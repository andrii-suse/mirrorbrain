# Defines the tag for OBS and build script builds:
#!BuildTag: serviced
FROM  opensuse/leap:15.1
ENV container docker
RUN zypper -n install systemd

RUN systemctl mask dev-mqueue.mount dev-hugepages.mount \
    systemd-remount-fs.service sys-kernel-config.mount \
    sys-kernel-debug.mount sys-fs-fuse-connections.mount \
    display-manager.service graphical.target systemd-logind.service

ENV LANG en_US.UTF-8

ADD dbus.service /etc/systemd/system/dbus.service

# RUN zypper -n install apparmor-profiles apparmor-utils
RUN zypper -n install curl hostname iputils vim command-not-found bsdtar zip sudo wget

RUN zypper -n addrepo -p 79 http://download.opensuse.org/repositories/openSUSE:/infrastructure/openSUSE_Leap_15.1/ infra
RUN zypper -n addrepo -p 89 http://download.opensuse.org/repositories/server:/database:/postgresql/openSUSE_Tumbleweed/ pg
RUN zypper -n --gpg-auto-import-keys --no-gpg-checks refresh

RUN zypper -n install python2-cmdln gzip patch
RUN zypper -n install postgresql10-ip4r postgresql postgresql-server

# next three lines is workaround
# RUN zypper -n install python2-PyDispatcher python3-PyDispatcher
# RUN wget http://download.opensuse.org/repositories/openSUSE:/infrastructure/openSUSE_Leap_15.1/noarch/python2-SQLObject-3.8.0-lp151.9.1.noarch.rpm
# RUN rpm -i python2-SQLObject-3.8.0-lp151.9.1.noarch.rpm

RUN zypper -n install mirrorbrain mirrorbrain-scanner apache2-worker apache2-mod_asn apache2-mod_geoip apache2-mod_form mirrorbrain-tools
# RUN zypper -n install --build-deps-only python-mb
# RUN zypper -n install --force apache2-mod_mirrorbrain

RUN wget http://download.opensuse.org/repositories/openSUSE:/infrastructure/openSUSE_Leap_15.1/x86_64/apache2-mod_mirrorbrain-2.19.1-lp151.8.1.x86_64.rpm
RUN rpm -i --nodeps apache2-mod_mirrorbrain-2.19.1-lp151.8.1.x86_64.rpm

# RUN zypper -n install infra:mirrorbrain infra:mirrorbrain-scanner infra:apache2-worker infra:apache2-mod_asn infra:apache2-mod_mirrorbrain infra:mirrorbrain-tools infra:python-mb

RUN zypper -n install gcc python-devel

VOLUME ['/sys/fs/cgroup']
VOLUME ['/run']

VOLUME ['/opt/project']

RUN systemctl enable dbus.service
RUN systemctl enable postgresql

ADD src/sql /usr/share/doc/packages/mirrorbrain/sql

RUN sudo -u postgres /usr/share/postgresql/postgresql-script start && \
    sudo -u postgres createuser mirrorbrain && \
    sudo -u postgres createdb mirrorbrain && \
    sudo -u postgres psql -c "alter user mirrorbrain with encrypted password 'mirrorbrain';" && \
    sudo -u postgres psql -c "CREATE EXTENSION ip4r;" mirrorbrain && \
    sudo -u mirrorbrain psql -f /usr/share/doc/packages/mirrorbrain/sql/schema-postgresql.sql mirrorbrain && \
    sudo -u mirrorbrain psql -f /usr/share/doc/packages/mirrorbrain/sql/migrations/schema-postgresql-add-filearr_split_path_trigger.sql mirrorbrain && \
    sudo -u mirrorbrain psql -f /usr/share/doc/packages/mirrorbrain/sql/initialdata-postgresql.sql mirrorbrain && \
    sudo -u postgres /usr/share/postgresql/postgresql-script stop

RUN sed -i 's,127.0.0.1/32            ident,127.0.0.1/32            password,' /var/lib/pgsql/data/pg_hba.conf

ADD mirrorbrain.conf /etc/mirrorbrain.conf
RUN chmod 0640 /etc/mirrorbrain.conf
RUN chown root:mirrorbrain /etc/mirrorbrain.conf

# let's patch mb to make sure it can be used without GeoIP DB

RUN sed -i '/^import errno/a database=\"\"' /usr/lib64/python2.7/site-packages/mb/geoip.py
ADD mb.diff /
RUN patch /mb.diff

ENTRYPOINT  ["/usr/lib/systemd/systemd"]
