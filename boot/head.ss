
head.o:     file format elf32-i386


Disassembly of section .text:

00000000 <startup_32>:
       0:	b8 10 00 00 00       	mov    $0x10,%eax
       5:	8e d8                	mov    %eax,%ds
       7:	8e c0                	mov    %eax,%es
       9:	8e e0                	mov    %eax,%fs
       b:	8e e8                	mov    %eax,%gs
       d:	8e d0                	mov    %eax,%ss
       f:	31 d2                	xor    %edx,%edx
      11:	66 8b 15 02 00 09 00 	mov    0x90002,%dx
      18:	31 c0                	xor    %eax,%eax
      1a:	b8 01 00 00 00       	mov    $0x1,%eax
      1f:	83 f8 00             	cmp    $0x0,%eax
      22:	74 03                	je     27 <bochs_emulator>
      24:	83 c2 03             	add    $0x3,%edx

00000027 <bochs_emulator>:
      27:	c1 e2 04             	shl    $0x4,%edx
      2a:	81 c2 00 10 00 00    	add    $0x1000,%edx
      30:	89 15 00 00 00 00    	mov    %edx,0x0
      36:	0f b2 25 00 00 00 00 	lss    0x0,%esp
      3d:	81 fa 00 00 04 00    	cmp    $0x40000,%edx
      43:	7e 05                	jle    4a <bochs_emulator+0x23>
      45:	ba 00 00 04 00       	mov    $0x40000,%edx
      4a:	8d 1d 00 00 00 00    	lea    0x0,%ebx
      50:	83 c3 08             	add    $0x8,%ebx
      53:	52                   	push   %edx
      54:	53                   	push   %ebx
      55:	e8 fc ff ff ff       	call   56 <bochs_emulator+0x2f>
      5a:	5b                   	pop    %ebx
      5b:	5a                   	pop    %edx
      5c:	8d 1d 00 00 00 00    	lea    0x0,%ebx
      62:	83 c3 10             	add    $0x10,%ebx
      65:	52                   	push   %edx
      66:	53                   	push   %ebx
      67:	e8 fc ff ff ff       	call   68 <bochs_emulator+0x41>
      6c:	5b                   	pop    %ebx
      6d:	5a                   	pop    %edx
      6e:	c1 e2 0c             	shl    $0xc,%edx
      71:	83 ea 04             	sub    $0x4,%edx

00000074 <init_temp_stack>:
      74:	89 15 18 01 00 00    	mov    %edx,0x118
      7a:	0f b2 25 18 01 00 00 	lss    0x118,%esp
      81:	e8 53 00 00 00       	call   d9 <setup_gdt>
      86:	e8 1e 00 00 00       	call   a9 <setup_idt>
      8b:	b8 10 00 00 00       	mov    $0x10,%eax
      90:	8e d8                	mov    %eax,%ds
      92:	8e c0                	mov    %eax,%es
      94:	8e e0                	mov    %eax,%fs
      96:	8e e8                	mov    %eax,%gs
      98:	e8 fc ff ff ff       	call   99 <init_temp_stack+0x25>
      9d:	0f b2 25 00 00 00 00 	lss    0x0,%esp
      a4:	e9 57 13 00 00       	jmp    1400 <main_entry>

000000a9 <setup_idt>:
      a9:	8d 15 28 14 00 00    	lea    0x1428,%edx
      af:	b8 00 00 08 00       	mov    $0x80000,%eax
      b4:	66 89 d0             	mov    %dx,%ax
      b7:	66 ba 00 8e          	mov    $0x8e00,%dx
      bb:	8d 3d 00 00 00 00    	lea    0x0,%edi
      c1:	b9 00 01 00 00       	mov    $0x100,%ecx

000000c6 <rp_sidt>:
      c6:	89 07                	mov    %eax,(%edi)
      c8:	89 57 04             	mov    %edx,0x4(%edi)
      cb:	83 c7 08             	add    $0x8,%edi
      ce:	49                   	dec    %ecx
      cf:	75 f5                	jne    c6 <rp_sidt>
      d1:	0f 01 1d 50 14 00 00 	lidtl  0x1450
      d8:	c3                   	ret    

000000d9 <setup_gdt>:
      d9:	0f 01 15 58 14 00 00 	lgdtl  0x1458
      e0:	c3                   	ret    

000000e1 <hd_read_interrupt>:
      e1:	eb 00                	jmp    e3 <hd_read_interrupt+0x2>
      e3:	50                   	push   %eax
      e4:	51                   	push   %ecx
      e5:	52                   	push   %edx
      e6:	1e                   	push   %ds
      e7:	06                   	push   %es
      e8:	0f a0                	push   %fs
      ea:	b8 10 00 00 00       	mov    $0x10,%eax
      ef:	8e d8                	mov    %eax,%ds
      f1:	8e c0                	mov    %eax,%es
      f3:	8e e0                	mov    %eax,%fs
      f5:	b0 20                	mov    $0x20,%al
      f7:	e6 a0                	out    %al,$0xa0
      f9:	eb 00                	jmp    fb <hd_read_interrupt+0x1a>
      fb:	eb 00                	jmp    fd <hd_read_interrupt+0x1c>
      fd:	e6 20                	out    %al,$0x20
      ff:	8b 15 00 00 00 00    	mov    0x0,%edx
     105:	83 fa 20             	cmp    $0x20,%edx
     108:	75 05                	jne    10f <omt>
     10a:	e8 fc ff ff ff       	call   10b <hd_read_interrupt+0x2a>

0000010f <omt>:
     10f:	0f a1                	pop    %fs
     111:	07                   	pop    %es
     112:	1f                   	pop    %ds
     113:	5a                   	pop    %edx
     114:	59                   	pop    %ecx
     115:	58                   	pop    %eax
     116:	cf                   	iret   
     117:	90                   	nop

00000118 <temp_stack>:
     118:	00 00                	add    %al,(%eax)
     11a:	00 00                	add    %al,(%eax)
     11c:	10 00                	adc    %al,(%eax)
	...

00000120 <hd_intr_cmd>:
	...

00001000 <tmp_floppy_area>:
    1000:	00 14 00             	add    %dl,(%eax,%eax,1)
    1003:	00 10                	add    %dl,(%eax)
	...

00001400 <main_entry>:
    1400:	6a 00                	push   $0x0
    1402:	6a 00                	push   $0x0
    1404:	6a 00                	push   $0x0
    1406:	68 10 14 00 00       	push   $0x1410
    140b:	e8 fc ff ff ff       	call   140c <main_entry+0xc>

00001410 <L6>:
    1410:	eb fe                	jmp    1410 <L6>

00001412 <int_msg>:
    1412:	55                   	push   %ebp
    1413:	6e                   	outsb  %ds:(%esi),(%dx)
    1414:	6b 6e 6f 77          	imul   $0x77,0x6f(%esi),%ebp
    1418:	6e                   	outsb  %ds:(%esi),(%dx)
    1419:	20 69 6e             	and    %ch,0x6e(%ecx)
    141c:	74 65                	je     1483 <gdt_descr+0x2b>
    141e:	72 72                	jb     1492 <gdt_descr+0x3a>
    1420:	75 70                	jne    1492 <gdt_descr+0x3a>
    1422:	74 0a                	je     142e <ignore_int+0x6>
    1424:	0d                   	.byte 0xd
    1425:	00 66 90             	add    %ah,-0x70(%esi)

00001428 <ignore_int>:
    1428:	50                   	push   %eax
    1429:	51                   	push   %ecx
    142a:	52                   	push   %edx
    142b:	1e                   	push   %ds
    142c:	06                   	push   %es
    142d:	0f a0                	push   %fs
    142f:	b8 10 00 00 00       	mov    $0x10,%eax
    1434:	8e d8                	mov    %eax,%ds
    1436:	8e c0                	mov    %eax,%es
    1438:	8e e0                	mov    %eax,%fs
    143a:	68 12 14 00 00       	push   $0x1412
    143f:	e8 fc ff ff ff       	call   1440 <ignore_int+0x18>
    1444:	58                   	pop    %eax
    1445:	0f a1                	pop    %fs
    1447:	07                   	pop    %es
    1448:	1f                   	pop    %ds
    1449:	5a                   	pop    %edx
    144a:	59                   	pop    %ecx
    144b:	58                   	pop    %eax
    144c:	cf                   	iret   
    144d:	8d 76 00             	lea    0x0(%esi),%esi

00001450 <idt_descr>:
    1450:	ff 07                	incl   (%edi)
    1452:	00 00                	add    %al,(%eax)
    1454:	00 00                	add    %al,(%eax)
	...

00001458 <gdt_descr>:
    1458:	00 08                	add    %cl,(%eax)
	...

00002000 <idt>:
	...

00003000 <gdt>:
	...
    3008:	ff 0f                	decl   (%edi)
    300a:	00 00                	add    %al,(%eax)
    300c:	00 9a c0 00 ff 0f    	add    %bl,0xfff00c0(%edx)
    3012:	00 00                	add    %al,(%eax)
    3014:	00 92 c0 00 00 00    	add    %dl,0xc0(%edx)
	...

00004000 <tr_tss>:
	...

00005000 <ldt>:
	...

00005800 <params_table_addr>:
    5800:	00 00                	add    %al,(%eax)
	...

00005804 <total_memory_size>:
    5804:	00 00                	add    %al,(%eax)
	...
