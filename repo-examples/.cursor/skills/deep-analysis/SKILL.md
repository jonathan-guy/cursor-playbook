---
name: deep-analysis
description: Conduct thorough, iterative statistical analysis with 4 mandatory passes (exploratory, primary, robustness, accuracy audit). Triangulates across methods, applies robustness checks, and prevents misinterpretations via an adversarial accuracy gate.
---

# Deep Analysis — Rigorous Investigative Analytics

Orchestrates multi-pass statistical investigations. Starts from a research question, exhausts available data, applies multiple methods, and gates every finding through an adversarial accuracy audit before delivery.

## When to Run

- User invokes `/deep-analysis`
- User asks "why did X change?", "does Y affect Z?", or any causal/explanatory question
- User asks for a "deep dive", "thorough analysis", or "root cause analysis"
- A metric movement needs explanation beyond descriptive stats

## Core Principles

1. **Never deliver a mistaken insight.** An absent finding is always better than a wrong one.
2. **Triangulate.** Never report a finding backed by only one method or one data source.
3. **4 mandatory passes.** Exploratory → primary → robustness → accuracy audit. No shortcuts.
4. **Practical significance over p-values.** Every finding must answer "so what?" with an effect size.
5. **Iterate.** Earlier passes feed later ones. The accuracy audit can send findings back for more investigation.

## Step 1: Frame the Question

Before touching any data:

1. State the **research question** as a single clear sentence.
2. List **1-3 testable hypotheses** with directional predictions.
3. Define **success criteria** — what would a convincing answer look like?
4. Identify the **question type** from the method selection matrix (Step 5).
5. Present the framing to the user for confirmation.

## Step 2: Survey Available Data

Inventory everything relevant:

1. Check metric catalog for existing related metrics and their status.
2. Check source registry for data availability and freshness.
3. Check existing analyses — has a related question been investigated before?
4. Check pre-aggregated data files.
5. Probe the data warehouse for row counts, date ranges, null rates.
6. Assess data quality: coverage gaps, known caveats, join keys.

Document the inventory as a table: source, table/metric, date range, row count, caveats.

## Step 3: Scaffold the Investigation

Create a reproducible analysis directory:

```
analysis/<investigation-name>/
  __init__.py
  PLAN.md              # blueprint (generated from Steps 1-2)
  run.py               # executable analysis (built incrementally)
  output/
    findings.json
    narrative.md
```

## Step 4: Pass 1 — Exploratory

Quick descriptive analysis to calibrate expectations:

1. **Distributions**: Mean, median, P25, P75, P95, standard deviation.
2. **Missing data**: Count nulls. Is missingness random or systematic?
3. **Outliers**: Beyond 3x IQR. Decide: winsorize, exclude, or keep.
4. **Time coverage**: Sufficient date ranges? Gaps?
5. **Population check**: Enough observations for planned methods?
6. **Quick correlations**: Rough effect size calibration.
7. **Known confounders**: List variables that could confound the relationship.

**Decision gate**: If data quality issues would compromise the primary analysis, stop and report before proceeding.

## Step 5: Design the Analytical Approach

### Method Selection Matrix

| Question Type | Primary Method | Triangulation |
|---|---|---|
| "Did X cause Y?" | Difference-in-differences (DID) | Event study, synthetic control |
| "Do X and Y move together?" | Pearson + Spearman correlation | Partial correlation, lag cross-correlation |
| "What predicts Z?" | OLS panel regression | Gradient boosted trees + SHAP |
| "Are there distinct groups?" | k-means + silhouette selection | Hierarchical clustering, PCA |
| "Is this pattern real?" | STL decomposition, bootstrap CIs | Permutation tests, anomaly detection |
| "Which segments differ?" | Mann-Whitney U, Cohen's d | Kruskal-Wallis, composite z-score |
| "Does A lead B in time?" | Granger causality | Cross-correlation, VAR |

Always plan a primary method AND at least one triangulation method.

## Step 6: Pass 2 — Primary Analysis

Execute with full statistical rigor:

1. Implement the primary method with confidence intervals, effect sizes, and p-values.
2. Implement the triangulation method. Compare results.
3. Segment the analysis by major groups to check generalizability.
4. Document every analytical decision.

## Step 7: Pass 3 — Robustness and Sensitivity

Apply at least 3 checks:

| Check | What It Tests |
|---|---|
| Alternative specifications | Different controls, functional forms, lag structures |
| Placebo tests | Fake treatment dates, irrelevant outcomes |
| Bootstrap CIs | Non-parametric confidence intervals |
| Leave-one-out | Drop each major segment and re-estimate |
| Multiple comparison correction | Bonferroni, Holm-Bonferroni, or FDR |
| Winsorization | Trim at 1st/99th percentile |
| Sample restriction | Exclude bots, tiny groups, incomplete periods |
| Time window sensitivity | Shift window +/- 2 weeks |

Classify each finding: **Robust** (survives all), **Partially robust** (sensitive to one spec), or **Fragile** (reverses under reasonable alternatives). Fragile findings return to Pass 2.

## Step 8: Pass 4 — Accuracy Audit

The hard gate. For EVERY finding:

### Devil's Advocate
State the single strongest argument that the finding is wrong. If the counter-argument is stronger than the evidence, drop the finding.

### Pre-Mortem
"If this conclusion is wrong six months from now, what is the most likely reason?"

### Statistical Trap Checklist

| Trap | Check |
|---|---|
| Simpson's paradox | Does the effect reverse when conditioning on a key variable? |
| Survivorship bias | Are you only seeing entities that survived? |
| Confounding | Is there an uncontrolled variable explaining both X and Y? |
| Ecological fallacy | Inferring individual behavior from group data? |
| Regression to the mean | Is the "improvement" just extreme values reverting? |
| Base rate neglect | Comparing rates without accounting for different populations? |
| Selection effects | Did treatment/control self-select? |
| Cherry-picked window | Would the finding hold with a shifted time window? |

### Audit Dispositions

- **Retained** — survived all checks, ships at assigned confidence
- **Downgraded** — survived with caveats, confidence reduced
- **Dropped** — failed critical checks, excluded from output
- **Deferred** — needs additional data before conclusion

## Step 9: Confidence Assignment

| Tier | Criteria |
|---|---|
| **High** | Multiple methods converge + all robustness checks pass + large effect size + full audit |
| **Medium** | Primary + 1 robustness check + moderate effect size + audit with minor caveats |
| **Low** | Single method, marginal significance, or meaningful caveats |

Never assign High to a single-method finding.

## Step 10: Synthesize and Output

Write `findings.json` (structured) and `narrative.md` (readable) with:
- Research question and hypothesis results
- Key findings ordered by confidence tier
- Accuracy audit summary (how many entered, survived, dropped)
- Robustness assessment
- Limitations (actively list ways conclusions could be wrong)
- Actionable recommendations

## Critical Rules

1. **All 4 passes are mandatory.** Reduce scope rather than cut passes.
2. **No finding ships without triangulation.** Single-method ≠ High or Medium confidence.
3. **Document every decision.** Every analytical choice must be justified.
4. **Report what you didn't find.** Null results are as important as significant ones.
5. **Effect sizes are mandatory.** Never report only a p-value.
6. **The accuracy audit is a hard gate.** Failed findings don't ship. Period.
7. **Prefer conservative conclusions.** When evidence is ambiguous, downgrade.
8. **Make it reproducible.** The `run.py` must be runnable by someone else.
