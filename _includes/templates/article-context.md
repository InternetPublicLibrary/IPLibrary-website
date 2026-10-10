{% comment %} Shared section/wiki context; only topic resources with real URLs are curated. {% endcomment %}
{% assign lang = page.lang | default: 'en-US' %}
{% assign t = site.data[lang].translations %}
{% assign pt = false %}{% if lang == 'pt-BR' %}{% assign pt = true %}{% endif %}
{% assign is_wiki = false %}{% if page.layout == 'wiki' %}{% assign is_wiki = true %}{% endif %}
{% assign topic_path = page.parent_section_path | default: page.url | remove: 'index.html' %}
{% comment %} topic_title comes from atoms/topic-meta.html (menu title); wiki pages carry their section's title. {% endcomment %}
{% if page.section_title %}{% assign topic_title = page.section_title %}{% elsif topic_title == nil %}{% assign topic_title = page.title %}{% endif %}
{% for category in site.data[lang].menu %}
  {% for subcategory in category.children %}
    {% for section in subcategory.children %}
      {% if section.path == topic_path %}
        {% assign current_section = section %}
        {% assign parent_subcategory = subcategory %}
        {% assign parent_category = category %}
      {% endif %}
    {% endfor %}
  {% endfor %}
{% endfor %}
{% assign topic_slug = topic_path | split: '/' | last %}
{% assign subcategory_slug = page.parent_subcategory_path | split: '/' | last %}
{% assign category_folder = parent_category.data_folder | default: parent_category.path | split: '/' | last %}
{% assign subcategory_folder = parent_subcategory.data_folder | default: subcategory_slug %}
{% assign topic_folder = current_section.data_folder | default: topic_slug %}
{% assign topic_data = site.data[lang][category_folder][subcategory_folder][topic_folder] %}
{% assign resources = '' | split: '' %}
{% assign candidate_resources = page.resources | default: current_section.resources %}
{% for resource in candidate_resources %}
  {% assign resource_url = resource.url | downcase %}
  {% if resource.url and resource.url != '' %}{% unless resource_url contains 'example.com' %}{% assign resources = resources | push: resource %}{% endunless %}{% endif %}
{% endfor %}
{% for entry in topic_data %}
  {% if entry.url %}{% assign entries = '' | split: '' | push: entry %}{% else %}{% assign entries = entry[1] %}{% endif %}
  {% for resource in entries %}
    {% assign resource_url = resource.url | downcase %}
    {% if resource.url and resource.url != '' %}{% unless resource_url contains 'example.com' %}{% assign resources = resources | push: resource %}{% endunless %}{% endif %}
  {% endfor %}
{% endfor %}
{% assign resources = resources | uniq %}
{% assign wiki_url = topic_path | append: 'wiki/' %}
{% assign wiki_pages = site.pages | where: 'url', wiki_url %}
{% assign issue_base = 'https://github.com/InternetPublicLibrary/' | append: lang | append: '/issues/new?title=' %}
{% assign edit_title = 'Edit: ' | append: topic_title | url_encode %}
{% assign suggestion_title = 'Resource suggestion: ' | append: topic_title | url_encode %}
{% assign issue_body = page.url | absolute_url | url_encode %}
{% assign edit_url = issue_base | append: edit_title | append: '&body=' | append: issue_body %}
{% if page.github_edit_url %}{% assign edit_url = page.github_edit_url %}{% endif %}
{% assign suggest_url = issue_base | append: suggestion_title | append: '&body=' | append: issue_body %}
{% assign wiki_edit_title = 'Edit: Wiki: ' | append: topic_title | url_encode %}
{% assign wiki_issue_body = wiki_url | absolute_url | url_encode %}
{% assign wiki_edit_url = issue_base | append: wiki_edit_title | append: '&body=' | append: wiki_issue_body %}
{% if wiki_pages.first.github_edit_url %}{% assign wiki_edit_url = wiki_pages.first.github_edit_url %}{% endif %}
