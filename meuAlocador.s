.section .data
TOPO_INICIAL_HEAP:          .quad 0
ULTIMO_ENDERECO_ALOCADO:    .quad 0

INFORMACOES_GERENCIAIS:     .string "################"
OCUPADO:                    .string "+"
DISPONIVEL:                 .string "-"
NOVA_LINHA:                 .string "\n"
FORMATO:                    .string "%s"

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
    movq -16(%rbp), %rax            # %rax <- bloco
    cmpq TOPO_INICIAL_HEAP, %rax    # %rax < topoInicialHeap
    jl retorno_0

    # se bloco >= topoAtualHeap retorna 0
    cmpq -24(%rbp), %rax    # %rax >= topoAtualHeap
    jge retorno_0

    # se bloco[-16] == 0 retorna 0
    cmpq $0, -16(%rax)  # bloco[-16] == 0
    je retorno_0

    movq $0, -16(%rax)  # bloco[-16] <- 0

    # primBloco <- topoInicialHeap+16
    movq TOPO_INICIAL_HEAP, %rax    # %rax <- topoInicialHeap
    addq $16, %rax                  # %rax <- topoInicialHeap + 16
    movq %rax, -32(%rbp)            # primBloco <- %rax

# while(primBloco[-16] == 1) 
comeco_loop_prim_bloco:
    movq -32(%rbp), %rax        # %rax <- primBloco
    movq $1, %rbx               # %rbx <- 1
    cmpq -16(%rax), %rbx        # 1 == primBloco[-16]
    jne fim_loop_prim_bloco

    # primBloco += primBloco[-8] + 16
    addq -8(%rax), %rax         # %rax <- primBloco + primBloco[-8]
    addq $16, %rax              # %rax <- primBloco + primBloco[-8] + 16
    movq %rax, -32(%rbp)        # primBloco <- %rax
    jmp comeco_loop_prim_bloco

fim_loop_prim_bloco:
    # tamBloco <- primBloco[-8]
    movq -32(%rbp), %rax    # %rax <- primBloco
    movq -8(%rax), %rax     # %rax <- %rax[-8]
    movq %rax, -40(%rbp)    # tamBloco <- %rax

    # proxBloco <- primBloco + tamBloco + 16
    movq -32(%rbp), %rax    # %rax <- primBloco
    addq -40(%rbp), %rax    # %rax <- primBloco + tamBloco
    addq $16, %rax          # %rax <- primBloco + tamBloco + 16
    movq %rax, -48(%rbp)    # proxBloco <- %rax

# while(proxBloco < topoAtualHeap)
comeco_loop_grande_libera:
    movq -48(%rbp), %rax        # %rax <- proxBloco
    cmpq -24(%rbp), %rax        # proxBloco < topoAtualHeap
    jge fim_loop_grande_libera

    # #if(proxBloco[-16] == 0)
    movq -48(%rbp), %rax        # %rax <- proxBloco
    movq $0, %rbx               # %rbx <- 0
    cmpq -16(%rax), %rbx        # 0 == proxBloco[-16]
    jne else_loop_grande_libera 

    # tamBloco += proxBloco[-8] + 16
    movq -48(%rbp), %rax    # %rax <- proxBloco
    movq -40(%rbp), %rbx    # %rbx <- tamBloco 
    addq -8(%rax), %rbx     # %rbx <- %proxBloc[-8]
    addq $16, %rbx          # %rbx <- %proxBloc[-8] + 16
    movq %rbx, -40(%rbp)    # tamBloco <- %rbx

    # proxBloco += proxBloco[-8] + 16
    movq -48(%rbp), %rax    # %rax <- proxBloco
    addq -8(%rax), %rax     # %rax <- proxBloco + proxBloco[-8]
    addq $16, %rax          # %rax <- proxBloco + proxBloco[-8] + 16
    movq %rax, -48(%rbp)    # proxBloco <- %rax

    jmp fim_if_loop_grande_libera

else_loop_grande_libera:
    # primBloco[-8] <- tamBloco
    movq -32(%rbp), %rax    # %rax <- primBloco
    movq -40(%rbp), %rbx    # rbx <- tamBloco
    movq %rbx, -8(%rax)     # primBloco[-8] <- %rbx

# while(proxBloco < topoAtualHeap && proxBloco[-16] == 1)
comeco_loop_pequeno_libera:
    movq -48(%rbp), %rax        # %rax <- proxBloco
    movq -24(%rbp), %rbx        # %rbx <- topoAtualHeap
    cmpq %rbx, %rax             # proxBloco < topoAtualHeap
    jge fim_loop_pequeno_libera 
    movq $1, %rbx               # %rbx <- 1
    cmpq -16(%rax), %rbx        # 1 == proxBloco[-16]
    jne fim_loop_pequeno_libera

    # proxBloco += proxBloco[-8] + 16
    movq -48(%rbp), %rax    # %rax <- proxBloco
    addq -8(%rax), %rax     # %rax <- proxBloco + proxBloco[-8]
    addq $16, %rax          # %rax <- proxBloco + proxBloco[-8] + 16
    movq %rax, -48(%rbp)    # proxBloco <- %rax

    jmp comeco_loop_pequeno_libera
fim_loop_pequeno_libera:
    # primBloco <- proxBloco
    movq -48(%rbp), %rax    # %rax <- proxBloco
    movq %rax, -32(%rbp)    # primBloco <- %rax

    # tamBloco <- primBloco[-8]
    movq -32(%rbp), %rax    # %rax <- primBloco
    movq -8(%rax), %rax     # %rax <- primBloco[-8]
    movq %rax, -40(%rbp)    # tamBloco <- %rax

    # proxBloco <- primBloco+tamBloco+16
    movq -32(%rbp), %rax    # %rax <- primBloco
    addq -40(%rbp), %rax    # %rax <- primBloco + tamBloco
    addq $16, %rax          # %rax <- primBloco + tamBloco + 16
    movq %rax, -48(%rbp)    # proxBloco <- %rax

fim_if_loop_grande_libera:
    jmp comeco_loop_grande_libera

fim_loop_grande_libera:
    # #if(tamBloco > primBloco[-8])
    movq -40(%rbp), %rax    # %rax <- tamBloco
    movq -32(%rbp), %rbx    # %rbx <- primBloco
    cmpq -8(%rbx), %rax     # tamBloco > primBloco[-8]
    jle retorno_1

    # primBloco[-8] <- tamBloco
    movq -32(%rbp), %rbx    # %rbx <- primBloco
    movq %rax, -8(%rbx)     # primBloco[-8] <- tamBloco

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
    cmpq %rbx, -8(%rax)     # bloco[-8] < num_bytes
    jl comeco_loop_aloca
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
    cmpq -24(%rbp), %rax
    jle if_nao_achou_bloco_livre

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
    cmpq %rbx, -8(%rax)     # compara bloco[-8] com num_bytes+16
    jle else_if_aloca

    # bloco[num_bytes] <- 0
    movq -32(%rbp), %rax    # %rax <- bloco  
    addq -16(%rbp), %rax    # %rax <- bloco + num_bytes
    movq $0, 0(%rax)        # *(bloco+num_bytes) <- 0

    # bloco[num_bytes+8] <-  bloco[-8] - num_bytes
    movq -32(%rbp), %rbx    # %rbx <- bloco
    movq -8(%rbx), %rbx     # %rbx <- bloco[-8]
    subq -16(%rbp), %rbx    # %rbx <- bloco[-8] - num_bytes
    subq $16, %rbx          # %rbx <- bloco[-8] - num_bytes - 16
    movq %rbx, 8(%rax)      # *(bloco+num_bytes+8) <- %rbx
    jmp fim_if_aloca

# else if(bloco[-8] > num_bytes)
else_if_aloca:
    movq -32(%rbp), %rax    # %rax <- bloco
    movq -16(%rbp), %rbx    # %rbx <- num_bytes
    cmpq %rbx, -8(%rax)     # compara bloco[-8] com num_bytes
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

# TABELA DE SIMBOLOS ALOCA_MEM
# ######################### #
# bloco         # -16(%rbp) #
# topoAtualHeap # -24(%rbp) #
# conteudo      # -32(%rbp) #
# ######################### #

imprimeMapa:
    # configura rbp
    pushq %rbp
    movq %rsp, %rbp

    pushq %rbx  # empilha %rbx antigo

    subq $24, %rsp  # aloca espaco para variaveis locais

    # bloco <- topoInicialHeap + 16
    movq TOPO_INICIAL_HEAP, %rax    # %rax <- topoInicialHeap
    addq $16, %rax                  # %rax <- topoInicialHeap + 16
    movq %rax, -16(%rbp)            # bloco <- %rax

    # topoAtualHeap <- sbrk(0)
    movq $12, %rax
    movq $0, %rdi
    syscall
    movq %rax, -24(%rbp)

    # while(bloco < topoAtualHeap)
while_imprime:
    movq -16(%rbp), %rax    # %rax <- bloco
    movq -24(%rbp), %rbx    # %rbx <- topoAtualHeap
    cmpq %rax, %rbx         # bloco < topoAtualHeap
    jl fim_while_imprime

    # print("################\n")
    movq $INFORMACOES_GERENCIAIS, %rdi   # "###..." para primeiro parametro
    call printf

    # #if(bloco[-16] == 1)
    movq -16(%rbp), %rax    # %rax <- bloco
    movq $1, %rbx           # %rbx <- 1
    cmpq -16(%rax), %rbx
    jne else_imprime

    movq $OCUPADO, %rax      # %rax <- '+'
    movq %rax, -32(%rbp)    # conteudo <- '+'
    jmp fim_if_imprime

else_imprime:
    movq $DISPONIVEL, %rax   # %rax <- '-'
    movq %rax, -32(%rbp)    # conteudo <- '-'

fim_if_imprime:    
    movq $0, %rdi   # i <- 0
for_imprime:
    # i < bloco[-8]
    movq -16(%rbp), %rax    # %rax <- bloco
    cmpq -8(%rax), %rdi     # i < %rax[-8]
    jge fim_for_imprime

    # printf("%c", conteudo)
    movq %rdi, %rbx         # empilha i
    movq $FORMATO, %rdi     # 1o parametro recebe "%c"  
    movq -32(%rbp), %rsi    # 2o parametro recebe conteudo
    call printf             # printf()
    movq %rbx, %rdi         # desempilha i

    addq $1, %rdi           # i++
    jmp for_imprime

fim_for_imprime:
    # bloco += bloco[-8] + 16
    movq -16(%rbp), %rax    # %rax <- bloco
    addq -8(%rax), %rax     # %rax <- bloco + bloco[-8]
    addq $16, %rax          # %rax <- bloco + bloco[-8] + 16
    movq %rax, -16(%rbp)    # bloco <- %rax

    jmp while_imprime

fim_while_imprime:
    # printf("\n")
    movq $NOVA_LINHA, %rdi   # 1o parametro recebe "\n"
    call printf

    # saida do procedimento
    addq $24, %rsp
    popq %rbx
    popq %rbp
    ret
