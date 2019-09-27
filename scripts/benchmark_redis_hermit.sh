
LOG=benchmark_logs/hermittux-redis.log

for i in `seq 1 30`
do
	ID=`sudo docker run -d -v ~/hermitux:/hermitux --rm --privileged --net=host -it \
		olivierpierre/hermitux bash -c "cd /hermitux/apps/redis-2.0.4 && bash hermitux.sh"`

	sleep 3

	redis-benchmark -h 192.168.100.2 -p 8000 -t get,set -c 30 >> $LOG
	sudo docker rm -f $ID
done
