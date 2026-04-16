# lovyjain.github.io

Modern Jekyll/GitHub Pages portfolio for **Lovy Jain**.

## Quick customization guide

### 1) Profile image and favicon
- Replace `assets/images/profile-placeholder.svg` with your real profile image (recommended 600x600+). If you use a JPG/PNG, update references in:
  - `_includes/navbar.html`
  - `_includes/sections/hero.html`
- Replace favicon at `assets/images/favicon.svg`.

### 2) Homepage content sections
All home sections are modular Jekyll includes:
- Hero: `_includes/sections/hero.html`
- About + stats: `_includes/sections/about.html`
- Skills: `_includes/sections/skills.html`
- Projects: `_includes/sections/projects.html`
- Experience timeline: `_includes/sections/experience.html`
- Blog cards: `_includes/sections/blog.html`
- Contact: `_includes/sections/contact.html`

### 3) Global layout and styling
- Layout shell: `_layouts/brand.html`
- Navbar/Footer components: `_includes/navbar.html`, `_includes/footer.html`
- Styles: `assets/css/site.css`
- Small interactions (mobile nav + footer year): `assets/js/site.js`

### 4) Blog cards
Blog cards pull from `site.posts` automatically. Add or edit posts under `_posts/`.

### 5) SEO and performance notes
- SEO tags rendered via `{% seo %}` in `_layouts/brand.html`.
- Minimal JavaScript and optimized SVG placeholders keep initial load light.
- Smooth scrolling enabled via CSS.
