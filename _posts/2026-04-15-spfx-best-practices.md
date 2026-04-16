---
title: "SPFx Development Best Practices: Hard-Won Lessons from Production SharePoint Projects"
date: 2026-04-15
layout: single
categories: [sharepoint, spfx, microsoft365]
tags: [SPFx, SharePoint Online, React, TypeScript, M365, Microsoft Graph, Performance]
---

## Introduction

SharePoint Framework (SPFx) is the modern way to extend SharePoint Online, Microsoft Teams, and Microsoft Viva Connections. After building SPFx solutions for clients including global financial organisations, logistics companies, and pharmaceutical firms — ranging from simple web parts to complex intranet platforms — I have a clear set of practices that separate production-quality work from prototype-quality work.

This post covers what I actually do in projects, not what the documentation suggests.

---

## Project Structure That Scales

Most tutorials show you a single web part in a single file. Real projects have multiple web parts, shared components, custom hooks, and services. Your structure needs to support this from day one.

```
src/
├── webparts/
│   ├── myDashboard/
│   │   ├── MyDashboardWebPart.ts      # SPFx entry point
│   │   ├── components/
│   │   │   ├── MyDashboard.tsx        # Root component
│   │   │   ├── MyDashboard.module.scss
│   │   │   └── widgets/
│   │   │       ├── AnnouncementWidget.tsx
│   │   │       └── TaskWidget.tsx
│   │   └── hooks/
│   │       └── useDashboardData.ts
│   └── myForm/
│       └── ...
├── shared/
│   ├── components/               # Reusable UI components
│   │   ├── LoadingSpinner.tsx
│   │   ├── ErrorBoundary.tsx
│   │   └── UserCard.tsx
│   ├── hooks/                    # Shared custom hooks
│   │   ├── useGraphClient.ts
│   │   └── usePnP.ts
│   ├── services/                 # API and data services
│   │   ├── GraphService.ts
│   │   ├── SharePointService.ts
│   │   └── CacheService.ts
│   ├── models/                   # TypeScript interfaces
│   │   ├── IUser.ts
│   │   └── IAnnouncement.ts
│   └── utils/
│       ├── dateUtils.ts
│       └── permissions.ts
└── extensions/
    └── ...
```

The `shared/` folder is the key. Any code used by more than one web part lives there. This prevents duplication and makes updates — especially to API services — a single change rather than a hunt across multiple web parts.

---

## TypeScript — Use It Properly

SPFx has always supported TypeScript, but many codebases I inherit treat it like JavaScript with optional types. This misses the core benefit: catching errors at build time, not at runtime in production.

**Rules I enforce:**

```typescript
// tsconfig.json additions
{
  "compilerOptions": {
    "strict": true,           // Enable all strict checks
    "noImplicitAny": true,    // No implicit any types
    "strictNullChecks": true, // Null and undefined must be handled explicitly
    "noUnusedLocals": true    // Catch dead code
  }
}
```

**Model every API response:**

```typescript
// Don't do this
const getData = async (): Promise<any> => { ... }

// Do this
interface ISharePointListItem {
  Id: number;
  Title: string;
  Author: { Title: string; EMail: string };
  Created: string;
  Modified: string;
}

const getData = async (): Promise<ISharePointListItem[]> => { ... }
```

When a SharePoint column is renamed or removed, TypeScript will tell you at compile time. Without types, you find out when a production user sees `undefined` in their browser.

---

## Microsoft Graph and PnPjs: Know When to Use Each

This is a question I get asked constantly. Both can access SharePoint data — the difference is about what you are doing:

| Use Case | Recommended |
|----------|-------------|
| SharePoint lists, libraries, items | PnPjs (much simpler API) |
| User profiles, Groups, Teams | Microsoft Graph |
| Teams app context | Microsoft Graph |
| Permissions, roles, policies | Microsoft Graph |
| Caml/FetchXML queries | PnPjs |
| Files and folders | PnPjs (wraps Graph internally) |

```typescript
// PnPjs: clean, typed, handles pagination automatically
import { spfi, SPFx } from "@pnp/sp";
import "@pnp/sp/lists";
import "@pnp/sp/items";

const sp = spfi().using(SPFx(this.context));

const items = await sp.web.lists
  .getByTitle("Announcements")
  .items
  .select("Id", "Title", "Body", "ExpiryDate")
  .filter("ExpiryDate ge datetime'" + new Date().toISOString() + "'")
  .orderBy("Created", false)
  .top(10)();

// Microsoft Graph: for M365 user data
import { MSGraphClientV3 } from "@microsoft/sp-http";

const client: MSGraphClientV3 = await this.context.msGraphClientFactory.getClient("3");
const me = await client.api("/me").select("displayName,mail,department").get();
```

---

## Performance: The Problems Nobody Talks About

SPFx web parts run in an iFrame inside SharePoint. Every API call adds latency. Here is where performance is lost and how to recover it:

### Problem 1: Waterfall API Calls

```typescript
// BAD: sequential — each call waits for the previous
const user = await getUser();
const items = await getItems(user.id);
const metadata = await getMetadata(items[0].id);

// GOOD: parallel where possible
const [user, recentItems] = await Promise.all([
  getUser(),
  getRecentItems()
]);
const details = await getDetails(user.id, recentItems[0].id);
```

### Problem 2: No Caching

SharePoint API calls from SPFx are expensive in latency terms. Cache aggressively for data that does not need to be real-time.

```typescript
class CacheService {
  private static cache = new Map<string, { data: unknown; expiry: number }>();
  
  static async get<T>(
    key: string, 
    fetcher: () => Promise<T>, 
    ttlSeconds: number = 300
  ): Promise<T> {
    const cached = this.cache.get(key);
    if (cached && cached.expiry > Date.now()) {
      return cached.data as T;
    }
    
    const data = await fetcher();
    this.cache.set(key, { data, expiry: Date.now() + ttlSeconds * 1000 });
    return data;
  }
}

// Usage
const announcements = await CacheService.get(
  'announcements',
  () => sp.web.lists.getByTitle("Announcements").items.top(10)(),
  300 // 5 minute cache
);
```

### Problem 3: Rendering Everything on Load

Use lazy loading for below-the-fold content. SPFx web parts are often positioned low on long SharePoint pages — do not fetch data until the user scrolls to them.

```tsx
const IntersectionWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [isVisible, setIsVisible] = React.useState(false);
  const ref = React.useRef<HTMLDivElement>(null);
  
  React.useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) setIsVisible(true); },
      { threshold: 0.1 }
    );
    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, []);
  
  return <div ref={ref}>{isVisible ? children : <Skeleton />}</div>;
};
```

---

## Permissions and Security Content Security Policy (CSP)

SharePoint Online enforces a strict Content Security Policy (CSP). This breaks web parts that try to load external resources — scripts, fonts, images, API calls — without proper configuration.

**Common CSP violations I see in production:**

- Inline styles set via JavaScript (`element.style.cssText = ...`)
- External Google Fonts loaded via `<link>` in web part HTML
- Direct calls to third-party APIs without proper CORS headers

**Solutions:**

```typescript
// Use CSS modules or SCSS — never inline styles
import styles from './MyWebPart.module.scss';
// <div className={styles.container}>...

// Load external fonts via the SPFx loadScript API, not inline
import { SPComponentLoader } from "@microsoft/sp-loader";

SPComponentLoader.loadCss("https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap");
```

For custom API endpoints, configure CORS properly on your Azure Function or API:

```csharp
// Azure Function CORS (via host.json or Azure Portal)
// host.json
{
  "extensions": {
    "http": {
      "routePrefix": "api",
      "cors": {
        "allowedOrigins": [
          "https://<tenant>.sharepoint.com"
        ]
      }
    }
  }
}
```

---

## Error Handling and Telemetry

Production SPFx web parts must handle errors gracefully and surface actionable information. A blank white box with no explanation destroys user trust.

```tsx
class ErrorBoundary extends React.Component<
  { children: React.ReactNode; webPartTitle: string },
  { hasError: boolean; error?: Error }
> {
  state = { hasError: false };
  
  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }
  
  componentDidCatch(error: Error, info: React.ErrorInfo) {
    // Log to Application Insights
    appInsights.trackException({ 
      exception: error,
      properties: { webPart: this.props.webPartTitle, componentStack: info.componentStack }
    });
  }
  
  render() {
    if (this.state.hasError) {
      return (
        <div className={styles.errorState}>
          <Icon iconName="ErrorBadge" />
          <Text>Something went wrong loading {this.props.webPartTitle}.</Text>
          <Text variant="small">Please refresh the page or contact support.</Text>
        </div>
      );
    }
    return this.props.children;
  }
}
```

I connect every production SPFx solution to Azure Application Insights. Page load times, API call durations, and JavaScript exceptions are tracked automatically. When a client reports "the web part is broken," I can pinpoint the cause before they finish the sentence.

---

## Deployment and Solution Packaging

**Always use tenant-scoped deployment for shared components.** Site-scoped deployment requires manual activation on every site — this is unmaintainable at scale.

In `package-solution.json`:

```json
{
  "solution": {
    "name": "ACME-Intranet",
    "id": "...",
    "version": "1.0.0.0",
    "includeClientSideAssets": true,
    "skipFeatureDeployment": true    // Tenant-wide deployment
  },
  "paths": {
    "zippedPackage": "solution/acme-intranet.sppkg"
  }
}
```

**Versioning**: Increment the version in `package-solution.json` on every deployment. SharePoint uses this to decide whether to update cached assets. Without version bumps, users may see stale JavaScript long after you deploy a fix.

---

## Accessibility

SharePoint intranets serve everyone — including users with accessibility needs. SPFx solutions are subject to WCAG 2.1 AA requirements at most enterprise clients.

Non-negotiables I include in every project:

```tsx
// Keyboard navigation and ARIA labels
<button
  aria-label="Open announcements panel"
  onClick={openPanel}
  onKeyDown={(e) => e.key === 'Enter' && openPanel()}
>
  <Icon iconName="News" aria-hidden="true" />
</button>

// Focus management when panels open
React.useEffect(() => {
  if (isPanelOpen) {
    panelTitleRef.current?.focus();
  }
}, [isPanelOpen]);

// Sufficient colour contrast — use Fluent UI theme tokens
// Don't hard-code colors; use var(--neutralPrimary) etc.
```

Run Accessibility Insights for Web (Microsoft's free tool) on every web part before release. It catches the majority of issues before a manual audit.

---

## A Note on Keeping Up

SPFx evolves rapidly. The team ships major framework updates that change how properties, contexts, and APIs work. The mistakes I see most often in inherited projects:

- Using deprecated `sp-pnp-js` v2 (current is `@pnp/sp` v4)
- Using the old `GraphHttpClient` instead of `MSGraphClientV3`
- Not updating the SPFx yeoman generator before scaffolding new projects

Sign up for the [Microsoft 365 Developer Blog](https://devblogs.microsoft.com/microsoft365dev/) and the [SPFx release notes](https://learn.microsoft.com/en-us/sharepoint/dev/spfx/roadmap). SPFx updates rarely break existing solutions — but staying current means accessing performance improvements and new APIs as they ship.

---

## Conclusion

SPFx development at enterprise scale requires disciplined structure, typed APIs, performance awareness, and production-grade error handling from the start. The shortcuts that seem convenient during development always surface as maintenance problems after go-live.

The best SPFx codebase I have worked on had these properties: a clear shared component library, every API call cached appropriately, full TypeScript coverage, and Application Insights on every production deployment. When something broke, we found it in our monitoring before the client found it in production. That is the standard to aim for.
