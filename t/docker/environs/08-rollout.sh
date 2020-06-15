#!../lib/test-in-container-environs.sh
set -ex

[ -d mirrorbrain ]

./environ.sh pg9-system2
./environ.sh ap9-system2
./environ.sh ap8-system2
./environ.sh ap7-system2
./environ.sh mb9 $(pwd)/mirrorbrain

pg9*/start.sh

mb9*/configure_db.sh pg9
mb9*/configure_apache.sh ap9

ap9=$(ls -d ap9*)

# populate test data
for x in ap7 ap8 ap9; do
    xx=$(ls -d $x*/)
    mkdir -p $xx/dt/downloads/{folder1,folder2,folder3}
    echo $xx/dt/downloads/{folder1,folder2,folder3}/{file1,file2}.dat | xargs -n 1 touch
done

mkdir -p ap9-system2/hashes
rollout1=$(mb9*/mb.sh makehashes --rollout -t $(pwd)/ap9-system2/hashes -b $(pwd)/ap9*/dt $(pwd)/ap9*/dt/downloads/folder1 | tee /dev/tty | tail -n 1) 

rollout2=$(mb9*/mb.sh makehashes --rollout -t $(pwd)/ap9-system2/hashes -b $(pwd)/ap9*/dt $(pwd)/ap9*/dt/downloads/folder2 | tee /dev/tty | tail -n 1) 

rollout3=$(mb9*/mb.sh makehashes --rollout -t $(pwd)/ap9-system2/hashes -b $(pwd)/ap9*/dt $(pwd)/ap9*/dt/downloads/folder3 | tee /dev/tty | tail -n 1) 


for x in ap7 ap8 ap9; do
    xx=$(ls -d $x*/)
    echo $xx/dt/downloads/{folder1,folder2,folder3}/{file11,file21}.dat | xargs -n 1 touch
done

rollout11=$(mb9*/mb.sh makehashes --rollout -t $(pwd)/ap9-system2/hashes -b $(pwd)/ap9*/dt $(pwd)/ap9*/dt/downloads/folder1 | tee /dev/tty | tail -n 1) 

rollout21=$(mb9*/mb.sh makehashes --rollout -t $(pwd)/ap9-system2/hashes -b $(pwd)/ap9*/dt $(pwd)/ap9*/dt/downloads/folder2 | tee /dev/tty | tail -n 1) 

rollout31=$(mb9*/mb.sh makehashes --rollout -t $(pwd)/ap9-system2/hashes -b $(pwd)/ap9*/dt $(pwd)/ap9*/dt/downloads/folder3 | tee /dev/tty | tail -n 1) 

ap9*/start.sh
ap9*/status.sh
ap9*/curl.sh downloads/ | grep folder1

for x in ap7 ap8; do
    $x*/start.sh
    $x*/status.sh
    mb9*/mb.sh new $x --http http://"$($x-system2/print_address.sh)" --region NA --country us
    mb9*/mb.sh scan --enable $x
    $x-system2/curl.sh | grep downloads
done

pg9*/sql.sh mirrorbrain 'select sr.server_id, f.id, f.path from server_rollout sr join rollout_filearr rf on rf.rollout_id = sr.rollout_id join filearr f on f.id = rf.filearr_id order by sr.server_id, f.id'

ap9*/curl.sh /downloads/folder1/file1.dat

tail ap9*/dt/error_log | grep 'Chose server '
