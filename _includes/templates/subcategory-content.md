{% comment %} Subcategory introduction; preserves parent links and the Overview heading contract. {% endcomment %}
{% if page.lang == 'pt-BR' %}
## Visão geral

**{{ page.title }}** é uma subcategoria de [{{ page.parent_category }}]({{ page.parent_category_path }}). Suas seções organizam os temas listados nesta página para que você consulte cada área separadamente.

## Consulta de recursos

Escolha uma seção para ver os materiais disponíveis e a wiki do tema. Compare a descrição e a origem de cada recurso com seu objetivo de estudo. As ferramentas de pesquisa externa consultam outras fontes e não fazem parte da seleção de recursos da IPL.
{% else %}
## Overview

**{{ page.title }}** is a subcategory of [{{ page.parent_category }}]({{ page.parent_category_path }}). Its sections organize the topics listed on this page so that each area can be explored separately.

## Finding resources

Choose a section to see its available materials and topic wiki. Compare each resource's description and source with your study goals. External research tools query other sources and are separate from IPL's curated resource lists.
{% endif %}
