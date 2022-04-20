.section .data
TOPO_INICIAL_HEAP:          .quad 0
ULTIMO_ENDERECO_ALOCADO:    .quad 0

.section .text

.globl iniciaAlocador
.globl finalizaAlocador
.globl liberaMem
.globl alocaMem
.globl imprimeMapa

# TABELA DE SIMBOLOS INICIA_ALOCADOR
# ######################### #
# ######################### #

iniciaAlocador:
    # configura rbp
    pushq %rbp
    movq %rsp, %rbp

    # %rax <- sbrk(0)
    movq $12, %rax
    movq $0, %rdi
    syscall

    # topoInicialHeap <- sbrk(0)
    movq %rax, TOPO_INICIAL_HEAP
    # ultimoEnderecoAlocadp <- sbrk(0)
    movq %rax, ULTIMO_ENDERECO_ALOCADO

    # saida do procedimento
    popq %rbp
    ret

# TABELA DE SIMBOLOS FINALIZA_ALOCADOR
# ######################### #
# ######################### #

finalizaAlocador:
    # configura rbp
    pushq %rbp
    movq %rsp, %rbp

    # brk(topoInicialHeap)
    movq $12, %rax
    movq TOPO_INICIAL_HEAP, %rdi
    syscall

    # saida do procedimento
    popq %rbp
    ret

# TABELA DE SIMBOLOS LIBERA_MEM
# ######################### #
# bloco         # -16(%rbp) #
# topoAtualHeap # -24(%rbp) #
# primBloco     # -32(%rbp) #
# tamBloco      # -40(%rbp) #
# proxBloco     # -48(%rbp) #
# ######################### #

liberaMem:
    # configura rbp
    pushq %rbp
    movq %rsp, %rbp

    pushq %rbx  # empilha %rbx antigo
    pushq %rdi  # empilha 'bloco'

    subq $32, %rsp # aloca espaco para variaveis locais

    # sbrk(0)
    movq $12, %rax
    movq $0, %rdi
    syscall

    movq %rax, -24(%rbp)  # topoAtualHeap <- sbrk(0)

    # se bloco < topoInicialHeap retorna 0
    movq -16(%rbp), %rax 
    cmpq %rax, TOPO_INICIAL_HEAP
    jge retorno_0

    # se bloco >= topoAtualHeap retorna 0
    cmpq %rax, -24(%rbp)
    jl retorno_0

    # se bloco[-16] == 0 retorna 0
    cmpq $0, -16(%rax)
    je retorno_0

    movq $0, -16(%rax)  # bloco[-16] <- 0

    # primBloco <- topoInicialHeap+16
    movq TOPO_INICIAL_HEAP, %rax
    addq $16, %rax
    movq %rax, -32(%rbp)

# while(primBloco[-16] == 1) primBloco += primBloco[-8] + 16 
comeco_loop_prim_bloco:
    movq -32(%rbp), %rax
    movq $1, %rbx
    cmpq -16(%rax), %rbx
    jne fim_loop_prim_bloco
    addq -8(%rax), %rax
    addq $16, %rax
    movq %rax, -32(%rbp)
    jmp comeco_loop_prim_bloco
fim_loop_prim_bloco:
    movq %rax, -32(%rbp)

    # tamBloco <- primBloco[-8]
    movq -8(%rax), %rax
    movq %rax, -40(%rbp)

    # proxBloco <- primBloco + tamBloco + 16
    movq -32(%rbp), %rax
    addq -40(%rbp), %rax
    addq $16, %rax
    movq %rax, -48(%rbp)

# while(proxBloco < topoAtualHeap)
comeco_loop_grande_libera:
    movq -48(%rbp), %rax
    cmpq %rax, -24(%rbp)
    jge fim_loop_grande_libera

    # #if(bloco[-16] == 0)
    movq $0, %rbx
    cmpq -16(%rax), %rbx
    jne else_loop_grande_libera

    # tamBloco += proxBloco[-8] + 16
    movq -40(%rbp), %rbx
    addq -8(%rax), %rbx
    addq $16, %rbx
    movq %rbx, -40(%rbp)

    # proxBloco += proxBloco[-8] + 16
    addq -8(%rax), %rax
    addq $16, %rax
    movq %rax, -48(%rbp)

    jmp fim_if_loop_grande_libera

else_loop_grande_libera:
    # primBloco[-8] <- tamBloco
    movq -32(%rbp), %rax
    movq -40(%rbp), %rbx
    movq %rbx, -8(%rax)

# while(proxBloco < topoAtualHeap && proxBloco[-16] == 1)
comeco_loop_pequeno_libera:
    movq -48(%rbp), %rax
    movq -24(%rbp), %rbx
    cmpq %rax, %rbx
    jge fim_loop_pequeno_libera
    movq $1, %rbx
    cmpq -16(%rax), %rbx
    jne fim_loop_pequeno_libera

    # proxBloco += proxBloco[-8] + 16
    addq -8(%rax), %rax
    addq $16, %rax
    movq -48(%rbp), %rax

    jmp comeco_loop_pequeno_libera
fim_loop_pequeno_libera:
    # primBloco <- proxBloco
    movq %rax, -48(%rbp)
    movq -32(%rbp), %rax

    # tamBloco <- primBloco[-8]
    movq %rax, -32(%rbp)
    subq $8, %rax
    movq 0(%rax), %rax
    movq %rax, -40(%rbp)

    # proxBloco <- primBloco+tamBloco+16
    movq -32(%rbp), %rax
    addq -40(%rbp), %rax
    addq $16, %rax
    movq -48(%rbp), %rax

fim_if_loop_grande_libera:
    jmp comeco_loop_grande_libera
fim_loop_grande_libera:
    # #if(tamBloco > primBloco[-8])
    movq -40(%rbp), %rax
    movq -32(%rbp), %rbx
    cmpq %rax, -8(%rbx)
    jle retorno_1

    # primBloco[-8] <- tamBloco
    movq -32(%rbp), %rbx
    movq %rax, -8(%rbx)

retorno_1:
    movq $1, %rax
    addq $40, %rsp
    popq %rbx
    popq %rbp
    ret

retorno_0:
    movq $0, %rax
    addq $40, %rsp
    popq %rbx
    popq %rbp
    ret

# TABELA DE SIMBOLOS ALOCA_MEM
# ######################### #
# num_bytes     # -16(%rbp) #
# topoAtualHeap # -24(%rbp) #
# bloco         # -32(%rbp) #
# ######################### #

alocaMem:
    # configura rbp
    pushq %rbp
    movq %rsp, %rbp

    pushq %rbx # empilha %rbx antigo
    pushq %rdi # empilha num_bytes
    
    subq $16, %rsp # aloca espaco para variaveis locais

    # topoAtualHeap <- sbrk(0)
    movq $12, %rax
    movq $0, %rdi
    syscall
    movq %rax, -24(%rbp)

    # bloco <- ultimoEnderecoAlocado
    movq ULTIMO_ENDERECO_ALOCADO, %rax
    movq %rax, -32(%rbp)

    # #if (topoAtualHeap == topoInicialHeap)
    movq -24(%rbp), %rax
    cmpq %rax, TOPO_INICIAL_HEAP
    jne loop_aloca

    # bloco <- topoAtualHeap + 16
    addq $16, %rax
    movq %rax, -32(%rbp)

    # brk(bloco + num_bytes)
    movq -16(%rbp), %rdi    # %rdi <- num_bytes
    addq %rax, %rdi         # %rdi += bloco
    movq $12, %rax          # %rax <- 12
    syscall

    # bloco[-8] <- num_bytes
    movq -16(%rbp), %rax    # %rax <- num_bytes
    movq -32(%rbp), %rbx    # %rbx <- bloco
    movq %rax, -8(%rbx)     # bloco[-8] <- %rax

    movq $1, -16(%rbx)      # bloco[-16] <- 1

    movq %rbx, ULTIMO_ENDERECO_ALOCADO  # ultimoEnderecoAlocado <- bloco

    # return bloco
    movq %rbx, %rax     # %rax <- bloco
    jmp retorno_aloca   # return %rax

# AQUI ESTA O NEXT-FIT!!!!!!
# while (bloco[-8] < num_bytes || bloco[-16] == 1)
loop_aloca:
    movq -32(%rbp), %rax    # %rax <- bloco
    movq -16(%rbp), %rbx    # %rbx <- num_bytes
    cmpq -8(%rax), %rbx     # bloco[-8] < num_bytes
    jge comeco_loop_aloca
    movq $1, %rbx           # %rbx <- 1
    cmpq -16(%rax), %rbx    # compara bloco[-16] com 1
    jne fim_loop_aloca

comeco_loop_aloca:
    # bloco += bloco[-8] + 16
    movq -32(%rbp), %rax    # %rax <- bloco
    addq -8(%rax), %rax     # %rax += %rax[-8]
    addq $16, %rax          # %rax += 16
    movq %rax, -32(%rbp)    # bloco <- %rax

    # #if(bloco > topoAtualHeap)
    cmpq %rax, -24(%rbp)
    jg if_nao_achou_bloco_livre

    # bloco <- topoInicialHeap + 16
    movq TOPO_INICIAL_HEAP, %rax    # bloco <- topoInicialHeap
    addq $16, %rax                  # bloco += 16
    movq %rax, -32(%rbp)            # guarda valor na memoria

# if(bloco == ultimoEnderecoAlocado)
if_nao_achou_bloco_livre:
    cmpq %rax, ULTIMO_ENDERECO_ALOCADO
    jne loop_aloca

    # bloco <- topoAtualHeap + 16
    movq -24(%rbp), %rax    # %rax <- topoAtualHeap
    addq $16, %rax          # rax <- topoAtualHeap+16
    movq %rax, -32(%rbp)    # bloco <- %rax
    
    # brk(bloco + num_bytes)
    addq -16(%rbp), %rax    # %rax += num_bytes
    movq %rax, %rdi         # %rdi <- bloco + num_bytes
    movq $12, %rax          # %rax <- cod de brk
    syscall

    # bloco[-8] <- num_bytes
    movq -32(%rbp), %rax    # %rax <- bloco
    movq -16(%rbp), %rbx    # %rbx <- num_bytes
    movq %rbx, -8(%rax)     # %rax[-8] <- %rbx

    movq $1, -16(%rax)      # bloco[-16] <- 1

    movq %rax, ULTIMO_ENDERECO_ALOCADO  # ultimoEnderecoAlocado <- bloco

    jmp retorno_aloca   # return bloco

fim_loop_aloca:
    # #if(bloco[-8] > num_bytes + 16)
    movq -32(%rbp), %rax    # %rax <- bloco
    movq -16(%rbp), %rbx    # %rbx <- num_bytes
    addq $16, %rbx          # %rbx += 16
    cmpq -8(%rax), %rbx     # compara bloco[-8] com num_bytes+16
    jle else_if_aloca

    # bloco[num_bytes] <- 0
    movq -32(%rbp), %rax    # %rax <- bloco  
    addq -16(%rbp), %rax    # %rax <- bloco + num_bytes
    movq $0, 0(%rax)        # *(bloco+num_bytes) <- 0

    # bloco[num_bytes+8] <-  bloco[-8] - num_bytes
    movq %rbx, -32(%rbp)    # %rbx <- bloco
    movq %rbx, -8(%rbx)     # %rbx <- bloco[-8]
    subq -16(%rbp), %rbx    # %rbx <- bloco[-8] - num_bytes
    subq $16, %rbx          # %rbx <- bloco[-8] - num_bytes - 16
    movq %rbx, 8(%rax)         # *(bloco+num_bytes+8) <- %rbx
    jmp fim_if_aloca

# else if(bloco[-8] > num_bytes)
else_if_aloca:
    movq -32(%rbp), %rax    # %rax <- bloco
    movq -16(%rbp), %rbx    # %rbx <- num_bytes
    cmpq -8(%rax), %rbx     # compara bloco[-8] com num_bytes
    jle fim_if_aloca

    # num_bytes <- bloco[-8]
    movq -8(%rax), %rax     # %rax <- bloco[-8]
    movq %rax, -16(%rbp)    # num_bytes <- %rax

fim_if_aloca:
    # bloco[-8] <- num_bytes
    movq -32(%rbp), %rax    # %rax <- bloco
    movq -16(%rbp), %rbx    # %rbx <- num_bytes
    movq %rbx, -8(%rax)     # %rax[-8] <- %rbx

    movq $1, -16(%rax)      # bloco[-16] <- 1

    movq %rax, ULTIMO_ENDERECO_ALOCADO  # ultimoEnderecoAlocado <- bloco

retorno_aloca:
    addq $24, %rsp
    popq %rbx
    popq %rbp
    ret

imprimeMapa:
    # configura rbp
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax

    # saida do procedimento
    popq %rbp
    ret
