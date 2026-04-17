---
layout: archive
title: "Example Archive"
permalink: /example-archive/
---

This is an example archive page that demonstrates how archive layouts work in the site structure.

{% for post in site.posts limit:5 %}
- [{{ post.title }}]({{ post.url | relative_url }})
{% endfor %}
