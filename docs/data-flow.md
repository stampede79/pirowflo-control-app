# PiRowFlo Control – Data Flow

This document describes how planned workouts, Endurain activities,
activity links, workout analyses and the training history are connected
inside PiRowFlo Control.

## Main concepts

PiRowFlo Control works with several related but distinct objects:

- **Workout** – the structured rowing workout that can be executed by the app
- **ScheduledWorkout** – a workout assigned to a specific date
- **EndurainActivity** – an actually recorded rowing activity
- **Workout/Activity Link** – persistent association between a planned workout and an Endurain activity
- **WorkoutAnalysis** – Coach analysis of a completed workout/activity pair
- **TrainingHistoryEntry** – presentation model combining planned and free training

These objects come from different systems and are intentionally not
treated as the same thing.

## Planned workout flow

Planned workouts are loaded from the PiRowFlo Control API.

```text
PiRowFlo Control API
        |
        | GET /api/workouts
        v
   ApiWorkout
        |
        | conversion
        v
 ScheduledWorkout
        |
        +----> Home
        |
        +----> Training
        |
        +----> Workout runner
        |
        +----> Training history
```

`WorkoutService` loads workouts for a requested date range.

The API representation is parsed as `ApiWorkout` and converted into a
`ScheduledWorkout`.

A malformed individual workout does not prevent all other workouts from
being loaded.

## Completed activity flow

Completed rowing activities originate from Endurain.

```text
     Endurain
        |
        | activities
        v
 EndurainActivity
        |
        +----> Statistics
        |
        +----> Workout matching
        |
        +----> Training history
```

An Endurain activity represents what actually happened during a rowing
session.

It is separate from the planned PiRowFlo workout.

## Workout/activity linking

A completed Endurain activity can be associated with a planned PiRowFlo
workout.

The persistent link is stored by the PiRowFlo Control API.

```text
ScheduledWorkout
       +
EndurainActivity
       |
       | POST /api/workouts/{id}/activity-link
       v
PiRowFlo Control API
       |
       v
persistent workout/activity link
```

The Flutter app sends the Endurain activity ID to the Control API through
`WorkoutService.linkActivity()`.

After the link has been stored, subsequent workout responses can contain
the existing activity association.

## Matching priority

`RecentWorkoutMatcher` resolves planned workouts and Endurain activities.

Existing persistent links always have priority.

```text
1. Existing persistent workout/activity link
                    |
                    v
             use directly

2. No persistent link
                    |
                    v
       search plausible activity
                    |
                    v
            candidate match

3. No plausible activity
                    |
                    v
               waiting
```

Activities already used by an existing persistent link are excluded from
candidate matching.

Candidate matches are scored and the most plausible combinations are
assigned first.

One activity cannot be assigned to multiple workouts and one workout
cannot receive multiple activities.

Skipped and missed workouts are preserved in the history but are not
considered open matching candidates.

## Training history

The training history combines planned workouts and actual Endurain
activities.

```text
ScheduledWorkouts ----+
                      |
                      v
             RecentWorkoutMatcher
                      |
                      v
             matched workouts
                      |
                      +----------+
                                 |
EndurainActivities --------------+
                                 |
                                 v
                    TrainingHistoryMerger
                                 |
                                 v
                    TrainingHistoryEntry[]
```

For every planned workout, the history can contain:

- linked activity
- candidate activity
- waiting workout
- missed workout
- skipped workout

A workout scheduled for today is not added to the history while it is
still incomplete.

Once it is completed, it can appear in the history on the same day.

## Free training

An Endurain activity that is not associated with a planned workout is
displayed as a free training session.

```text
EndurainActivity
       |
       | no persistent link
       | no candidate assignment
       v
TrainingHistoryEntry.free
```

Activities already assigned to a planned workout are explicitly excluded
from the free-training list.

This prevents the same physical rowing session from appearing twice in
the history.

## Workout analyses

Workout analyses are loaded from the PiRowFlo Control API through
`TrainingHistoryService`.

```text
PiRowFlo Control API
        |
        | GET /api/training-history
        v
 activity + analysis
        |
        v
Map<EndurainActivityId, WorkoutAnalysis>
```

The Flutter app indexes analyses by Endurain activity ID.

During history construction, the matching activity ID is used to attach
the corresponding `WorkoutAnalysis` to the history entry.

```text
TrainingHistoryEntry
        |
        +-- planned/free activity
        |
        +-- WorkoutAnalysis
```

The generation of the analysis itself happens outside the Flutter app.

The Flutter app consumes and presents the resulting analysis.

## Detailed activity data

The activity metadata and the detailed chart streams have different
data paths.

### Activity metadata

Basic activity information originates from Endurain:

```text
Endurain
   |
   v
EndurainActivity
```

This includes values such as:

- distance
- duration
- average and maximum power
- average and maximum heart rate
- cadence
- calories

### Activity streams

The chart streams displayed by the app are loaded through the PiRowFlo
Control API:

```text
Endurain activity ID
        |
        v
PiRowFlo Control API
        |
        | GET /api/activities/{id}/streams
        v
 cleaned activity streams
        |
        +-- power
        +-- cadence
        +-- heart rate
        |
        v
RowingActivityDetailScreen
```

The activity still originates from Endurain, but the Flutter app does
not directly load the chart streams from Endurain.

The PiRowFlo Control API provides the prepared streams used for
visualization and analysis.

This distinction is important when troubleshooting activity details.

If Endurain is reachable but the PiRowFlo Control API is not reachable,
activity metadata may still be available while detailed charts cannot be
loaded.

## Live workout metrics

Live SmartRow data follows a separate path from historical activity
streams.

```text
SmartRow
   |
   v
PiRowFlo
   |
   v
PiRowFlo Control API
   |
   | GET /api/metrics
   v
MetricsService
   |
   v
WorkoutScreen
```

The Flutter app does not connect directly to SmartRow.

`MetricsService` polls the Control API while a workout is running.

The optional heart-rate sensor is the exception: it is connected
directly by the Flutter app through `HeartRateService`.

## Offline workout cache

Workout planning data is cached locally on the device.

```text
PiRowFlo Control API
        |
        | raw workout response
        v
WorkoutCacheService
        |
        v
workout_cache.json
```

The cache stores:

- cache timestamp
- raw workout rows

When loaded, the raw API rows are parsed again into `ApiWorkout` and
then converted into `ScheduledWorkout`.

Invalid cache data is ignored instead of preventing the application from
starting.

The cache is intended to keep planned workout information available when
the PiRowFlo Control API cannot be reached.

It does not turn the complete application into an offline application.

Features requiring live API access remain unavailable while PiRowFlo is
offline.

## Coach data flow

The Flutter app consumes Coach information from the PiRowFlo Control API.

```text
Workout/activity data
        |
        v
PiRowFlo Coach backend
        |
        +-- WorkoutAnalysis
        +-- WeeklyReview
        +-- MonthlyReview
        +-- Recommendations
        |
        v
GET /api/coach/overview
        |
        v
CoachService
        |
        v
CoachScreen
```

The Flutter application presents these results and sends user decisions
back to the Coach API.

Examples include:

- availability decisions
- replanning recommendation decisions

The generation of workout analyses, weekly reviews, monthly reviews and
training plans is backend functionality and is not implemented in the
Flutter application.

## Summary

The most important distinction is:

```text
Planned training
    -> PiRowFlo Control API

Recorded activities and statistics
    -> Endurain

Persistent workout/activity association
    -> PiRowFlo Control API

Prepared historical chart streams
    -> PiRowFlo Control API

Workout analyses and Coach reviews
    -> PiRowFlo Control API

Live SmartRow metrics
    -> PiRowFlo Control API

Optional live heart rate
    -> direct Bluetooth connection from the Flutter app
```

Keeping these data sources separate makes it easier to understand which
component is responsible when a specific part of the application is
unavailable.