{% comment %} Dense resource rows; the shared context excludes placeholder URLs. {% endcomment %}
<section aria-labelledby="resources" class="bg-white border border-gray-200 rounded-lg p-4 sm:p-5 mt-5">
  <h2 id="resources">{{ t.layout.curated_resources | default: 'Curated resources' }}</h2>
  {% if resources.size > 0 %}
  <ul class="list-none p-0 divide-y divide-gray-200">
    {% for resource in resources %}
    <li class="py-3">
      <div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
        <a href="{{ resource.url | escape }}" class="font-semibold">{{ resource.title | default: resource.name | escape }}</a>
        {% if resource.type or resource.resource_type %}<span class="text-xs px-2 py-1 rounded bg-blue-50 text-blue-800">{{ resource.type | default: resource.resource_type | escape }}</span>{% endif %}
      </div>
      <span class="text-sm text-gray-600">{{ resource.url | split: '://' | last | split: '/' | first | escape }}</span>
      {% if resource.description %}<p>{{ resource.description | escape }}</p>{% endif %}
    </li>
    {% endfor %}
  </ul>
  {% else %}
  <p>{% if pt %}Nenhum recurso selecionado está listado para {{ topic_title | escape }}.{% else %}No curated resources are listed for {{ topic_title | escape }}.{% endif %}</p>
  {% endif %}
  <a href="{{ suggest_url | escape }}" class="inline-flex items-center min-h-11 font-semibold">{% if pt %}Sugerir um recurso{% else %}Suggest a resource{% endif %}</a>
</section>
