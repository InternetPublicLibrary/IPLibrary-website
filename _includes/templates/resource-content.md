{% comment %} Resource details from source metadata; no generated edit date. {% endcomment %}
{% if page.lang == 'pt-BR' %}
## Sobre este recurso

**{{ page.title }}**{% if page.resource_type %} é um recurso do tipo {{ page.resource_type }}{% endif %}{% if page.category %} na categoria {{ page.category }}{% endif %}.

### Descrição

{{ page.description }}

{% if page.tags.size > 0 %}
Marcadores: {{ page.tags | join: ', ' }}.
{% endif %}

### Acesso

O link para o recurso leva ao site de origem, onde você pode verificar as condições atuais de acesso.
{% else %}
## About this resource

**{{ page.title }}**{% if page.resource_type %} is a {{ page.resource_type }} resource{% endif %}{% if page.category %} in the {{ page.category }} category{% endif %}.

### Description

{{ page.description }}

{% if page.tags.size > 0 %}
Tags: {{ page.tags | join: ', ' }}.
{% endif %}

### Access

The resource link opens its source website, where you can check the current conditions of access.
{% endif %}

{% if page.access %}
{{ page.access }}
{% endif %}
