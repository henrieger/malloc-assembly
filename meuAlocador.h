# ifndef __MEU_ALOCADOR_H__
# define __MEU_ALOCADOR_H__

// Define o topo da heap antes das alocações
void iniciaAlocador();

// Desaloca blocos e retorna brk para valor original
void finalizaAlocador();

// Indica que um bloco está livre
int liberaMem(void *bloco);

// Aloca um bloco de tamanho num_bytes na memória
void *alocaMem(int num_bytes); 

// Imprime um mapa do estado atual da heap
void imprimeMapa();

# endif