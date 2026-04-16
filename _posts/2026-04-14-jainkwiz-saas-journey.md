---
title: "JainKwiz: What Building a SaaS Product Taught Me That Enterprise Work Never Did"
date: 2026-04-14
last_modified_at: 2026-04-14
layout: single
author_profile: true
read_time: true
show_date: true
toc: true
toc_label: "Contents"
toc_sticky: true
categories:
  - product
  - saas
  - azure
tags:
  - JainKwiz
  - SaaS
  - Azure
  - Product Development
  - Entrepreneurship
  - SignalR
  - Cosmos DB
excerpt: "The architecture, product decisions, and hard lessons from building a gamified Jain learning platform from zero to production as a solo founder."
---

## Introduction

After 13 years of building enterprise software for other people's organisations, I did something that felt both obvious and terrifying: I built something of my own.

[JainKwiz](https://jainkwiz.com) is a gamified learning platform for Jain philosophy — real-time multiplayer quiz tournaments, leaderboards, AI-assisted learning, and a progressive web app that runs beautifully on any device. It is live, it has real users, and it has taught me more about software product thinking in one year than most of my enterprise career combined.

This is the story of that build — the architecture choices, the surprises, and the lessons that changed how I think about software.

---

## Why JainKwiz?

The Jain community has a rich tradition of religious education through Pathshalas (community schools). Children learn Jain scripture, history, philosophy, and practice — but mostly through textbooks, rote memorisation, and periodic tests. Engagement is a constant challenge, especially for younger generations growing up with smartphones and short attention spans.

I saw a real problem: meaningful content, motivated teachers, but a delivery mechanism stuck in the 1980s. The technology to fix this already existed. I just needed to build the bridge.

The mission became clear: make Jain education as engaging as Duolingo and as competitive as a game, while preserving the depth and authenticity of the tradition.

---

## Architecture Decisions (and Why I Made Them)

### Frontend: React + Ionic

I chose React with Ionic because I needed one codebase that could serve a mobile-quality experience on both iOS-like and Android-like surfaces, plus the web — without going the full React Native route with its native build complexity.

Ionic gives you native-feeling UI components (bottom tabs, swipeable sheets, haptic feedback patterns) that compile as a Progressive Web App. Users install JainKwiz to their home screen and get an experience that feels native. No app store friction. No review delays. Instant updates.

```tsx
// Tournament lobby with real-time participant list
const TournamentLobby = ({ tournamentId }: Props) => {
  const { participants, isConnected } = useSignalR(tournamentId);
  
  return (
    <IonPage>
      <IonContent>
        <ParticipantList participants={participants} />
        <ConnectionStatus connected={isConnected} />
        {isHost && <StartTournamentButton tournamentId={tournamentId} />}
      </IonContent>
    </IonPage>
  );
};
```

**What I would change**: I underestimated the complexity of managing Ionic's navigation stack alongside React Router. If I were starting again I would evaluate whether a simple React + Tailwind PWA would have been simpler to maintain without meaningfully sacrificing UX quality.

### Real-time: Azure SignalR Service

The live tournament feature — where 20 people simultaneously answer the same question within a 15-second window — required genuine real-time infrastructure. I evaluated WebSocket libraries, Pusher, Socket.io (self-hosted), and Azure SignalR.

Azure SignalR won because:
- Serverless mode integrates cleanly with Azure Functions (no persistent server required)
- It scales automatically across WebSocket connections
- The Azure Functions trigger/binding system handles negotiation and message dispatch without boilerplate
- It fits the Azure Free tier for development and is cost-predictable in production

```csharp
// Azure Function: broadcast next question to tournament room
[FunctionName("BroadcastQuestion")]
public static async Task Run(
    [TimerTrigger("*/15 * * * * *")] TimerInfo timer,
    [SignalR(HubName = "tournament")] IAsyncCollector<SignalRMessage> signalRMessages,
    ILogger log)
{
    var activeTournaments = await _tournamentService.GetActiveAsync();
    
    foreach (var tournament in activeTournaments)
    {
        var nextQuestion = await _questionService.GetNextAsync(tournament.Id);
        
        await signalRMessages.AddAsync(new SignalRMessage
        {
            GroupName = tournament.Id,
            Target = "nextQuestion",
            Arguments = new[] { nextQuestion }
        });
    }
}
```

### Database: Cosmos DB

I chose Cosmos DB because the data access patterns for JainKwiz are heavily read-biased and document-oriented:

- Quiz questions with rich metadata (category, difficulty, language, tags)
- User profiles with gamification state (XP, level, streak, badges)
- Tournament sessions with participant lists and scores
- Leaderboard snapshots at weekly and global scopes

The partition key design was the hardest decision. I ended up with:

| Container | Partition Key | Reasoning |
|-----------|-------------|-----------|
| `questions` | `/category` | Queries always filter by category |
| `users` | `/userId` | Single-user reads dominate |
| `tournaments` | `/tournamentId` | All operations scoped to one tournament |
| `leaderboard` | `/period` | Weekly vs. global isolation |

Cosmos DB's free tier (1000 RU/s, 25GB) covers JainKwiz's current scale comfortably. The serverless tier is an option for bursty workloads — I am evaluating the switch for the seasonal event peaks (Paryushana, Diwali).

### Gamification: SM-2 Spaced Repetition

One feature I am particularly proud of is the spaced repetition engine built on the SM-2 algorithm. Rather than showing users random questions, JainKwiz adapts to their performance — questions they struggle with appear more frequently; mastered questions space out over days and weeks.

```javascript
function calculateNextReview(card, quality) {
  // quality: 0-5 (0=blackout, 5=perfect)
  if (quality < 3) {
    return { interval: 1, easeFactor: Math.max(1.3, card.easeFactor - 0.2) };
  }
  
  const newEaseFactor = card.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  const newInterval = card.repetitions === 0 ? 1
    : card.repetitions === 1 ? 6
    : Math.round(card.interval * newEaseFactor);
  
  return {
    interval: newInterval,
    easeFactor: Math.max(1.3, newEaseFactor),
    repetitions: card.repetitions + 1,
    nextReview: addDays(new Date(), newInterval)
  };
}
```

Users do not know they are interacting with an algorithm — they just feel like JainKwiz "knows" what they need to study. That invisibility is good product design.

---

## What Enterprise Work Did Not Prepare Me For

### 1. You are the product manager, designer, developer, and support team

In enterprise work, there is always a business analyst, a project manager, a dedicated designer, and a QA team. Building JainKwiz solo meant making every product decision myself — and living with the consequences.

The hardest decisions were not technical. They were:
- Which features to build first (and which 20 features to say no to)
- How to structure the onboarding so a 12-year-old from Jalgaon can use it without instructions
- Whether to add Hindi language support immediately or defer it

These decisions have no correct answer and no senior stakeholder to escalate to. You just decide, ship, and learn.

### 2. Real users are brutally honest

Enterprise users are polite in feedback sessions. Real users either use your app or they do not. Retention numbers tell you the truth that user interviews sometimes hide.

My first version had a beautiful UI but the quiz flow had three taps too many before reaching the first question. Retention at day 3 was poor. I removed the friction, retention improved. No amount of stakeholder presentations would have taught me that — only shipping and measuring did.

### 3. Cost is not a rounding error

In enterprise projects, cloud spend is somebody else's budget line. When it is your Azure subscription and your credit card, every resource decision becomes real.

I rewrote my indexing pipeline three times to reduce Azure Function invocation costs. I switched from Azure Blob Storage triggers (which poll constantly) to Event Grid triggers (which fire only on change). I moved from Cosmos DB provisioned throughput to serverless to cut idle costs by 80%.

This cost-consciousness has made me a better architect for enterprise clients — I now challenge provisioned capacity assumptions that previously felt unimportant.

### 4. Content is as hard as code

Building the question database was underestimated. Good quiz questions require:
- Factual accuracy (which means expert review by community knowledge-holders)
- Appropriate difficulty calibration
- Language sensitivity (Jain terminology varies across regional traditions)
- Diversity of question format (not just multiple choice)

I ended up building a separate question editor and review workflow — effectively a mini CMS — so trusted community contributors can submit and review questions. This content infrastructure took longer than the gamification engine.

---

## The AI Layer

JainKwiz has an AI chatbot powered by Azure OpenAI (GPT-4o) that users can ask questions about Jain philosophy. The chatbot is grounded on a curated knowledge base of Jain texts and explanations — a RAG implementation similar to what I described in my earlier post on SharePoint RAG pipelines.

```
User: "What is the difference between Digambara and Shvetambara?"
Bot: [Retrieves relevant context from Jain knowledge base]
     "The Digambara and Shvetambara are the two main sects of Jainism..."
     [Cited from: Jain Philosophy Fundamentals, Chapter 3]
```

The grounding is critical — the general LLM has surface-level knowledge of Jainism but makes errors on specific philosophical points, canonical texts, and practice differences. The curated knowledge base corrects this.

---

## JainKwiz as a Mirror

The most unexpected outcome of building JainKwiz has been what it taught me about my enterprise work.

When I design a feature for JainKwiz, I am the user. I feel the friction. I experience the delight. I understand why decisions matter. In enterprise work, the feedback loop is longer and often filtered through multiple layers.

Building JainKwiz made me a better architect. I question default assumptions more. I care more about what users actually experience rather than what the requirements document says. I design for change because I know I will need to change things.

If you are an enterprise developer considering building something of your own — I strongly encourage it. Pick a problem you care about, keep the scope small, and ship something real. The learning per hour invested will astonish you.

---

## Current Status and What Is Next

JainKwiz is live at [jainkwiz.com](https://jainkwiz.com). Current features:

- [x] Quiz engine with 500+ questions across 8 categories
- [x] XP and level progression system
- [x] Daily streaks and reminders
- [x] Global and weekly leaderboards
- [x] AI chatbot (beta)
- [x] Jain festival calendar
- [x] PWA (installable on home screen)

In progress:

- [ ] Live multiplayer tournaments (SignalR backend complete, frontend integration underway)
- [ ] Hindi language support
- [ ] Pathshala classroom mode (teacher dashboard + student roster)
- [ ] Mobile apps on Play Store / App Store via Capacitor

The classroom mode is the feature I am most excited about. It will let Pathshala teachers create assignments, track student progress, and run live class quiz sessions — bringing the technology directly into the community education system it was built to serve.

---

## Conclusion

JainKwiz is my proof that an enterprise architect can build a real product, for real users, solving a real problem. It is not perfect — no product is. But it is live, it is growing, and it matters to the people who use it.

If you are from the Jain community and want to contribute questions, review content, or help with translations, please reach out. And if you want to know more about the technical architecture or the product journey, I would love to have that conversation.
