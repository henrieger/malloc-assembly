# include "meuAlocador.h"

/**
 * 
 * AVISO IMPORTANTE!!!!
 * 
 * Este código em C serve apenas como
 * pseudo-código base para a implementação
 * das funções em Assembly.
 * 
 * ESTE CÓDIGO NÃO É FUNCIONAL E 
 * NÃO COMPILA!!!
 * 
 */

void *topoInicialHeap;
void *ultimoEnderecoAlocado;

void iniciaAlocador()
{
    topoInicialHeap = sbrk(0);
    ultimoEnderecoAlocado = topoInicialHeap;
}

void finalizaAlocador()
{
    brk(topoInicialHeap);
}

int liberaMem(void *bloco)
{
    void *topoAtualHeap = sbrk(0);
    if(bloco < topoInicialHeap || bloco >= topoAtualHeap || bloco[-16] == 0)
        return 0;

    bloco[-16] = 0;
    
    void *primBloco = topoInicialHeap+16;
    while(primBloco[-16] == 1)
    {
        primBloco += primBloco[-8] + 16;
    }

    long tamBloco = primBloco[-8];
    void *proxBloco = primBloco+tamBloco+16;

    while(proxBloco < topoAtualHeap)
    {
        if(proxBloco[-16] == 0)
        {
            tamBloco += proxBloco[-8] +16;
            proxBloco += proxBloco[-8] + 16;
        }
        else
        {
            primBloco[-8] = tamBloco;
            while(proxBloco < topoAtualHeap && proxBloco[-16] == 1)
            {
                proxBloco += proxBloco[-8] + 16;
            }
            primBloco = proxBloco;
            tamBloco = primBloco[-8];
            proxBloco = primBloco+tamBloco+16;
        }
    }
    if(tamBloco > primBloco[-8])
        primBloco[-8] = tamBloco;

    return 1;
}

void *alocaMem(int num_bytes)
{
    void *topoAtualHeap = sbrk(0);
    void *bloco = ultimoEnderecoAlocado;

    if(topoAtualHeap == topoInicialHeap)
    {
        bloco = topoAtualHeap + 16;
        brk(bloco + num_bytes);
        bloco[-8] = num_bytes;
        bloco[-16] = 1;
        ultimoEnderecoAlocado = bloco;
        return bloco;
    }

    // ESSA EH A CONDICAO DO NEXT-FIT!!!!
    while(bloco[-8] < num_bytes || bloco[-16] == 1)
    {
        bloco += bloco[-8] + 16;
        if(bloco > topoAtualHeap)
            bloco = topoInicialHeap+16;
        if(bloco == ultimoEnderecoAlocado)
        {
            bloco = topoAtualHeap + 16;
            brk(bloco + num_bytes);
            bloco[-8] = num_bytes;
            bloco[-16] = 1;
            ultimoEnderecoAlocado = bloco;
            return bloco;
        }
    }

    if(bloco[-8] > num_bytes + 16)
    {
        bloco[num_bytes] = 0;
        bloco[num_bytes+8] = bloco[-8] - num_bytes - 16;
    }
    else if (bloco[-8] > num_bytes)
        num_bytes = bloco[-8];

    bloco[-8] = num_bytes;
    bloco[-16] = 1;
    ultimoEnderecoAlocado = bloco;

    return bloco;
}