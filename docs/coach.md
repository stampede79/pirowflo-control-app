# PiRowFlo Coach

The PiRowFlo Coach is a backend-driven training analysis and planning
system for indoor rowing.

The Flutter application presents Coach results and user decisions, while
the actual analysis, review and planning logic runs in the PiRowFlo
Control API environment.

## Overview

The Coach operates at several levels:

```text
Completed workout
       |
       v
Workout Analysis
       |
       v
Weekly Review
       |
       v
Monthly Review
       |
       +--------------------+
       |                    |
       v                    v
Monthly Planning      Plan Reassessment
       |                    |
       v                    v
Training Plan       Recommendation / Review
```

These stages deliberately have different responsibilities.

A single workout analysis evaluates one session.

A weekly review looks for patterns across several sessions.

A monthly review evaluates longer-term patterns across weeks.

The monthly planner uses the accumulated context to prepare the next
training month.

Plan reassessment and plan review can react to new information without
automatically replacing an otherwise suitable plan.

## Model and prompt versions

At the time of writing, the backend uses:

| Component | Model | Prompt version |
|---|---|---|
| Workout Analysis | `gpt-6-luna` | `5` |
| Weekly Review | `gpt-6-luna` | `2` |
| Monthly Review | `gpt-6-luna` | `2` |
| Monthly Training Planner | `gpt-6-luna` | `3` |
| Training Plan Reviewer | `gpt-6-luna` | not separately versioned |

Prompt versions are part of the persisted analysis/review metadata where
supported.

They allow previously generated results to be distinguished from results
created with newer analysis logic.

## Input fingerprints and caching

Several Coach stages calculate a deterministic fingerprint from their
structured input.

A previously generated result can be reused when the relevant
combination of:

- input fingerprint
- model
- prompt version

has not changed.

This avoids unnecessary OpenAI calls while still allowing results to be
regenerated when their underlying data or prompt logic changes.

The monthly planner follows the same principle for plan drafts.

A cached draft is only reused when its:

- input fingerprint
- model
- prompt version

still match the current planning request.

## Workout Analysis

Workout Analysis evaluates an individual completed rowing session.

It combines the planned workout with the actual recorded activity and
produces structured training feedback.

The analysis can describe aspects such as:

- execution
- load assessment
- effort
- progression
- recovery concerns
- summary
- recommendation

Workout Analysis is the lowest Coach aggregation level.

Later weekly and monthly reviews consume these analyses instead of
reinterpreting every raw workout independently.

## Recovery data

Recovery information is treated as training context rather than as
medical information.

The Coach may use information such as:

- sleep duration
- sleep score
- resting heart rate
- sleep stress
- HRV status

Recovery values are primarily interpreted relative to personal
baselines.

For weekly reviews, the backend provides 28-day personal baselines for
relevant recovery metrics.

The Coach must not interpret missing recovery data as a negative signal.

Incomplete data coverage must also be taken into account when evaluating
a week.

For example, three days of available recovery data must not be treated
as if all seven days of the week had been observed.

A single negative recovery signal is not sufficient for a concerning
assessment.

Several consistent signals, or recovery abnormalities together with
repeatedly abnormal training reactions, are required for stronger
conclusions.

Recovery information is not used to derive medical diagnoses.

## Weekly Review

A Weekly Review evaluates a complete ISO training week.

Its primary input consists of already generated workout analyses together
with deterministic weekly context and recovery information.

The purpose of the Weekly Review is not to repeat individual workout
analyses.

Instead, it looks for patterns such as:

- implementation of the training plan
- load distribution
- performance stability
- recurring observations
- recovery patterns
- useful consequences for the following week

Workout states are interpreted explicitly:

- `completed` – the workout was completed
- `planned` – the workout is still upcoming
- `skipped` – the workout was intentionally skipped
- `missed` – the workout date passed without a matching activity

A planned workout must not be treated as missed before its scheduled
time has passed.

A single missed workout does not automatically justify a fundamental
change to the training plan.

### Weekly Review output

The structured result includes concepts such as:

- assessment
- trend
- load assessment
- recovery assessment
- consistency
- key observations
- summary
- recommendation

The Weekly Review provides context for subsequent training decisions but
does not directly modify the training plan.

## Monthly Review

The Monthly Review evaluates a complete training month.

Its input combines:

- deterministic monthly metrics
- Weekly Reviews
- current individual Workout Analyses

Weekly Reviews are the primary source for trends that span multiple
weeks.

Individual Workout Analyses remain useful for concrete observations.

The Monthly Review deliberately avoids counting the same recovery signal
multiple times merely because it appears both in an individual workout
analysis and a Weekly Review.

A single unusual workout is not considered a monthly trend.

Similarly, one week with `recovery_assessment=watch` does not
automatically mean that recovery for the complete month is problematic.

### Monthly Review focus

The review evaluates areas including:

- training-plan execution
- consistency
- load distribution
- performance development
- recurring heart-rate or recovery patterns
- quality of different training types
- useful priorities for the following month

Its recommendation becomes an important input for planning the next
training month.

## Month-end coordination

Monthly finalization is intentionally guarded.

The previous month is not finalized merely because the calendar month
has changed.

Before a Monthly Review is generated, the backend checks:

1. At least one workout was completed.
2. No workouts for the month are still open.
3. All relevant weeks have actually finished.
4. Required Weekly Reviews are available.

If a relevant week is still in progress, monthly finalization is
postponed.

This prevents a race where a Monthly Review would be generated before
the final Weekly Review contains all relevant training data.

Before generating the Monthly Review, the monthly Coach job ensures the
required completed Weekly Reviews exist.

## Plan reassessment after month end

After the final Monthly Review has been created, the backend evaluates
whether the already prepared plan for the following month should be
reassessed.

A reassessment can be recommended when new information from the final
month changes the training context.

The system does not silently modify the plan at this stage.

Instead, it can create a recommendation explaining why reassessment may
be useful.

This keeps plan changes visible and reviewable.

## Monthly Training Planner

The Monthly Training Planner creates a draft for a target month.

By default, it plans the next calendar month.

The current default target is three sessions per week, subject to
availability and recovery constraints.

### Planning context

The planner receives structured context including:

- planned workouts from the previous month
- completed workouts
- actual performance data
- individual Workout Analyses
- Weekly Reviews
- optional final Monthly Review
- confirmed availability decisions
- personal calendar entries
- deterministic planning constraints

The planner therefore does not make scheduling decisions from the
training history alone.

Personal availability is part of the initial planning input.

## Planning constraints

Deterministic planning constraints have priority over model preferences.

Important categories include:

- `unavailable_dates`
- `explicitly_available_dates`
- `limited_dates`

### Unavailable dates

No workout may be scheduled on an unavailable date.

This rule is also validated after model generation.

### Explicitly available dates

An explicitly available date may be used even when a personal calendar
entry exists.

### Limited dates

Limited dates should only be used for light or otherwise appropriate
sessions when this is sensible from a training perspective.

### Multi-day absences

Multi-day absences are already represented in the deterministic planning
constraints.

The model is instructed not to reinterpret these restrictions
independently.

## Training-plan principles

The monthly planner follows conservative training principles.

In particular:

- base training should form the largest part of the plan
- volume or intensity should only increase moderately
- progression should be supported by the available data
- load should not remain monotonous across the whole month
- lighter or recovery phases should be included where appropriate
- directly consecutive training days should be avoided where possible
- absence weeks do not need to be compensated by additional sessions
  before or after the absence

Training targets use watts and SPM.

## Planner output validation

The model output is not accepted blindly.

After generation, the backend validates the proposed workout dates.

The plan is rejected if:

- a workout lies outside the target month
- a workout lies on an unavailable date
- multiple workouts are scheduled for the same date

This means deterministic scheduling rules remain authoritative even when
the plan itself was generated by the model.

## Plan draft

A generated monthly plan is initially stored as a draft.

The draft contains:

- target month
- generation timestamp
- sessions per week
- model
- prompt version
- input fingerprint
- complete planning context
- generated workouts

The planning context stored with the draft makes it possible to
understand what information was available when the plan was created.

## Training Plan Reviewer

The Training Plan Reviewer evaluates an existing plan rather than
creating a completely new one.

Its guiding principle is:

> Keep the existing plan stable unless there is a concrete reason to
> change it.

The reviewer can return the following actions:

- `keep`
- `move`
- `skip`
- `modify`

### Keep

The workout remains unchanged.

### Move

The workout is moved to another date.

### Skip

The workout remains part of the plan but is intentionally marked as
skipped.

A skipped workout must not later be interpreted as a missed workout.

### Modify

The workout content or load is changed.

## Plan-review context

The reviewer can use:

- the existing monthly plan
- availability-calendar events
- deterministic availability context
- Endurain activities from the current month
- training-calendar events
- current training development

This allows an existing plan to react to new circumstances without
regenerating the entire month unnecessarily.

Unavailable periods remain hard constraints: no training may be moved
into such a period.

## Coach recommendations

Some Coach decisions require user confirmation.

Examples include:

- availability decisions
- plan reassessment
- proposed replanning decisions

The Flutter application displays these recommendations and sends the
user's decision back to the PiRowFlo Control API.

The backend remains responsible for applying the resulting Coach logic.

## Flutter application responsibility

The Flutter application does not generate Coach analyses itself.

Its responsibilities are:

- loading the Coach overview
- displaying Workout Analyses
- displaying Weekly Reviews
- displaying Monthly Reviews
- displaying pending recommendations
- collecting availability decisions
- collecting recommendation decisions
- displaying monthly plan drafts
- displaying plan reviews
- requesting application of accepted plan changes

This keeps model interaction and Coach business logic on the backend.

## Safety and interpretation

Coach results are training guidance.

Recovery, sleep, HRV, resting-heart-rate and stress information must not
be interpreted as medical diagnosis.

Missing data is not negative evidence.

Individual unusual workouts or isolated recovery signals should not
cause disproportionate changes to the training plan.

The Coach intentionally favors repeated patterns and accumulated evidence
over single observations.

## Pipeline summary

The complete conceptual flow is:

```text
Planned workout + Endurain activity
                |
                v
        Workout Analysis v5
                |
                v
         Weekly Review v2
                |
                v
        Monthly Review v2
                |
                +----------------------+
                |                      |
                v                      v
    Monthly Planner v3          Plan reassessment
                |                      |
                v                      v
           Plan draft             Recommendation
                |
                v
       Training Plan Reviewer
                |
                v
       keep / move / skip / modify
                |
                v
          reviewed plan
```

The individual stages intentionally build on one another while retaining
deterministic validation and explicit user decisions around plan changes.