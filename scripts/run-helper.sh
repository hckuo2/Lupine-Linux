#!/bin/bash -e
die() { echo "$*" 1>&2 ; exit 1; }
TAP=${TAP:-100}

declare -A table
table[ltp]="1.0,/opt/ltp/runltp -f syscalls -s getpid"
table[redis]="5-alpine,/trusted/redis-server"
table[httpd]="2-alpine,/trusted/httpd -DFOREGROUND"
table[mongo]="4.0.10-xenial,/usr/local/bin/docker-entrypoint.sh mongod"

get_docker_tag() {
    ret=$(echo ${table[$1]} | cut -d',' -f1)
    [ -z $ret ] && die "empty docker tag"
    echo $ret
}


get_exec_args() {
    ret=$(echo ${table[$1]} | cut -d',' -f2)
    [ "x$ret" == "x" ] && die "empty exec args"
    echo $ret
}

create_tap() {
    if ! ip link show tap$1 &> /dev/null; then
        sudo ip tuntap add mode tap tap$1
        sudo ip addr add 192.168.$1.1/24 dev tap$1
        sudo ip link set tap$1 up
        echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null
        sudo iptables -t nat -A POSTROUTING -o bond1 -j MASQUERADE
        sudo iptables -I FORWARD 1 -i tap$1 -j ACCEPT
        sudo iptables -I FORWARD 1 -o tap$1 -m state --state RELATED,ESTABLISHED -j ACCEPT
    fi
}

delete_tap() {
    sudo ip link del tap$TAP
}

create_current_tap() {
    create_tap $TAP
}

delete_current_tap() {
    delete_tap $TAP
}

ltp_scs=(abort accept accept4 access acct add_key adjtimex alarm bind brk \
    cacheflush capget capset chdir chmod chown chroot clock_adjtime \
    clock_getres clock_gettime clock_nanosleep clock_nanosleep2 clock_settime \
    clone close cma confstr connect copy_file_range creat delete_module dup \
    dup2 dup3 epoll epoll2 epoll_create1 epoll_ctl epoll_pwait epoll_wait \
    eventfd eventfd2 execl execle execlp execv execve execveat execvp exit \
    exit_group faccessat fadvise fallocate fanotify fchdir fchmod fchmodat \
    fchown fchownat fcntl fdatasync fgetxattr flistxattr flock fmtmsg fork \
    fpathconf fremovexattr fsetxattr fstat fstatat fstatfs fsync ftruncate \
    futex futimesat get_mempolicy get_robust_list getcontext getcpu getcwd \
    getdents getdomainname getdtablesize getegid geteuid getgid getgroups \
    gethostbyname_r gethostid gethostname getitimer getpagesize getpeername \
    getpgid getpgrp getpid getppid getpriority getrandom getresgid getresuid \
    getrlimit getrusage getsid getsockname getsockopt gettid gettimeofday \
    getuid getxattr inotify inotify_init io_cancel io_destroy io_getevents \
    io_setup io_submit ioctl ioperm iopl  kcmp keyctl kill lchown lgetxattr \
    link linkat listen listxattr llistxattr llseek lremovexattr lseek lstat \
    madvise mallopt mbind membarrier memcmp memcpy memfd_create memmap memset \
    migrate_pages mincore mkdir mkdirat mknod mknodat mlock mlock2 mlockall \
    mmap modify_ldt mount move_pages mprotect mq_notify mq_open \
    mq_timedreceive mq_timedsend mq_unlink mremap msync munlock munlockall \
    munmap nanosleep newuname nftw nice open openat paging pathconf pause \
    perf_event_open personality pidfd_send_signal pipe pipe2 pivot_root poll \
    ppoll prctl pread preadv preadv2 profil pselect ptrace pwrite pwritev \
    pwritev2 quotactl read readahead readdir readlink readlinkat readv \
    realpath reboot recv recvfrom recvmsg remap_file_pages removexattr rename \
    renameat renameat2 request_key rmdir rt_sigaction rt_sigprocmask \
    rt_sigqueueinfo rt_sigsuspend rt_sigtimedwait rt_tgsigqueueinfo sbrk \
    sched_get_priority_max sched_get_priority_min sched_getaffinity \
    sched_getattr sched_getparam sched_getscheduler sched_rr_get_interval \
    sched_setaffinity sched_setattr sched_setparam sched_setscheduler \
    sched_yield select send sendfile sendmsg sendto set_mempolicy \
    set_robust_list set_thread_area set_tid_address setdomainname setegid \
    setfsgid setfsuid setgid setgroups sethostname setitimer setns setpgid \
    setpgrp setpriority setregid setresgid setresuid setreuid setrlimit setsid \
    setsockopt settimeofday setuid setxattr sgetmask sigaction sigaltstack \
    sighold signal signalfd signalfd4 sigpending sigprocmask sigrelse \
    sigsuspend sigtimedwait sigwait sigwaitinfo socket socketcall socketpair \
    sockioctl splice ssetmask stat statfs statvfs statx stime string swapoff \
    swapon switch symlink symlinkat sync sync_file_range syncfs syscall \
    sysconf sysctl sysfs sysinfo syslog tee tgkill time timer_getoverrun \
    timer_gettime timerfd times tkill truncate ulimit umask umount umount2 \
    uname unlink unlinkat unshare userfaultfd ustat utils utime utimensat \
    utimes vfork vhangup vmsplice  wait wait4 waitid waitpid write writev)

