{% comment %} Topic introduction; Markdown headings must remain on separate lines. {% endcomment %}
{% if page.lang == 'pt-BR' %}
## Escopo

{% if page.title == 'Teoria da Criptografia' %}
A teoria da criptografia estuda as bases matemáticas da proteção de informações. Examina como definir confidencialidade e autenticidade, quais capacidades um adversário pode ter e sob quais hipóteses um esquema criptográfico pode ser considerado seguro.

### Como estudar

Probabilidade, teoria dos números e complexidade computacional ajudam a interpretar definições de segurança e provas por redução. Ao comparar materiais, identifique o modelo de ameaça e as hipóteses usadas: uma prova de segurança depende dessas condições.
{% else %}
**{{ page.title }}** integra [{{ page.parent_subcategory }}]({{ page.parent_subcategory_path }}), na categoria [{{ page.parent_category }}]({{ page.parent_category_path }}). Esta página separa os materiais desse tema das demais seções da subcategoria.

### Como consultar os materiais

A lista de recursos apresenta o endereço e a descrição de cada material disponível. Use esses dados para verificar sua origem e adequação ao estudo de {{ page.title }}. As seções relacionadas permitem explorar outros temas de {{ page.parent_subcategory }}.
{% endif %}

## Contribuições

Para sugerir um material sobre {{ page.title }}, envie o endereço e explique sua relação com o tema pelo link “Sugerir um recurso”. Correções e explicações para a wiki podem ser propostas pelo link “Editar”.
{% else %}
## Scope

{% if page.title == 'Cryptography Theory' %}
Cryptography theory studies the mathematical foundations of protecting information. It examines how to define confidentiality and authenticity, what capabilities an adversary may have, and which assumptions make a cryptographic scheme secure.

### Study approach

Probability, number theory, and computational complexity help explain security definitions and reduction proofs. When comparing materials, identify their threat models and assumptions: a security proof depends on those conditions.
{% else %}
**{{ page.title }}** belongs to [{{ page.parent_subcategory }}]({{ page.parent_subcategory_path }}) in [{{ page.parent_category }}]({{ page.parent_category_path }}). This page distinguishes resources for this topic from the other sections in its subcategory.

### Using the materials

The resource list gives the address and description of each available item. Use that information to assess its source and relevance to {{ page.title }}. Related sections connect this topic to other areas of {{ page.parent_subcategory }}.
{% endif %}

## Contributions

To suggest a resource about {{ page.title }}, provide its address and explain its relevance through “Suggest a resource”. Use “Edit” to propose corrections or explanations for the wiki.
{% endif %}
