!bootsect.s 
!当 PC 的电源打开后,80x86 结构的 CPU 将自动进入实模式,并从地址 0xFFFF0 开始自动执行程序代码,这
!个地址通常是 ROM-BIOS 中的地址。PC 机的 BIOS 将执行某些系统的检测,在物理地址 0 处开始初始化中
!断向量。此后,它将可启动设备的第一个扇区读入内存地址 0x7C00 处,并跳转到这个地方。此代码即为引导扇
!区的代码，它将完成自身的复制迁移，加载setup.s设置程序,最后在终端显示启动字符串,并跳到setup程序执
!行。

.globl begtext,begdata,begbss,endtext,enddata,endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

SETUPLEN=4
BOOTSEG=0x07c0
INITSEG=0x9000
SETUPSEG=0x9020

entry start
start:
!将自身从内存0x7c00处复制到0x90000处
!ds:si=>es:di 执行cx次movw
    mov ax,#BOOTSEG
    mov ds,ax
    mov ax,#INITSEG
    mov es,ax
    sub si,si
    sub di,di
    mov cx,#256
    rep 
    movw
    jmpi go,INITSEG !段间跳转,设置cs为INITSEG

go:
    mov ax,cs
    mov ds,ax!cs=>ds
    mov es,ax!cs=>es

!从磁盘加载setup程序到内存0x90200处
!调用0x13号中断
!输入：ah为功能号,0x02为从磁盘读到内存,al为读取扇区个数
!dh为磁头号,dl为驱动器号,ch为柱面（磁道）号,cl为开始扇区，es:bx指向数据缓冲区
!如果出错,CF标志置位,ah返回出错码
load_setup:
    xor dx,dx
    mov cx,#0x0002
    mov ax,#0x0200+SETUPLEN
    mov bx,#0x0200
    int #0x13
    jnc ok_load_setup
    !复位磁盘控制器,重试
    !调用0x13号中断
    !ah为功能号,0x0为复位,dl为驱动器号
    xor dl,dl
    xor ah,ah
    int #0x13
    j load_setup

!显示字符串
!调用0x10号中断
!输入:ah功能号为0x13表示显示字符串,al为0x01表示光标停在字符串结尾处
!es:bp指向显示字符串的起始位置,cx为字符串长度,dh为显示位置行号,dl为列号,bh为显示页号,bl为字符属性
ok_load_setup:

!读取光标位置
!调用0x10号中断
!ah功能号为0x03,bh为页号
!输出dh为光标位置行号,dl为列号
    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#25
    mov bx,#0x000A
    mov bp,#msg1
    mov ax,#0x1301
    int 0x10

    jmpi 0,SETUPSEG!跳转到setup程序段执行

msg1:
    .byte 13,10
    .ascii "Funix is booting..."
    .byte 13,10,13,10!ASCII码：13为回车,10为换行

.org    510 !定位当前偏移地址为510
    .word 0xAA55!有效引导扇区的标志

.text
endtext:
.data
enddata:
.bss
endbss:
