from sqlobject import *
from sqlobject.sqlbuilder import *
from enum import IntEnum
from datetime import datetime

import mb.conn

class ScanScheme(IntEnum):
    Http = 0,
    Ftp = 1,
    Rsync = 2

def isSsl(mirror, scheme):
    if int(scheme) == int(ScanScheme.Http):
        return mirror.baseurl.startswith('https://')
    if int(scheme) == int(ScanScheme.Ftp):
        return mirror.baseurl.startswith('ftps://')
    return None

def parseUrlScheme(url):
    if url.startswith('http'):
        return ScanScheme.Http
    if url.startswith('ftp'):
        return ScanScheme.Ftp
    if url.startswith('rsync'):
        return ScanScheme.Rsync

def start_mirror_scan(conn, mirror, need_lock, client_ident, is_probe, scheme):
    is_ssl  = isSsl(mirror, scheme)
    is_ipv6 = False # not sure if we detect it here or pass as argument
    lock = None
    if need_lock:
        try:
            lock = conn.ScanLock(id=mirror.id, lockedByName=client_ident, lockedByHost='test')
        except dberrors.DuplicateEntryError:
            logging.debug('%s: baseurl %s: cannot start scan' % (mirror.identifier, repr(mirror.baseurl)))
            return None

    st = conn.ScanType.select(AND(conn.ScanType.q.id==mirror.id, conn.ScanType.q.isProbe==is_probe, conn.ScanType.q.isSsl==is_ssl, conn.ScanType.q.isIpv6==is_ipv6, conn.ScanType.q.scheme==int(scheme))).getOne(None)
    if st == None:
        st = conn.ScanType(id=mirror.id, isProbe=is_probe, isSsl=is_ssl, isIpv6=is_ipv6, scheme=int(scheme))

    s = conn.Scan(scanTypeID=st.id, startedAt = datetime.now(), scannedBy=client_ident)
    s.lock = lock
    return s

def finish_mirror_scan(conn, scan, success):
    if scan.lock is not None:
        scan.lock.destroySelf()

    rev = 0
    last_scan = conn.Scan.select(AND(conn.Scan.q.id != scan.id, conn.Scan.q.scanTypeID == scan.scanTypeID)).orderBy('-finished_at').limit(1).getOne(None)
    if last_scan is not None:
        if last_scan.success == scan.success:
            rev = last_scan.revision
        else:
            rev = last_scan.revision + 1

    scan.set(revision = rev, success = success,  finishedAt = datetime.now())
