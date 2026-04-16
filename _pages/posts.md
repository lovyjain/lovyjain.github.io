---
layout: home
author_profile: true
title: "Posts by Category"
permalink: /posts/
---

{% comment %}
  This page uses a custom layout to display all posts organized by category.
{% endcomment %}

<div class="archive">
  {% assign groupedposts = site.posts | group_by: "categories" %}
  {% for group in groupedposts %}
    <h2 id="{{ group.name | slugify }}" class="archive__subtitle">{{ group.name }}</h2>
    {% assign posts = group.items | sort: "date" | reverse %}
    {% for post in posts %}
      {% include archive-single.html type="list" %}
    {% endfor %}
  {% endfor %}
</div>
