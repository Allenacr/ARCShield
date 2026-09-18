# Bidirectional Transaction Guard

Real-time financial fraud detection that scores money in both directions — what an account sends, and what it receives.

**Problem statement:** FC-05, with a bridge into FC-01 (privacy-preserving inter-institution intelligence).

Full requirements: [`PRD.md`](./PRD.md)
Full system design: [`ARCHITECTURE.md`](./ARCHITECTURE.md)
One-page cheat sheet for a fast recap or a judge Q&A: [`ESSENTIALS.md`](./ESSENTIALS.md)

---

## What this is

Most fraud systems ask one question: *should this person be allowed to send this money?*

This one adds a second, barely-served question: *should this person be allowed to receive and use this money?*

That second question matters because money from a cybercrime trail routinely lands in ordinary accounts. The holder spends it, and months later the account is frozen while investigators trace the funds — even though the holder stole nothing. No consumer banking app today gives that person a way to say "I don't recognise this money, don't let me touch it." This platform gives them that action, records it, and turns it into evidence.

```
                    TRANSACTION
                         │
           ┌─────────────┴─────────────┐
      MONEY OUT                    MONEY IN
           │                           │
 Behaviour drift              Unknown sender
 Event sequence               Pass-through speed
 Recipient graph              Fan-in / fan-out
 Device + session             Dormancy break
 Structuring                  Income mismatch
 Coercion answers             Complaint proximity
                              Refund bait
           └─────────────┬─────────────┘
                          ▼
                 RISK FUSION ENGINE
                          ▼
          LOW          MEDIUM          HIGH
         Allow       Challenge     Hold + Case
```

The headline feature is **Quarantine**: an unexpected credit can be held for 24 hours in a real, functional ledger — `available_balance` drops, `held_balance` rises, and any attempt to spend the held amount is refused — while a timestamped evidence record is built for an investigator.

## Scope boundary

This runs as a complete simulated financial environment: accounts, ledgers, devices, sessions, complaints, and three virtual banks. Every feature works inside that simulation. It does **not** connect to NPCI, UPI rails, or a real bank core, and it cannot freeze real money without a bank or payment-provider integration. Stated here, not discovered later.

## Stack

| Layer | Choice |
|---|---|
| Data generation | Python |
| API | FastAPI |
| Model | XGBoost / LightGBM + SHAP |
| Graph | NetworkX |
| Database | Supabase (Postgres, Auth, RLS, Realtime) |
| Analyst dashboard | React + TypeScript |
| Mobile app | Flutter + Firebase Cloud Messaging |
| Hosting | Vercel (frontend), Render (backend), Supabase (data) |

## Repository layout

```
/generator        synthetic world, seeded fraud scenarios, deterministic seeds
/features          feature builders, shared between training and serving
/models            training, evaluation, SHAP, model registry
/graph             NetworkX service, graph features, subgraph snapshots
/api               FastAPI: ingestion, scoring, actions, counterfactual
/rules             deterministic rule engine and thresholds
/db                schema, enums, RLS policies, triggers, migrations
/federated         virtual banks, coordinator, hashed indicator service
/dashboard         React + TypeScript analyst UI
/app               Flutter user app
/docs              PRD, architecture, demo script, evaluation results
```

## Build order

1. Synthetic world generator, with event-level fraud labels
2. Database schema, ledger, RLS
3. Feature builders (outgoing + incoming)
4. Graph service
5. Risk model + SHAP
6. Rule engine + fusion
7. Scoring API
8. Ledger + quarantine — the product's core mechanism
9. Realtime + push notifications
10. Analyst dashboard
11. Flutter app
12. Beneficiary trust ladder
13. Inter-bank hashed intelligence
14. Federated learning simulation
15. Feedback loop + monitoring
16. Deploy and seed

Steps 1–8 are the product. Nothing after step 8 is worth starting before step 8 is solid. Full detail in `ARCHITECTURE.md` §13.

## Demo, in five scenarios

1. **Quiet** — ordinary payment, no alert.
2. **Account takeover** — new device, password change, new payee, escalating transfers. Flagged on the *sequence*.
3. **Manipulated payment** — every technical signal clean; coercion answers ("urgent," "safe account") push it to HIGH.
4. **Structuring** — several payments just under a limit, caught by a deterministic rule.
5. **Unexpected money (closer)** — a stranger's credit arrives, the user taps Hold, the balance splits, a spend attempt is refused, and a case opens with the evidence trail.

Full script with acceptance detail: `PRD.md` §8.

## Positioning

> Outgoing fraud detection asks, *are you sending money to the wrong person?*
> Incoming protection asks, *why did money from the wrong person enter your account, and what can you do before it becomes your problem?*

The second question is the product, not a new algorithm — graph detection, behavioural modelling and explainable risk are all established elsewhere.
