# Bidirectional Transaction Guard — Product Requirements

**Problem statement:** Problem Real-Time Financial Fraud Detection Engine Financial fraud can manifest through unusual combinations of transaction behaviour, account history, device characteristics, location and transaction velocity. A single transaction may appear legitimate when viewed in isolation. Build a real-time fraud-detection engine that analyses multiple behavioural and contextual signals to determine the risk associated with a transaction. The solution should demonstrate: Transaction behaviour. Account history. Device characteristics. Location patterns. Transaction velocity. Network relationships. The system should produce: A risk assessment. Reasoning/evidence for the assessment. A recommended action. Key challenge — Detect suspicious behaviour by considering the broader context and relationships around a transaction, rather than relying on isolated rules.

**Version:** 1.0 — full scope. No feature is deferred. Every item in this document is a build requirement.

---

## 1. What this is

A financial fraud platform that scores money in **both directions**.

Almost every fraud system asks one question: *should this person be allowed to send this money?* This platform asks that question and a second one that is barely served anywhere: *should this person be allowed to receive and use this money?*

The second question exists because of a real and common harm. Money from a cybercrime trail lands in an ordinary account. The account holder spends it. Weeks or months later the account is frozen and the holder is questioned as part of a criminal investigation. They stole nothing. Today no consumer banking app gives that person a way to say "I don't recognise this money, don't let me touch it."

This platform gives them that action, records it, and turns it into evidence.

---

## 2. Scope boundary (state this openly)

The platform runs a **complete simulated financial environment**: accounts, balances, ledgers, transfers, beneficiaries, devices, sessions, complaints and three virtual banks. Every feature is genuinely functional inside that environment.

It does **not** connect to NPCI, UPI rails, or any real bank core. It cannot freeze real money or stop a real payment without a bank or payment-provider integration.

This is stated up front in the pitch, not discovered by a judge. An honest boundary makes the architecture credible; a vague one destroys it.

---

## 3. Users

| Role | What they need |
|---|---|
| **Account holder** | To be warned before sending money to the wrong person, and to be protected from money arriving from the wrong person. Must be able to act in one tap. |
| **Fraud analyst** | To see live alerts, understand *why* the system scored something, inspect the entity graph, and work a case. |
| **Investigator** | To receive a held transaction as a case file with a complete, tamper-evident evidence trail. |
| **Administrator** | To manage models, rules, thresholds and inter-bank intelligence sharing. |

---

## 4. Core product concept

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

---

## 5. Feature requirements

Each feature below is a build requirement with acceptance criteria. "Done" means the criteria are demonstrable in the running system, not that the code exists.

### 5.1 Outgoing intelligence

**F-01 Behaviour drift**
Every account carries a rolling profile: 7-day and 30-day mean and standard deviation of amount, usual transaction hours, usual locations, usual devices, usual recipients, usual velocity, usual merchant categories.
The system scores deviation on each axis and, critically, scores *simultaneous* deviation across axes.
*Accepted when:* a ₹49,000 transfer at 03:17 to a new payee from a new device produces a higher drift score than the same amount at noon from the usual device to the usual payee, and the reason codes name which axes moved.

**F-02 Event-sequence detection**
Account events are first-class records, not just transactions: `LOGIN`, `LOGIN_NEW_DEVICE`, `PASSWORD_CHANGE`, `PROFILE_CHANGE`, `BENEFICIARY_ADDED`, `FAILED_AUTH`, `TRANSACTION`.
The feature builder converts recent event windows into binary and ordinal signals: `new_device_before_transfer`, `credential_change_before_transfer`, `new_beneficiary_before_transfer`, `escalating_amounts`, `rapid_sequence`, `failed_auth_before_success`.
*Accepted when:* the classic takeover chain (new device → password change → new beneficiary → ₹5k → ₹25k → ₹75k in six minutes) is flagged on the *sequence*, and the alert text names the order of events rather than the amount.

**F-03 Recipient network graph**
A graph over accounts, devices, UPI handles, phone numbers, IP addresses and merchants. Edges: `PAID`, `SHARES_DEVICE`, `SHARES_IDENTIFIER`, `SAME_SESSION`, `REPORTED_IN`.
Compact features are extracted and fed to the model — never the raw graph: `hops_to_flagged_account`, `shared_device_count`, `shared_identifier_count`, `connected_flagged_accounts`, `component_size`, `recipient_degree_24h`.
*Accepted when:* a transfer to a recipient with a clean personal history is still elevated because that recipient shares a device with flagged accounts, and the analyst can see the subgraph that caused it.

**F-04 Coercion check**
Before any transfer scored MEDIUM or above, the app asks the user two short questions: the purpose of the payment, and whether anyone asked them to act urgently, keep it secret, share a code, or move money to a "safe account."
Answers become rule features: `urgent_request`, `secrecy_request`, `code_sharing_request`, `safe_account_claim`.
*Accepted when:* a transaction that is clean on every technical signal is still escalated to HIGH because the user ticked "safe account" and "keep it secret," and the alert is worded as a possible scam rather than a possible hack.

**F-05 Structuring detection**
Deterministic rule, not learned: several transfers from one account within a window, amounts clustering just under a limit, same or related recipients. Produces `threshold_avoidance_score`.
*Accepted when:* ₹9,900 + ₹9,800 + ₹9,950 + ₹9,700 within ten minutes trips the signal while four unrelated payments of similar size across a week do not.

### 5.2 Incoming intelligence

**F-06 Unknown sender**
On every credit, resolve the sender against the receiver's relationship history: prior credits, prior debits, beneficiary list, shared merchants. Produce `sender_seen_before`, `relationship_age_days`, `prior_transaction_count`.

**F-07 Pass-through speed**
Continuously measured: seconds between a credit arriving and a comparable amount leaving. Produces `incoming_to_outgoing_seconds` and `pass_through_ratio` (value forwarded ÷ value received).
*Accepted when:* ₹42,000 in at 10:00 and ₹39,000 out at 10:03 produces a HIGH pass-through signal with a plain-language explanation.

**F-08 Fan-in / fan-out**
Graph and window features: `incoming_counterparties_1h`, `outgoing_counterparties_1h`, `fan_in_ratio`, `fan_out_ratio`, `inflow_concentration`.
*Accepted when:* an account collecting many small credits then pushing one large debit is separable from an account with ordinary two-way traffic.

**F-09 Dormancy break**
`days_since_last_activity` combined with the volume and value of the burst that ends it, producing `dormancy_break_score`.

**F-10 Income mismatch**
`normal_monthly_inflow` versus the current credit. Presented **never** as proof of fraud, always as *unusual inflow relative to this account's history*. The wording is a requirement, not a preference.

**F-11 Complaint proximity**
A simulated intelligence store holds complaints, flagged accounts, flagged devices and flagged identifiers. Shortest-path search from the sender to any flagged entity produces `complaint_proximity_hops` and the path itself as evidence.
*Accepted when:* an alert can say "this sender is two accounts away from a reported fraud case" and the analyst can click through to the path.

**F-12 Refund bait**
Sequence pattern: unexplained credit, then a return request or a rapid outgoing transfer of a similar amount to the same or a linked party. Detected by the same sequence engine as F-02.

### 5.3 User protection

**F-13 Explainable alert**
Every alert carries the amount, counterparty, direction, risk band and an ordered list of reason codes rendered as sentences. Reason codes are generated by the scoring service, not written by a language model after the fact.

**F-14 Actions**
Outgoing: `Continue`, `Cancel`, `Report`.
Incoming: `Recognise sender`, `Hold for 24 hours`, `Report`.

**F-15 Quarantine with a real held balance**
This is the headline feature and it must be functional, not a status flag.
Every account carries `available_balance`, `held_balance` and `total_balance`. Every outgoing transfer checks `available_balance >= amount`. A hold moves value from available to held and sets an expiry.
*Accepted when:* after quarantining ₹42,000, an attempt to send ₹50,000 from an account showing ₹80,000 total is refused for insufficient available funds, and the app explains why.

**F-16 Evidence record**
A quarantine writes an append-only audit chain: receipt time, alert time, user action time, amount spent after receipt, reason codes, sender subgraph snapshot, report status.
The wording constraint matters: the product claims it **creates a timestamped record showing the holder flagged and quarantined unexpected funds before using or forwarding them.** It never claims to establish legal innocence. Software cannot do that.

**F-17 Beneficiary trust ladder**
New beneficiaries carry a trust level that grows with confirmed history. For a large first payment the system proposes a controlled sequence: a ₹1 test transfer, an observation window, then release of the remainder. Presented as a recommended workflow inside the simulator, not as an enforced rail-level control.

**F-18 Push alerting**
Firebase Cloud Messaging to the Flutter app; Supabase Realtime to the analyst dashboard. Alert must reach the device within seconds of the scoring decision.

### 5.4 Analyst and investigation

**F-19 Live dashboard** — streaming alert feed, filters by direction, band and reason code.
**F-20 Transaction investigation view** — features, reason codes, SHAP contributions, event timeline.
**F-21 Graph visualisation** — the subgraph around the counterparty, with flagged nodes and the path to them highlighted.
**F-22 Counterfactual slider** — re-scores the transaction live with one input changed (amount, device known/unknown, recipient trusted/untrusted, hour of day) and shows the risk move. SHAP explains the actual decision; the slider answers what-if. They are different mechanisms and both are required.
**F-23 Case management** — held or reported transactions open a case with linked evidence, status workflow and an assigned analyst.
**F-24 Analyst feedback loop** — confirmed or dismissed alerts are labelled and feed the next training run.
**F-25 Model and system monitoring** — model version in use, score distribution drift, alert volume, latency percentiles, rule-fire counts.

### 5.5 Intelligence and privacy

**F-26 Simulated device fingerprinting**
Synthetic but structured: `device_id`, `os`, `app_version`, `device_model`, `network_id`, `first_seen`. Hashed into a stable fingerprint. Detects known device, new device, device reused across accounts, device linked to flagged accounts. No real telemetry is collected.

**F-27 Simulated behavioural session profile**
Synthetic session signals: typing speed, tap intervals, session duration, navigation path, time-to-confirm. Compared against the account's historical session profile to produce `session_anomaly_score`. No real biometric capture.

**F-28 Cross-bank hashed intelligence (FC-01 bridge)**
Three virtual banks hold private data and exchange only salted SHA-256 hashes of device, account and UPI identifiers alongside a risk indicator. A shared hash seen across institutions raises a cross-bank signal without exposing any customer identity.
*Accepted when:* Bank A can learn that a device it has never seen has been observed across several suspicious accounts elsewhere, without receiving a single raw identifier.

**F-29 Federated learning simulation**
Each virtual bank trains a local model on its own synthetic data; only parameter updates go to a coordinator, which aggregates and redistributes. Demonstrated with a small number of rounds and a visible metric improvement. Scope is a working demonstration of the mechanism, not a production federated platform.

---

## 6. Non-goals

- No connection to real payment rails, real bank cores, or real customer accounts.
- No collection of real biometric or device telemetry.
- No claim of a novel fraud-detection algorithm. Graph detection, behavioural modelling and explainable risk are all established. The contribution is the incoming-money protection and the quarantine mechanism.
- No legal determination of innocence or guilt.

---

## 7. Success metrics

| Metric | Target |
|---|---|
| Warm scoring latency, p95 | under 200 ms, measured locally and on a warm backend |
| Alert to device | under 3 seconds from decision |
| Recall on seeded fraud scenarios | every seeded scenario detected |
| False-positive rate on normal traffic | under 2% of transactions escalated above LOW |
| Reason-code coverage | 100% of alerts carry at least one human-readable reason |
| Quarantine correctness | held funds are never spendable; ledger always balances |

Latency is reported as *warm* latency. Free-tier hosting sleeps after inactivity and takes roughly a minute to wake, so a cold first request is not representative and is never quoted as the number.

---

## 8. Demonstration script

Five scenarios, in this order. The last one is the closer.

**Scenario 1 — Quiet.** ₹1,200 to a regular merchant, known device, normal hour. Nothing happens. This establishes that the system is not a smoke alarm that goes off at toast.

**Scenario 2 — Account takeover.** New device, password change, new beneficiary, then ₹5k, ₹25k, ₹75k in six minutes. The alert names the *sequence*. Show the event timeline in the analyst view.

**Scenario 3 — Manipulated payment.** Correct user, correct device, correct PIN, large transfer to a new payee. Every technical signal is clean. The coercion questions come back with "urgent" and "safe account." The system escalates to HIGH and words the alert as a scam, not a hack. This is the scenario that separates the project from a classifier.

**Scenario 4 — Structuring.** The same user retries as four payments just under the limit. The rule layer catches the pattern. Shows that not everything should be left to a model.

**Scenario 5 — Unexpected money (the closer).** ₹42,000 arrives from a stranger. The card explains: first-time sender, two hops from a reported complaint, sender collected eleven credits in the last hour, amount far above this account's normal inflow. User taps **Hold for 24 hours**. Show the balance split: total unchanged, available reduced, held ₹42,000. Attempt a ₹50,000 transfer and watch it refuse. Open the case file with the evidence chain and the sender subgraph.

Close on the line: *nobody sent a rupee, and a crime was still interrupted.*

**Optional sixth beat.** Switch to the three-bank view and show Bank A learning about a device from Banks B and C without receiving a single raw identifier, then run a federated round and watch local metrics improve.

---

## 9. Positioning

Do not pitch a new algorithm; a knowledgeable judge will name three papers that got there first.

Pitch the direction:

> Outgoing fraud detection asks, *are you sending money to the wrong person?*
> Incoming protection asks, *why did money from the wrong person enter your account, and what can you do before it becomes your problem?*

The second question is the product.
