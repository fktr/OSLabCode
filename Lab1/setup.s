!setup.s
!被bootsect.s加载到内存0x90200处，首先显示一个字符串，然后打印光标位置、内存尺寸以及磁盘参数信息

.globl begtext,begdata,begbss,endtext,enddata,endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

BOOTSEG=0x07c0
INITSEG=0x9000
SETUPSEG=0x9020

entry start
start:
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#23
    mov bx,#0x0007
    mov bp,#msg1
    mov ax,#0x1301
    int 0x10

    mov ax,#INITSEG
    mov ds,ax!设置硬件信息保存的段地址为INITSEG
    mov ah,0x03
    xor bh,bh
    int 0x10!读取光标位置
    mov [0],dx!保存到ds:0x0处

    !取扩展内存的大小值
    !调用0x15号中断,ah功能号为0x88取系统所含扩展内存大小
    mov ah,#0x88
    int 0x15
    mov [2],ax!保存到ds:0x2处

    !取第一个硬盘的信息
    !第一个硬盘参数表的首地址是中断向量0x41的向量值，第二个硬盘参数表紧接其后,为0x46。
    !表长为16个字节
    !ds:si=>es:di
    mov ax,#0x0000
    mov ds,ax
    lds si,[4*0x41]!取中断向量0x41的值,即hd0参数表的地址->ds:si
    mov ax,#INITSEG
    mov es,ax
    mov di,#0x0080
    mov cx,#0x10
    rep
    movsb

    mov ax,#INITSEG
    mov ds,ax
    mov ax,#SETUPSEG
    mov es,ax

    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#11
    mov bx,#0x0007
    mov bp,#cur
    mov ax,#0x1301
    int 0x10!打印提示字符串

    mov ax,[0x0]!取出光标位置
    call print_hex!打印数值
    call print_nl!打印回车换行

    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#12
    mov bx,#0x0007
    mov bp,#mem
    mov ax,#0x1301
    int 0x10

    mov ax,[0x2]
    call print_hex!打印内存大小

    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#25
    mov bx,#0x0007
    mov bp,#cyl
    mov ax,#0x1301
    int 0x10

    mov ax,[0x80]
    call print_hex!打印柱面个数
    call print_nl

    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#8
    mov bx,#0x0007
    mov bp,#head
    mov ax,#0x1301
    int 0x10

    mov ax,[0x80+0x02]
    call print_hex!打印磁头个数
    call print_nl

    mov ah,#0x03
    xor bh,bh
    int 0x10
    mov cx,#8
    mov bx,#0x0007
    mov bp,#sect
    mov ax,#0x1301
    int 0x10

    mov ax,[0x80+0x0e]
    call print_hex!打印每磁道扇区数
    call print_nl

ok: j ok !停止

!将ax中16位数字打印成按十六进制显示字符输出
print_hex:
    mov cx,#4!打印4个字符
    mov dx,ax!参数ax传递给dx
print_digit:
    rol dx,#4!循环左移4位,最高位变为最低位
    mov ah,#0xe!中断功能号,显示al中的字符
    mov al,dl
    and al,#0xf!高4位置零,设置al为显示数字
    add al,#0x30!转换ascii码
    cmp al,#0x39
    jbe good_digit!不超过9直接中断打印出来
    add al,#0x41-0x30-0xa!超过9加上'A'-'0'-10设置为大写字母显示
good_digit:
    int 0x10!调用中断0x10
    loop print_digit!循环打印4个字符
    ret 

!中断打印回车换行
print_nl:
    mov ax,#0xe0d
    int 0x10
    mov al,#0xa
    int 0x10
    ret

msg1:
    .ascii "Now we are in SETUP"
    .byte 13,10,13,10
cur:
    .ascii "Cursor POS:"
mem:
    .ascii "Memory SIZE:"
cyl:
    .ascii "KB"
    .byte 13,10,13,10
    .ascii "HD Info"
    .byte 13,10
    .ascii "Cylinders:"
head:
    .ascii "Headers:"
sect:
    .ascii "Sectors:"

.text
endtext:
.data
enddata:
.bss
endbss: 
