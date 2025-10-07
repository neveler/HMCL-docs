---
title: Getting Started Guide
---

## Notice

If you encounter a BUG, please send feedback in time to [HMCL-dev/HMCL](https://github.com/HMCL-dev/HMCL/issues).

{% for group in site.data.navigation.docs %}
## {{ group.title }}

{% for item in group.children %}
{{ forloop.index }}. [{{ item.title }}]({{ item.url }})
{%- if item.description %}

    {{ item.description }}
{% endif %}
{% endfor %}
{% endfor %}
