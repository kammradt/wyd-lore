# Dados estruturados

Arquivos YAML gerados a partir das páginas em [`wiki/`](../wiki/), para agentes e scripts que precisam de dados em vez de texto corrido. A fonte de verdade continua sendo a wiki: quando uma página muda, o arquivo correspondente deve ser atualizado.

| Arquivo | Conteúdo |
| --- | --- |
| [`quests.yml`](quests.yml) | Uma entrada por página em `wiki/quests/`: níveis, local, NPCs, chefes, itens exigidos, recompensas, se é repetível e os passos. |
| [`maps.yml`](maps.yml) | Uma entrada por página em `wiki/mapas/`: tipo, região, NPCs e monstros citados. |
| [`npcs.yml`](npcs.yml) | NPCs nomeados nas páginas, com os mapas e páginas onde aparecem. |

Notas:

- Os nomes seguem exatamente a grafia das páginas. Alguns NPCs aparecem com dois nomes (por exemplo, "Chefe de Treino" e "TrainerChief") e ficam em entradas separadas.
- `null` significa que a página não informa o dado.
- Cada entrada tem `page` ou `pages`, apontando para a página de origem.
