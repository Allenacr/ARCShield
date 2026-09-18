# Essentials — Bidirectional Transaction Guard

One page. Everything you need to explain the project in thirty seconds or field a hard question from a judge.

## The pitch, in one breath

Every other fraud system asks whether you should be allowed to *send* money. This one also asks whether you should be allowed to *receive and use* it — because money from a cybercrime trail routinely lands in ordinary accounts, gets spent, and turns the receiver into a suspect months later. This gives them a way to say "not mine" before that happens, and proves they said it.

## The headline feature

**Quarantine.** An unexpected credit can be held for 24 hours in a real ledger: `available_balance` drops, `held_balance` rises, any spend attempt against the held amount is refused. A timestamped, tamper-evident evidence record is created showing the holder flagged the money before touching it — not a claim of legal innocence, a record of proactive action.

## The one diagram

```
MONEY OUT: behaviour drift, event sequence, recipient graph, coercion, structuring
MONEY IN:  unknown sender, pass-through speed, fan-in/out, dormancy break,
           income mismatch, complaint proximity, refund bait
                              │
                   RISK FUSION ENGINE (model + rules)
                              │
              LOW → allow   MEDIUM → challenge   HIGH → hold + case
```

## What makes each risk decision, exactly

- **One ML model** (XGBoost/LightGBM) over all feature families — behaviour, sequence, graph, device, session.
- **Deterministic rules**, separately, for anything that shouldn't be left to statistics: velocity, structuring, coercion answers, pass-through thresholds.
- **Fusion** combines both into a risk band and an ordered, human-readable reason list. SHAP explains the model's part; a counterfactual slider lets an analyst re-run the score with one field changed.

## Scope boundary — say this before you're asked

Fully simulated financial environment: accounts, ledgers, devices, sessions, complaints, three virtual banks. Every feature is genuinely functional inside it. **No connection to real UPI rails or a real bank core** — it cannot freeze real money without a payment-provider integration. This honesty is what makes the rest of the architecture credible.

## The five demo scenarios

| # | Scenario | What it proves |
|---|---|---|
| 1 | Quiet, normal payment | System isn't a smoke alarm that fires at toast |
| 2 | Account takeover (new device → password change → new payee → escalating transfers) | Sequence detection, not just amount |
| 3 | Manipulated payment — everything technically clean | Coercion questions catch what no signal can |
| 4 | Structuring — payments just under a limit | Deterministic rule, not left to the model |
| 5 | **Unexpected money arrives → Hold → spend refused → case opens** | The closer. Nobody sent a rupee; a crime was still interrupted |

## Numbers to have ready

- Warm scoring latency target: **under 200 ms** (quoted warm only — free-tier hosting sleeps and a cold first call is not representative)
- Alert reaches the device: **under 3 seconds**
- False-positive rate target on normal traffic: **under 2%**
- Every alert carries **at least one** human-readable reason code

## The two honest limits, memorised

1. **Not connected to real payment rails.** Simulated environment throughout; stated up front, not discovered.
2. **Hashed cross-bank identifiers are linkable by design** if banks share a salt, and brute-forceable for short identifier spaces. It demonstrates the privacy-preserving *pattern*, not a proof of anonymity.

## The line that closes the pitch

> "Nobody sent a rupee, and a crime was still interrupted."

## If asked "what's actually novel here"

Not the algorithm — graph-based detection, behavioural models and explainable AI are all established research and production practice. The contribution is **incoming-money protection** and the **quarantine mechanism**: giving an ordinary account holder proof that they refused money before it became their legal problem. That product doesn't exist in the market today.

## Where to look for more

- Full requirements + acceptance criteria for every feature → `PRD.md`
- Data model, feature engineering, ledger semantics, security, build order → `ARCHITECTURE.md`
- Project overview and repo layout → `README.md`
