---
layout: single
title: JainKwiz
permalink: /jainkwiz/
---

# JainKwiz

A modern, gamified learning platform that makes Jain philosophy accessible, engaging, and interactive for the global Jain community.

**Live at**: [jainkwiz.com](https://jainkwiz.com)

---

## The Problem

The Jain community has a rich tradition of religious education through Pathshalas (community schools). Children learn Jain scripture, history, philosophy, and practice — but mostly through textbooks and rote memorisation.

The challenges are real:
- **Engagement gap**: Traditional methods struggle to hold the attention of digital-native younger generations
- **Geographic fragmentation**: Jain communities are spread across India, UK, USA, Kenya, Singapore — education cannot be hyper-local
- **Content accessibility**: High-quality Jain educational content is mostly in Gujarati or Hindi, creating barriers for diaspora communities
- **No feedback loops**: Students and teachers have limited visibility into learning progress and knowledge gaps
- **Inconsistent quality**: Education quality varies significantly by Pathshala and teacher

---

## The Solution

JainKwiz transforms Jain education into an interactive, competitive, and globally accessible experience — using the same engagement patterns as Duolingo, Kahoot, and Khan Academy, applied to authentic Jain content.

The core product loop:
1. **Learn** — structured question sets with explanations, categorised by topic and difficulty
2. **Practice** — adaptive review based on spaced repetition (SM-2 algorithm)
3. **Compete** — real-time multiplayer tournaments with friends or global community
4. **Progress** — XP, levels, streaks, badges, and leaderboard rankings
5. **Explore** — AI chatbot for deeper questions, Jain festival calendar, glossary

---

## Features

### Quiz Engine
- 500+ questions across 8 categories: Bhagwan Mahavir, Tirthankaras, Jain History, Philosophy & Principles, Paryushana & Festivals, Jain Shlokas, Saints & Sadhus, Community & Culture
- Multiple question formats: multiple choice, true/false, image-based
- Difficulty levels: Beginner, Intermediate, Advanced
- Detailed explanations for every answer — not just correct/incorrect feedback

### Gamification
- **XP & Levels**: Earn experience points for every quiz, tournament, and daily activity
- **Daily Streaks**: Consecutive days of activity unlock streak bonuses and badges
- **Badges**: Achievement badges for milestones (First Quiz, 7-Day Streak, Tournament Winner, etc.)
- **Leaderboards**: Global all-time, weekly, and friends-only rankings
- **Spaced Repetition**: SM-2 algorithm schedules reviews based on individual performance

### Live Tournaments
- Real-time multiplayer quiz sessions (2–50 participants)
- Synchronised question delivery via Azure SignalR — all players see the same question simultaneously
- 15-second countdown timer per question
- Live score updates and final results screen
- Tournament scheduling with shareable invite links

### AI Learning Assistant
- Azure OpenAI (GPT-4o) chatbot for Jain philosophy questions
- Grounded on a curated knowledge base of Jain texts — not general internet knowledge
- Supports questions in English and Hindi
- Citations and sources provided with every answer
- Contextually aware: knows what the user has been studying

### Community Features
- Jain festival calendar with descriptions, dates, and significance
- Jain glossary (Paryushana, Aryika, Samayik, Pratikraman, etc.)
- Community question contribution (moderated by trusted reviewers)
- Pathshala classroom mode (coming soon): teacher dashboard, student roster, assigned quizzes

### Progressive Web App
- Installable on iOS and Android home screens — no app store required
- Offline mode for studying without internet connectivity
- Push notifications for daily streaks and tournament reminders
- Mobile-first responsive design

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      FRONTEND (PWA)                         │
│              React + Ionic + TypeScript                     │
│         Azure Static Web Apps (CDN-distributed)            │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS
          ┌──────────────┴──────────────┐
          │                             │
    ┌─────▼──────┐               ┌──────▼─────┐
    │  REST API  │               │  SignalR   │
    │  (Node.js  │               │  (Azure    │
    │  Azure Fn) │               │  SignalR   │
    └─────┬──────┘               │  Service)  │
          │                      └──────┬─────┘
    ┌─────▼──────────────────────────── │ ──────┐
    │              BACKEND              │       │
    │                                   │       │
    │  ┌──────────┐   ┌─────────────┐  │       │
    │  │ Cosmos DB│   │ Azure OpenAI│◄─┘       │
    │  │(NoSQL)   │   │ (GPT-4o +   │          │
    │  └──────────┘   │  Embeddings)│          │
    │                 └─────────────┘          │
    │  ┌──────────┐   ┌─────────────┐          │
    │  │Azure Blob│   │ Azure AI    │          │
    │  │(Media)   │   │ Search(RAG) │          │
    │  └──────────┘   └─────────────┘          │
    └───────────────────────────────────────────┘
```

### Component Breakdown

**Frontend: React + Ionic**
- React 18 with TypeScript for component logic
- Ionic Framework for native-quality mobile UI components
- Capacitor for future App Store / Play Store packaging
- TanStack Query for server state management and caching
- Zustand for client-side gamification state

**Real-time: Azure SignalR Service**
- Serverless mode — no persistent server required
- Azure Functions bindings for negotiation and message broadcast
- Group-based message routing: each tournament is a SignalR group
- Handles WebSocket fallback to long-polling automatically
- Scales to thousands of concurrent connections without configuration

**Backend: Node.js on Azure Functions**
- HTTP-triggered functions for REST API endpoints
- Timer-triggered functions for scheduled tasks (streak resets, leaderboard aggregation)
- Event-driven functions for tournament state management
- Managed Identity for secure access to Cosmos DB and Key Vault

**Database: Azure Cosmos DB**
- NoSQL document store — schema-flexible for evolving quiz content
- Partition keys designed for query patterns, not just data structure
- Serverless tier for cost efficiency at current scale
- Change feed for real-time tournament event processing

**AI: Azure OpenAI + Azure AI Search**
- GPT-4o for conversational AI assistant
- `text-embedding-3-large` for knowledge base embeddings
- Azure AI Search for hybrid vector + keyword retrieval
- Curated Jain knowledge base (manually reviewed for accuracy)

**Hosting: Azure Static Web Apps**
- Global CDN distribution — fast load times regardless of geography
- Integrated authentication (Azure AD B2C for social login)
- Staging environments for pre-release testing
- Free tier supports current traffic volume

---

## Gamification Design

The gamification system is built on established learning science principles:

**XP Formula:**
```
Base XP = difficulty_multiplier × correct_answers
Streak Bonus = base_xp × (0.1 × min(streak_days, 10))
Tournament Bonus = base_xp × position_multiplier
Daily XP = quiz_xp + streak_bonus + tournament_bonus
```

**Level Thresholds:**
Levels follow an exponential curve — early levels are achievable quickly to build momentum, later levels require sustained engagement.

**Spaced Repetition (SM-2):**
Questions are scheduled for review based on performance:
- Incorrect answer → review tomorrow
- Correct with hesitation → review in 3 days
- Confident correct answer → review in 7, 14, 30... days (geometric growth)

This means users spend their time on questions they actually need to practice, not questions they already know perfectly.

---

## Content Strategy

Building the question database was as challenging as building the technology:

**Content categories:**
1. **Bhagwan Mahavir** — life, teachings, Kalyanakas
2. **24 Tirthankaras** — identities, symbols, shrines
3. **Jain History** — key events, empires, councils, eras
4. **Philosophy & Principles** — Anekantavada, Syadvada, Ahimsa, Aparigraha, Asteya
5. **Paryushana & Festivals** — Diwali, Paryushana, Mahavir Jayanti, Akshaya Tritiya
6. **Jain Shlokas** — Navkar Mantra, Uvasaggaharam, Bhaktamar
7. **Saints & Sadhus** — Acharya, Upadhyaya, Muni, Aryika, notable saints
8. **Community & Culture** — Pathshala, Jain organisations, customs, food, terminology

**Quality process:**
- Questions drafted by content contributors with Jain education background
- Expert review by community scholars before publication
- Regional variation notes where applicable (Digambara vs. Shvetambara differences)
- Regular updates for factual accuracy and new content

---

## Cost Architecture

Building JainKwiz as a self-funded side project required genuine cost discipline:

| Service | Tier | Monthly Cost |
|---------|------|-------------|
| Azure Static Web Apps | Free | $0 |
| Azure Functions | Consumption | ~$2–5 |
| Cosmos DB | Serverless | ~$3–8 |
| Azure SignalR | Free (20K messages/day) | $0 |
| Azure OpenAI | Pay-per-use | ~$5–15 |
| Azure AI Search | Free (50MB index) | $0 |
| Azure Blob Storage | Pay-per-use | ~$1 |
| **Total** | | **~$11–29/month** |

The architecture was intentionally designed to fit within Azure free tiers and serverless consumption models. This is not a limitation — it is a demonstration that enterprise architecture patterns can be applied cost-effectively at any scale.

---

## Learnings & What I Would Do Differently

**What worked well:**
- Azure SignalR Service for real-time — zero ops burden, auto-scaling, clean SDK
- Cosmos DB partition key design — got this right early and have not regretted it
- PWA approach — removes app store friction and enables instant updates
- SM-2 spaced repetition — users notice the adaptive quality even without knowing the algorithm

**What I underestimated:**
- Content creation complexity — building a high-quality question database took longer than the entire quiz engine
- User onboarding friction — the first version had too many steps before a new user reached their first question
- Hindi language support — localisation is not just translation; it requires cultural adaptation of the entire UX
- Push notification permissions — iOS requires careful handling and a clear user value proposition before requesting

**What I would do differently:**
- Start with a teacher-facing product, not a learner-facing product — teachers are the content distribution channel in the Pathshala ecosystem
- Build the community contribution workflow from week one — content quality scales with community involvement
- Invest in analytics earlier — understanding where users drop off is more valuable than adding new features

---

## Roadmap

**Q2 2026 (In Progress)**
- Live tournament front-end (SignalR integration complete, UI in progress)
- Hindi language support across the full app

**Q3 2026**
- Pathshala classroom mode — teacher dashboard, student roster, assignment creation
- Mobile apps on Play Store / App Store via Capacitor
- Advanced AI tutor: adaptive study plans based on quiz history

**Q4 2026**
- Tournament seasons with prizes and community recognition
- Video integration for Pathshala sessions
- API for Pathshala management system integrations

---

## Get Involved

JainKwiz is built for the Jain community, by the community.

**Want to contribute questions?** — Reach out if you have subject-matter expertise in Jain philosophy, history, or culture. The question review process takes approximately 30 minutes per set.

**Running a Pathshala?** — I am building the classroom mode specifically for Pathshala teachers. If you would like to be an early tester, please get in touch.

**Have feedback?** — Every piece of feedback directly influences the product roadmap. lovyjain18@gmail.com or LinkedIn.

---

JainKwiz represents the intersection of **technology, culture, and community impact** — proof that enterprise architecture skills can build products that matter beyond the enterprise.

[Visit JainKwiz →](https://jainkwiz.com)
