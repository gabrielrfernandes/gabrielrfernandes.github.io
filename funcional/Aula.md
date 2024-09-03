- [Aula Bioinformática](#aula-bioinformática)
  - [Origem dos dados](#origem-dos-dados)
  - [Conhecendo o conteúdo da pasta](#conhecendo-o-conteúdo-da-pasta)
  - [Controle de qualidade das sequências](#controle-de-qualidade-das-sequências)
  - [Montagem do genoma](#montagem-do-genoma)
  - [Avaliando a qualidade da montagem](#avaliando-a-qualidade-da-montagem)
  - [Predição de Genes](#predição-de-genes)
  - [Classificação funcional dos genes](#classificação-funcional-dos-genes)
  - [Visualização em vias metabólicas](#visualização-em-vias-metabólicas)

-----

# Aula Bioinformática

> **Objetivo:** Montagem e anotação funcional de um genoma bacteriano.

---

## Origem dos dados
Os dados utilizados são provenientes de um sequenciamento feito na plataforma Illumina. Uma biblioteca de DNA foi utilizada para duas diferentes abordagens de sequenciamento, porém com a mesma profundidade esperada de 60x.
- 1 milhão de pares de leituras de 150bp: `lib1`
- 500 mil pares de leituras de 300bp. `lib2`

## Conhecendo o conteúdo da pasta
- Uma vez dentro do servidor, pode ver a sua pasta atual e seu conteúdo com os comandos:
``` bash
pwd #path of working directory

ls #lista o conteudo da pasta
```

- Entre na pasta de trabalho e veja seu conteúdo:
```bash
mkdir Aula_Funcional
cd Aula_Funcional
ls
```

- Vamos criar os diretórios onde armazenaremos os resultados
``` bash
mkdir 0.Logs 1.Trim 2.Assembly 3.Genes 4.Function
ls

conda activate assembly
```
---
## Controle de qualidade das sequências
O sequenciamento Illumina tem uma taxa de erro de substituição de bases de cerca de 1%. À medida em que a sequência vai sendo sintetizada essa taxa de erro pode aumentar. Por isso, é importante retirarmos as regiões com baixa qualidade de bases.

A ferramenta Trimmomatic é uma das muitas utilizadas para esse fim. Nela, podemos definir a qualidade média das bases em uma janela deslizante, além da remoção de adaptadores e exclusão de sequências muito curtas.
O comando utilizado é:
```bash
trimmomatic PE -threads 4 /databases/big/input/lib1_150bp_R1.fq.gz /databases/big/input/lib1_150bp_R2.fq.gz 1.Trim/lib1.Paired_R1.fastq.gz 1.Trim/lib1.Unpaired_R1.fastq.gz 1.Trim/lib1.Paired_R2.fastq.gz 1.Trim/lib1.Unpaired_R2.fastq.gz ILLUMINACLIP:/databases/big/ref/adapters.fasta:2:30:10:2:keepBothReads LEADING:5 TRAILING:5 SLIDINGWINDOW:4:20 MINLEN:50 2> 0.Logs/lib1.trimmomatic.log
```

A linha de comando recebe parâmetros que chamamos de *_flags_*. Seccionando as linhas de comando, vemos a função de cada parâmetro.
```bash
trimmomatic #inicia o programa
PE #informa que o sequenciamento é paired-end
-threads 4 #conta que vai usar 4 processadores
/databases/big/input/lib1_150bp_R1.fq.gz /databases/big/input/lib1_150bp_R2.fq.gz #indicas os arquivos que contem as sequências forward e reversas a serem corrigidas
1.Trim/lib1.Paired_R1.fastq.gz #Indica onde vai escrever as sequências Forward (R1) cujos pares sobreviveram
1.Trim/lib1.Unpaired_R1.fastq.gz #Sequências forward cujos pares reversos não passaram no critério de qualidade
1.Trim/lib1.Paired_R2.fastq.gz 1.Trim/lib1.Unpaired_R2.fastq.gz #Os mesmos que os anteriores, só que com as sequências reversas: R2
ILLUMINACLIP:/databases/big/ref/adapters.fasta:2:30:10:2:keepBothReads #Cita o nome do arquivo que contém a sequência dos adaptadores : número de mismatches aceitos : tamanho mínimo de um palíndromo (em caso de pares de reads) : tamanho mínimo do alinhamento simples : tamanho mínimo da sequência do adaptador identifica.
LEADING:5 TRAILING:5 #Valores mínimos de qualidade para começar a análise no início (LEADING) e no final da sequência (TRAILING)
SLIDINGWINDOW:4:20 #Tamanho da janela de bases : Qualidade média dentro da janela
MINLEN:50 #Tamanho mínimo da sequência restante para que não seja descartada
2> 0.Logs/lib1.trimmomatic.log #Escreve o relatório da análise no arquivo mencionado
```

Assim, dentro da pasta `1.Trim` teremos os arquivos limpos. E no `0.Logs` podemos ver o relatório.
```bash
cat 0.Logs/lib1.trimmomatic.log
```


## Montagem do genoma
Para a montagem do genoma, utilizaremos apenas as sequências cujos pares "sobreviveram" ao controle de qualidade. Assim, teremos dois arquivos de entrada: as sequências forward e as reverse.
Dentre os vários programas para a montagem de um genoma, vamos utilizar o Spades.
```bash
spades.py --isolate -o 2.Assembly/lib1 -1 1.Trim/lib1.Paired_R1.fastq.gz -2 1.Trim/lib1.Paired_R2.fastq.gz -t 4 -m 16
```
Esse comando contém os seguintes parâmetros:
```bash
spades.py #Roda o programa
--isolate #Diz que o genoma é de um isolado. Ou seja, espera-se que todas as sequências tenham vindo de um mesmo organismo
-o 2.Assembly/lib1 #Diretório onde escreverá os resultados
-1 1.Trim/lib1.Paired_R1.fastq.gz #Arquivo forward
-2 1.Trim/lib1.Paired_R2.fastq.gz #Arquivo reverse
-t 4 #Número de processadores
-m 16 #Máximo de memória
```
---
## Avaliando a qualidade da montagem
Existem métrica que informam sobre o quão completa está a montagem do seu genoma. Uma das ferramentas é o Quast, que fornece métricas como:
- tamanho do genoma montado
- número de contigs úteis
- conteúdo GC
- N50 e L50

Para rodar, podemos usar o comando com os seguintes parâmtros:

```bash
quast -o 2.Assembly/lib1/quast/ -m 1000 -t 4 -1 1.Trim/lib1.Paired_R1.fastq.gz -2 1.Trim/lib1.Paired_R2.fastq.gz 2.Assembly/lib1/scaffolds.fasta
```
Os parâmetros são: 
```bash
quast #Chama o programa
-o 2.Assembly/lib1/quast/ #Diz onde vão escrever os resultados
-m 1000 #Tamano mínimo de um contig
-t 4 #Número de processadores
-1 1.Trim/lib1.Paired_R1.fastq.gz #[OPCIONAL] Sequências forward utilizadas na montagem
-2 1.Trim/lib1.Paired_R2.fastq.gz #[OPCIONAL] Sequências reverse utilizadas na montagem
2.Assembly/lib1/scaffolds.fasta #Arquivo com sua montagem
```

Observando o conteúdo do arquivo, vemos as métricas da montagem
```bash
cat 2.Assembly/lib1/quast/report.txt
```

```bash
Assembly                    scaffolds
# contigs (>= 0 bp)         212      
# contigs (>= 1000 bp)      81       
# contigs (>= 5000 bp)      62       
# contigs (>= 10000 bp)     56       
# contigs (>= 25000 bp)     46       
# contigs (>= 50000 bp)     29       
Total length (>= 0 bp)      4502140  
Total length (>= 1000 bp)   4473025  
Total length (>= 5000 bp)   4431666  
Total length (>= 10000 bp)  4386681  
Total length (>= 25000 bp)  4227455  
Total length (>= 50000 bp)  3592230  
# contigs                   81       
Largest contig              329901   
Total length                4473025  
GC (%)                      50.79    
N50                         115885   
N90                         34661    
auN                         148131.5 
L50                         12       
L90                         40       
# total reads               1998966  
# left                      999483   
# right                     999483   
Mapped (%)                  99.28    
Properly paired (%)         98.67    
Avg. coverage depth         66       
Coverage >= 1x (%)          100.0    
# N's per 100 kbp           4.47 
```

## Predição de Genes

A predição de genes vai procurar por janelas abertas de leitura (ORF) e aprender sobre o uso de codons dentro dessa janela para predizer os genes possivelmente codificantes.

Dentre as diversas ferramentas, usaremos a ferramenta *_prodigal_*

```bash
prodigal -a 3.Genes/lib1.aa -d 3.Genes/lib1.nt -f gff -i 2.Assembly/lib1/scaffolds.fasta -o 3.Genes/lib1.gff
```

O comando contém as seguintes _flags_
```bash
prodigal #Chama o programa
-a 3.Genes/lib1.aa #Escreve um arquivo contendo as sequências de aminoácidos
-d 3.Genes/lib1.nt #Escreve um arquivo contendo os nucleotídeos
-f gff #Determina o formato GFF para a anotação
-i 2.Assembly/lib1/scaffolds.fasta #Conta qual o arquivo contém o genoma para a predição
-o 3.Genes/lib1.gff #Escreve um arquivo contendo a anotação
```
Podemos observar as primeiras linha do arquivo:
```bash
head 3.Genes/lib1.aa 
```
No cabeçalho temos algumas informações:
`>NODE_1_length_329901_cov_29.783351_1 # 19 # 486 # 1 # ID=1_1;partial=00;start_type=ATG;rbs_motif=AGGA;rbs_spacer=5-10bp;gc_cont=0.538`.

A informação `partial=00` informa se o gene foi predito completamente - Metionina no início e codon de parada ao final. `partial=10` indica que não havia Metionina no início, mas havia codon de parada. `partial=01` indica que o codon de parada não estava presente. E `partial=11` indica que não havia metionina e nem codon de parada, porém o preditor encontrou uma sequência de possível codons que condiziam com _codon usage_ do organismo.

Podemos contar quantos genes codificantes de proteínas foram preditos:
```bash
grep ">" -c 3.Genes/lib1.aa 
```
O que esse comando faz?
```bash
grep #Chama o programa que faz buscas
">" #Aponta o que ele precisa buscar
-c #Retorna a contagem de linhas que tinham aquele item da busca ao invés de retornar a linha inteira
3.Genes/lib1.aa #Arquivo em que a busca será feita
```

Podemos usar o _grep_  para contar quantos genes estavam completos:
```bash
grep ">" 3.Genes/lib1.aa | cut -d "#" -f5 | cut -d ";" -f2 | sort | uniq -c
```
Explicando...
```bash
grep #Chama o programa que faz as buscas
">" #Aponta o que ele precisa buscar
3.Genes/lib1.aa #Arquivo em que será feita a busca
| #Conecta o resultado do comando anterior ao próximo comando
cut #Corta o arquivo em colunas
-d "#" #Determina que o caracter delimitador de colunas é o #
-f5 #Mostra a coluna 5
| #Conecta o resultado do comando anterior ao próximo comando
cut -d ";" -f2 | #Corta usando o ; como delimitador e mostra a segunda coluna
sort | #Ordena em ordem alfabética
uniq -c #Conta quanta vezes cada item único apareceu
```

## Classificação funcional dos genes

Como vimos, temos milhares de possíveis genes, e não sabemos suas funções.
Uma das formas de identificar as funções é através de alinhamentos locais com bancos de dados secundários que contenham alguma informação funcional.
Para tal tarefa, o BLAST é a ferramenta mais popular. Usaremos o _diamond_ que faz um alinhamento local, assim como o BLAST, porém de maneira muito mais rápida.

Utilizaremos o UniProt como banco de dados para as buscas. A primeira etapa é transformar as sequências do UniProt em um formato que o _diamond_ possa ler.
```bash
diamond makedb --threads 4 --in /databases/big/ref/uniprotkb_proteome_UP000000625_2024_08_29.fasta.gz --db ecoli
```
As _flags_ significam:
```bash
diamond #Chama o programa
makedb #Conta qual a tarefa que ele vai fazer
--threads 4 #Número de processadores
--in /databases/big/ref/uniprotkb_proteome_UP000000625_2024_08_29.fasta.gz #Onde está o arquivo do UniProt com as sequências
--db ecoli #Nome que quer dar ao seu banco de dados
```
Após formatarmos o banco de dados, podemos chamar o alinhamento. Temos um banco de dados de sequências de aminoácidos (UniProt), e arquivo de entrada de aminoácidos ou nucleotídeos. Poderiam então escolher entre duas opções:
- *_blastp_*: que compara minhas sequências de proteínas a um banco de proteínas
- *_blastx_*: que traduz minhas sequências de nucleotídeos nas 6 janelas de leitura para compará-las ao banco de prteínas

Para otimizar o tempo - dado que temos as sequências de aminoácidos - rodaremos o *_blastp_*:

```bash
diamond blastp -d ecoli.dmnd -q 3.Genes/lib1.aa -o 4.Function/lib1.diamond -e 1e-20 -k 1 -p 4 --outfmt 6
```
As _flags_ são:
```bash
diamond #Chama o programa
blastp #Diz a opção de alinhamento
-d ecoli.dmnd #Aponta o banco de dados
-q 3.Genes/lib1.aa #Aponta o arquivo de entrada 
-o 4.Function/lib1.diamond #Define o nome do arquivo de saída
-e 1e-20 #Estabelece um mínimo de e-value
-k 1 #Pede para mostrar só o melhor resultado para cada um dos meus genes
-p 4 #Usa 4 processadores
--outfmt 6 #Mostra o resultado em um formato tabular com 12 colunas
```
Podemos ver como é o resultado:
```bash
head 4.Function/lib1.diamond

#Descrição das colunas
 # 1.  qseqid      query or source (gene) sequence id
 # 2.  sseqid      subject or target (reference genome) sequence id
 # 3.  pident      percentage of identical positions
 # 4.  length      alignment length (sequence overlap)
 # 5.  mismatch    number of mismatches
 # 6.  gapopen     number of gap openings
 # 7.  qstart      start of alignment in query
 # 8.  qend        end of alignment in query
 # 9.  sstart      start of alignment in subject
 #10.  send        end of alignment in subject
 #11.  evalue      expect value
 #12.  bitscore    bit score
```
Vemos que a segunda coluna contém o nome da proteína que melhor descreve nosso gene no banco de dados.
Agora queremos adicionar informação funcional à ela.
Vamos adicionar a informação do KEGG, e saber qual KO e via metabólica nosso gene pertence.

Para isso vamos executar uma sério de comandos.
```bash
#Entrar na pasta que contém os resultados
cd 4.Function

#Pega o nome de cada proteína que teve hit
awk -F'|' '{print $2}' lib1.diamond > protein_ids.txt
head protein_ids.txt

#Adicionar o nome dessa proteína do UniProte à nossa tabela do resultado do Diamond
paste lib1.diamond protein_ids.txt > diamond_with_protein_ids.txt

# Colocar em ordem alfabética as colunas que contem as informações que vamos precisar.
## A coluna que contém o nome das proteínas é a 13.
sort -k13 diamond_with_protein_ids.txt > sorted_diamond.txt
## A coluna que contém os nomes das mesmas proteínas no arquivo de conversão, é a 1
sort -k1 /databases/big/ref/Uniprot2KEGG.eco.txt > sorted_Uniprot2KEGG.txt
## Juntamos as duas tabelas, levando em consideração o ponto de junção como sendo a 13 coluna do resultado do Diamond, com a 1 coluna da tabela de conversão.
join -t$'\t' -1 13 -2 1 sorted_diamond.txt sorted_Uniprot2KEGG.txt > diamond_with_KEGG.txt

# Colocar em ordem alfabética as colunas que contem as informações que vamos precisar.
## A coluna que contém o nome da entrada no KEGG é a 14.
sort -k14 diamond_with_KEGG.txt > sorted_diamond_with_KEGG.txt
## A coluna que contém os nomes das mesmas proteínas no arquivo de conversão, é a 1
sort -k1 /databases/big/ref/KEGG2KO.eco.txt > sorted_KEGG2KO.txt
## Juntamos as duas tabelas, levando em consideração o ponto de junção como sendo a 14 coluna do resultado do Diamond, com a 1 coluna da tabela de conversão.
join -t$'\t' -1 14 -2 1 sorted_diamond_with_KEGG.txt sorted_KEGG2KO.txt > diamond_with_KO.txt

# Temos uma tabela com 15 colunas, sendo que a última delas é o identificador do KEGG Orthology
## Podemos ver qual é o KO mais representado
cat diamond_with_KO.txt | cut -f15 | sort | uniq -c | sort -k1 -nr | head
## Podemos gerar uma lista para visualizar no mapa metabólico
cat diamond_with_KO.txt | cut -f15 | sort -u | sed -e 's/ko://g' > KO_list.txt
```

## Visualização em vias metabólicas

A partir da lista de KOs, é possível ver suas funções no site do [KEGG](https://www.genome.jp/kegg/)<base target="_blank"> ou criar uma via metabólica interativa com o [iPath3](https://pathways.embl.de/ipath3.cgi)<base target="_blank">.