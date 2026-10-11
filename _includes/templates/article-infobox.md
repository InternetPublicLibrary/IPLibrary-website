{% comment %} Compact information card for the current topic, after its lead in DOM order. {% endcomment %}
<aside aria-labelledby="information-title" class="lg:col-start-3 lg:row-start-2 min-w-0">
  <div class="bg-white border border-gray-200 rounded-lg p-4 text-sm text-gray-700">
    <h2 id="information-title" class="font-semibold text-base text-gray-900 mb-3">{% if pt %}Informações{% else %}Information{% endif %}</h2>
    <dl class="space-y-3">
      {% if page.parent_category_path %}
      <div><dt class="font-semibold">{% if pt %}Categoria{% else %}Category{% endif %}</dt><dd><a href="{{ page.parent_category_path | relative_url }}" class="text-blue-600 hover:underline">{{ page.parent_category | escape }}</a></dd></div>
      {% endif %}
      {% if page.parent_subcategory_path %}
      <div><dt class="font-semibold">{% if pt %}Subcategoria{% else %}Subcategory{% endif %}</dt><dd><a href="{{ page.parent_subcategory_path | relative_url }}" class="text-blue-600 hover:underline">{{ page.parent_subcategory | escape }}</a></dd></div>
      {% endif %}
      <div><dt class="font-semibold">{% if pt %}Outras seções{% else %}Sibling sections{% endif %}</dt><dd>{{ parent_subcategory.children.size | default: 1 | minus: 1 | at_least: 0 }}</dd></div>
      <div><dt class="font-semibold">{{ t.layout.curated_resources | default: 'Curated resources' }}</dt><dd>{{ resources.size }}</dd></div>
      <div><dt class="font-semibold">{% if pt %}Idiomas da biblioteca{% else %}Library languages{% endif %}</dt><dd class="flex flex-wrap gap-x-3">
        {% for language in site.languages %}
        {% include lang-switch-url.html lang=language.code %}
        <a href="{{ lang_switch_url | relative_url }}" hreflang="{{ language.code }}" lang="{{ language.code }}" class="text-blue-600 hover:underline">{% if language.code == 'pt-BR' %}Português{% elsif language.code == 'en-US' %}English{% else %}{{ language.name | escape }}{% endif %}</a>
        {% endfor %}
      </dd></div>
      {% if wiki_pages.size > 0 %}<div><dt class="font-semibold">{{ t.layout.wiki | default: 'Wiki' }}</dt><dd><a href="{{ wiki_url | relative_url }}" class="text-blue-600 hover:underline">{% if pt %}Wiki de {{ topic_title | escape }}{% else %}{{ topic_title | escape }} wiki{% endif %}</a></dd></div>{% endif %}
      {% if page.tags.size > 0 %}<div><dt class="font-semibold">{% if pt %}Marcadores{% else %}Tags{% endif %}</dt><dd class="flex flex-wrap gap-1 mt-1">{% for tag in page.tags %}<span class="px-2 py-1 bg-gray-100 rounded text-gray-700">{{ tag | escape }}</span>{% endfor %}</dd></div>{% endif %}
    </dl>
  </div>
</aside>
