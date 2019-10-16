
system_call.o:     file format elf32-i386


Disassembly of section .text:

00000000 <bad_sys_call>:
   0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
   5:	cf                   	iret   
   6:	66 90                	xchg   %ax,%ax

00000008 <reschedule>:
   8:	68 48 00 00 00       	push   $0x48
   d:	e9 fc ff ff ff       	jmp    e <reschedule+0x6>
  12:	66 90                	xchg   %ax,%ax

00000014 <system_call>:
  14:	83 f8 47             	cmp    $0x47,%eax
  17:	77 e7                	ja     0 <bad_sys_call>
  19:	1e                   	push   %ds
  1a:	06                   	push   %es
  1b:	0f a0                	push   %fs
  1d:	52                   	push   %edx
  1e:	51                   	push   %ecx
  1f:	53                   	push   %ebx
  20:	ba 10 00 00 00       	mov    $0x10,%edx
  25:	8e da                	mov    %edx,%ds
  27:	8e c2                	mov    %edx,%es
  29:	ba 17 00 00 00       	mov    $0x17,%edx
  2e:	8e e2                	mov    %edx,%fs
  30:	ff 14 85 00 00 00 00 	call   *0x0(,%eax,4)
  37:	50                   	push   %eax
  38:	e8 fc ff ff ff       	call   39 <system_call+0x25>
  3d:	83 38 00             	cmpl   $0x0,(%eax)
  40:	75 c6                	jne    8 <reschedule>
  42:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
  46:	74 c0                	je     8 <reschedule>

00000048 <ret_from_sys_call>:
  48:	e8 fc ff ff ff       	call   49 <ret_from_sys_call+0x1>
  4d:	3b 05 00 00 00 00    	cmp    0x0,%eax
  53:	74 30                	je     85 <ret_from_sys_call+0x3d>
  55:	66 83 7c 24 20 0f    	cmpw   $0xf,0x20(%esp)
  5b:	75 28                	jne    85 <ret_from_sys_call+0x3d>
  5d:	66 83 7c 24 2c 17    	cmpw   $0x17,0x2c(%esp)
  63:	75 20                	jne    85 <ret_from_sys_call+0x3d>
  65:	8b 58 0c             	mov    0xc(%eax),%ebx
  68:	8b 88 10 02 00 00    	mov    0x210(%eax),%ecx
  6e:	f7 d1                	not    %ecx
  70:	21 d9                	and    %ebx,%ecx
  72:	0f bc c9             	bsf    %ecx,%ecx
  75:	74 0e                	je     85 <ret_from_sys_call+0x3d>
  77:	0f b3 cb             	btr    %ecx,%ebx
  7a:	89 58 0c             	mov    %ebx,0xc(%eax)
  7d:	41                   	inc    %ecx
  7e:	51                   	push   %ecx
  7f:	e8 fc ff ff ff       	call   80 <ret_from_sys_call+0x38>
  84:	58                   	pop    %eax
  85:	58                   	pop    %eax
  86:	5b                   	pop    %ebx
  87:	59                   	pop    %ecx
  88:	5a                   	pop    %edx
  89:	0f a1                	pop    %fs
  8b:	07                   	pop    %es
  8c:	1f                   	pop    %ds
  8d:	cf                   	iret   
  8e:	66 90                	xchg   %ax,%ax

00000090 <coprocessor_error>:
  90:	1e                   	push   %ds
  91:	06                   	push   %es
  92:	0f a0                	push   %fs
  94:	52                   	push   %edx
  95:	51                   	push   %ecx
  96:	53                   	push   %ebx
  97:	50                   	push   %eax
  98:	b8 10 00 00 00       	mov    $0x10,%eax
  9d:	8e d8                	mov    %eax,%ds
  9f:	8e c0                	mov    %eax,%es
  a1:	b8 17 00 00 00       	mov    $0x17,%eax
  a6:	8e e0                	mov    %eax,%fs
  a8:	68 48 00 00 00       	push   $0x48
  ad:	e9 fc ff ff ff       	jmp    ae <coprocessor_error+0x1e>
  b2:	66 90                	xchg   %ax,%ax

000000b4 <device_not_available>:
  b4:	1e                   	push   %ds
  b5:	06                   	push   %es
  b6:	0f a0                	push   %fs
  b8:	52                   	push   %edx
  b9:	51                   	push   %ecx
  ba:	53                   	push   %ebx
  bb:	50                   	push   %eax
  bc:	b8 10 00 00 00       	mov    $0x10,%eax
  c1:	8e d8                	mov    %eax,%ds
  c3:	8e c0                	mov    %eax,%es
  c5:	b8 17 00 00 00       	mov    $0x17,%eax
  ca:	8e e0                	mov    %eax,%fs
  cc:	68 48 00 00 00       	push   $0x48
  d1:	0f 06                	clts   
  d3:	0f 20 c0             	mov    %cr0,%eax
  d6:	a9 04 00 00 00       	test   $0x4,%eax
  db:	0f 84 fc ff ff ff    	je     dd <device_not_available+0x29>
  e1:	55                   	push   %ebp
  e2:	56                   	push   %esi
  e3:	57                   	push   %edi
  e4:	e8 fc ff ff ff       	call   e5 <device_not_available+0x31>
  e9:	5f                   	pop    %edi
  ea:	5e                   	pop    %esi
  eb:	5d                   	pop    %ebp
  ec:	c3                   	ret    
  ed:	8d 76 00             	lea    0x0(%esi),%esi

000000f0 <timer_interrupt>:
  f0:	1e                   	push   %ds
  f1:	06                   	push   %es
  f2:	0f a0                	push   %fs
  f4:	52                   	push   %edx
  f5:	51                   	push   %ecx
  f6:	53                   	push   %ebx
  f7:	50                   	push   %eax
  f8:	ba 10 00 00 00       	mov    $0x10,%edx
  fd:	8e da                	mov    %edx,%ds
  ff:	8e c2                	mov    %edx,%es
 101:	e8 fc ff ff ff       	call   102 <timer_interrupt+0x12>
 106:	83 f8 00             	cmp    $0x0,%eax
 109:	75 07                	jne    112 <timer_interrupt+0x22>
 10b:	ba 17 00 00 00       	mov    $0x17,%edx
 110:	eb 05                	jmp    117 <timer_interrupt+0x27>
 112:	ba 10 00 00 00       	mov    $0x10,%edx
 117:	8e e2                	mov    %edx,%fs
 119:	ff 05 00 00 00 00    	incl   0x0
 11f:	e8 fc ff ff ff       	call   120 <timer_interrupt+0x30>
 124:	8b 44 24 20          	mov    0x20(%esp),%eax
 128:	83 e0 03             	and    $0x3,%eax
 12b:	50                   	push   %eax
 12c:	e8 fc ff ff ff       	call   12d <timer_interrupt+0x3d>
 131:	83 c4 04             	add    $0x4,%esp
 134:	e9 0f ff ff ff       	jmp    48 <ret_from_sys_call>
 139:	8d 76 00             	lea    0x0(%esi),%esi

0000013c <sys_execve>:
 13c:	8d 44 24 1c          	lea    0x1c(%esp),%eax
 140:	50                   	push   %eax
 141:	e8 fc ff ff ff       	call   142 <sys_execve+0x6>
 146:	83 c4 04             	add    $0x4,%esp
 149:	c3                   	ret    
 14a:	66 90                	xchg   %ax,%ax

0000014c <sys_fork>:
 14c:	e8 fc ff ff ff       	call   14d <sys_fork+0x1>
 151:	85 c0                	test   %eax,%eax
 153:	78 0e                	js     163 <sys_fork+0x17>
 155:	0f a8                	push   %gs
 157:	56                   	push   %esi
 158:	57                   	push   %edi
 159:	55                   	push   %ebp
 15a:	50                   	push   %eax
 15b:	e8 fc ff ff ff       	call   15c <sys_fork+0x10>
 160:	83 c4 14             	add    $0x14,%esp
 163:	c3                   	ret    

00000164 <hd_interrupt>:
 164:	50                   	push   %eax
 165:	51                   	push   %ecx
 166:	52                   	push   %edx
 167:	1e                   	push   %ds
 168:	06                   	push   %es
 169:	0f a0                	push   %fs
 16b:	b8 10 00 00 00       	mov    $0x10,%eax
 170:	8e d8                	mov    %eax,%ds
 172:	8e c0                	mov    %eax,%es
 174:	b8 17 00 00 00       	mov    $0x17,%eax
 179:	8e e0                	mov    %eax,%fs
 17b:	b0 20                	mov    $0x20,%al
 17d:	e6 a0                	out    %al,$0xa0
 17f:	eb 00                	jmp    181 <hd_interrupt+0x1d>
 181:	eb 00                	jmp    183 <hd_interrupt+0x1f>
 183:	31 d2                	xor    %edx,%edx
 185:	87 15 00 00 00 00    	xchg   %edx,0x0
 18b:	85 d2                	test   %edx,%edx
 18d:	75 05                	jne    194 <hd_interrupt+0x30>
 18f:	ba 00 00 00 00       	mov    $0x0,%edx
 194:	e6 20                	out    %al,$0x20
 196:	ff d2                	call   *%edx
 198:	0f a1                	pop    %fs
 19a:	07                   	pop    %es
 19b:	1f                   	pop    %ds
 19c:	5a                   	pop    %edx
 19d:	59                   	pop    %ecx
 19e:	58                   	pop    %eax
 19f:	cf                   	iret   

000001a0 <floppy_interrupt>:
 1a0:	50                   	push   %eax
 1a1:	51                   	push   %ecx
 1a2:	52                   	push   %edx
 1a3:	1e                   	push   %ds
 1a4:	06                   	push   %es
 1a5:	0f a0                	push   %fs
 1a7:	b8 10 00 00 00       	mov    $0x10,%eax
 1ac:	8e d8                	mov    %eax,%ds
 1ae:	8e c0                	mov    %eax,%es
 1b0:	b8 17 00 00 00       	mov    $0x17,%eax
 1b5:	8e e0                	mov    %eax,%fs
 1b7:	b0 20                	mov    $0x20,%al
 1b9:	e6 20                	out    %al,$0x20
 1bb:	31 c0                	xor    %eax,%eax
 1bd:	87 05 00 00 00 00    	xchg   %eax,0x0
 1c3:	85 c0                	test   %eax,%eax
 1c5:	75 05                	jne    1cc <floppy_interrupt+0x2c>
 1c7:	b8 00 00 00 00       	mov    $0x0,%eax
 1cc:	ff d0                	call   *%eax
 1ce:	0f a1                	pop    %fs
 1d0:	07                   	pop    %es
 1d1:	1f                   	pop    %ds
 1d2:	5a                   	pop    %edx
 1d3:	59                   	pop    %ecx
 1d4:	58                   	pop    %eax
 1d5:	cf                   	iret   

000001d6 <parallel_interrupt>:
 1d6:	50                   	push   %eax
 1d7:	b0 20                	mov    $0x20,%al
 1d9:	e6 20                	out    %al,$0x20
 1db:	58                   	pop    %eax
 1dc:	cf                   	iret   

000001dd <parse_cpu_topology>:
 1dd:	50                   	push   %eax
 1de:	53                   	push   %ebx
 1df:	51                   	push   %ecx
 1e0:	52                   	push   %edx
 1e1:	b8 01 00 00 00       	mov    $0x1,%eax
 1e6:	0f a2                	cpuid  
 1e8:	5a                   	pop    %edx
 1e9:	59                   	pop    %ecx
 1ea:	5b                   	pop    %ebx
 1eb:	58                   	pop    %eax
 1ec:	cf                   	iret   

000001ed <handle_ipi_interrupt>:
 1ed:	50                   	push   %eax
 1ee:	53                   	push   %ebx
 1ef:	51                   	push   %ecx
 1f0:	52                   	push   %edx
 1f1:	e8 fc ff ff ff       	call   1f2 <handle_ipi_interrupt+0x5>
 1f6:	e8 fc ff ff ff       	call   1f7 <handle_ipi_interrupt+0xa>
 1fb:	5a                   	pop    %edx
 1fc:	59                   	pop    %ecx
 1fd:	5b                   	pop    %ebx
 1fe:	58                   	pop    %eax
 1ff:	cf                   	iret   
