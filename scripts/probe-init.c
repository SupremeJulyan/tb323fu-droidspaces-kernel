/* SPDX-License-Identifier: MIT
 * Minimal ARM64 init for QEMU kernel capability tests; no Android data access.
 */
typedef unsigned long ulong;
static long sc(long nr, long a, long b, long c, long d, long e, long f) {
    register long x0 __asm__("x0")=a, x1 __asm__("x1")=b;
    register long x2 __asm__("x2")=c, x3 __asm__("x3")=d;
    register long x4 __asm__("x4")=e, x5 __asm__("x5")=f;
    register long x8 __asm__("x8")=nr;
    __asm__ volatile("svc 0" : "+r"(x0) : "r"(x1),"r"(x2),"r"(x3),"r"(x4),"r"(x5),"r"(x8) : "memory");
    return x0;
}
#define S(n,a,b,c,d,e,f) sc(n,(long)(a),(long)(b),(long)(c),(long)(d),(long)(e),(long)(f))
static int failures;
static void text(const char *s) { ulong n=0; while(s[n]) n++; S(64,1,s,n,0,0,0); }
static void check(const char *name, int ok) {
    text(ok ? "PASS " : "FAIL "); text(name); text("\n"); if(!ok) failures++;
}
static long mountfs(const char *type, const char *where) { return S(40,type,where,type,0,0,0); }
#ifdef WITH_LKM
static void load(const char *path, const char *params) {
    long fd=S(56,-100,path,0,0,0,0);
    long rc=fd>=0?S(273,fd,params,0,0,0,0):fd;
    check(path,rc==0);
    if(fd>=0) S(57,fd,0,0,0,0,0);
}
#endif
void _start(void) {
    long console=S(56,-100,"/dev/ttyAMA0",2,0,0,0);
    if(console>=0) { if(console!=1) S(24,console,1,0,0,0,0); if(console!=2) S(24,console,2,0,0,0,0); }
    text("TB323FU_QEMU_PROBE_BEGIN\n");
    check("procfs", mountfs("proc","/proc")==0);
    check("sysfs", mountfs("sysfs","/sys")==0);
#ifdef WITH_LKM
    load("/lkm4ctr.ko","");
    load("/devtmpfs_lkm.ko","devtmpfs_probe=2");
#endif
    check("devtmpfs", mountfs("devtmpfs","/dev")==0);
    check("mount_namespace", S(97,0x20000,0,0,0,0,0)==0);
    check("uts_namespace", S(97,0x4000000,0,0,0,0,0)==0);
    check("ipc_namespace", S(97,0x8000000,0,0,0,0,0)==0);
    check("network_namespace", S(97,0x40000000,0,0,0,0,0)==0);
    long id=S(194,0,4096,0600,0,0,0);
    check("sysv_shm_create",id>=0);
    if(id>=0) {
        long addr=S(196,id,0,0,0,0,0);
        check("sysv_shm_attach",addr>0);
        if(addr>0) { *(volatile long*)addr=1234; check("sysv_shm_rw",*(volatile long*)addr==1234); S(197,addr,0,0,0,0,0); }
        S(195,id,0,0,0,0,0);
    }
    long sem=S(190,0,1,0600,0,0,0);
    check("sysv_semaphore",sem>=0);
    if(sem>=0) S(191,sem,0,0,0,0,0);
    struct { long flags,maxmsg,msgsize,curmsgs; } attr={0,1,16,0};
    long mq=S(180,"probe",66,0600,&attr,0,0);
    check("posix_mqueue_create",mq>=0);
    if(mq>=0) {
        char buf[32]={0};
        long sent=S(182,mq,"hello",5,0,0,0);
        check("posix_mqueue_send",sent==0);
        long received=sent==0?S(183,mq,buf,32,0,0,0):-1;
        check("posix_mqueue_receive",received==5 && buf[0]=='h' && buf[4]=='o');
        S(57,mq,0,0,0,0,0); S(181,"probe",0,0,0,0,0);
    }
    check("cgroup2_mount",mountfs("cgroup2","/cgroup")==0);
    long child=S(220,17,0,0,0,0,0);
    if(child==0) {
        if(S(97,0x20000000,0,0,0,0,0)!=0) S(93,2,0,0,0,0,0);
        long nested=S(220,17,0,0,0,0,0);
        if(nested==0) S(93,S(172,0,0,0,0,0,0)==1?0:3,0,0,0,0,0);
        int status=0;
        if(nested<0 || S(260,nested,&status,0,0,0,0)<0) S(93,4,0,0,0,0,0);
        S(93,status==0?0:5,0,0,0,0,0);
    }
    int status=0;
    long waited=child>0?S(260,child,&status,0,0,0,0):-1;
    check("pid_namespace_pid1",waited==child && child>0 && status==0);
    child=S(220,17,0,0,0,0,0);
    if(child==0) S(93,S(97,0x10000000,0,0,0,0,0)==0?0:1,0,0,0,0,0);
    status=0;
    waited=child>0?S(260,child,&status,0,0,0,0):-1;
    check("user_namespace",waited==child && child>0 && status==0);
    struct { unsigned short code; unsigned char jt,jf; unsigned int k; } filter={6,0,0,0x7fff0000};
    struct { unsigned short len; void *filter; } program={1,&filter};
    long nnp=S(167,38,1,0,0,0,0);
    check("seccomp_filter",nnp==0 && S(277,1,0,&program,0,0,0)==0);
    text(failures?"TB323FU_QEMU_PROBE_FAILED\n":"TB323FU_QEMU_PROBE_PASSED\n");
    S(142,0xfee1dead,672274793,0x4321fedc,0,0,0);
    for(;;) S(124,0,0,0,0,0,0);
}
