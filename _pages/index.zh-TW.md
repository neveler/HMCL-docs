---
title: 新手導航
---

## 注意

如果您遇到 BUG，請及時在 [HMCL-dev/HMCL](https://github.com/HMCL-dev/HMCL/issues) 髮送反饋。

{% for group in site.data.navigation.docs %}
## {{ group.title }}

{% for item in group.children %}
{{ forloop.index }}. [{{ item.title }}]({{ item.url }})
{%- if item.description %}

    {{ item.description }}
{% endif %}
{% endfor %}
{% endfor %}
