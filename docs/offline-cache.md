# PiRowFlo Control – Offline Workout Cache

PiRowFlo Control keeps a local cache of planned workouts so that useful
training information remains available when the PiRowFlo Control API
cannot temporarily be reached.

The cache is intentionally limited in scope. It is not intended to make
the complete application work offline.

## Purpose

The cache primarily improves application startup and training-plan
visibility during temporary network or PiRowFlo API outages.

Without the cache, a failed startup connection could leave the app
without information about planned workouts.

With the cache, previously loaded workout data can still be presented.

## Storage

The cache is managed by:

```text
lib/services/workout_cache_service.dart
```

It is stored in the application's support directory as:

```text
workout_cache.json
```

The file contains:

- the time at which the cache was written
- raw workout rows returned by the PiRowFlo Control API

Conceptually:

```json
{
  "cached_at": "2026-10-30T09:30:00.000",
  "workouts": [
    {
      "...": "raw API workout data"
    }
  ]
}
```

The cache does not store an independently designed Flutter-specific
workout format.

Instead, the original API representation is retained.

## Loading the cache

When cached workouts are loaded, PiRowFlo Control reconstructs the normal
application models:

```text
workout_cache.json
        |
        v
raw workout rows
        |
        v
ApiWorkout
        |
        v
ScheduledWorkout
```

This means cached and freshly downloaded workouts follow the same model
conversion path.

## Cache failure handling

Cache failures must not prevent the application from starting.

`WorkoutCacheService.load()` therefore returns no cache data when:

- the cache file does not exist
- the file cannot be read
- the JSON structure is invalid
- the cache timestamp is invalid
- another cache parsing error occurs

Invalid individual workout rows that cannot produce a usable scheduled
workout are not added to the resulting workout list.

## Startup behavior

During normal startup the app first attempts to reach the PiRowFlo
Control API.

If PiRowFlo cannot be reached, cached workout information can be loaded
instead.

This allows the training-related UI to retain useful previously known
information even when live PiRowFlo communication is unavailable.

The UI can indicate that cached workout data is being used and when the
cache was created.

## Cache refresh

When fresh workout information has been successfully obtained from the
PiRowFlo Control API, the local cache can be refreshed with the latest
raw workout data.

The cache is therefore a fallback copy of previously retrieved planning
information, not a second authoritative data source.

The PiRowFlo Control API remains the source of truth.

## What remains available

Depending on what has already been cached or loaded locally, the app can
still present previously known planned workout information when PiRowFlo
is temporarily unavailable.

This is particularly useful for:

- today's planned workouts
- upcoming workouts
- previously retrieved workout planning information

## What is not provided by the cache

The workout cache does not provide live backend functionality.

The following features still require the corresponding service to be
reachable:

- PiRowFlo operating-mode control
- current hardware status
- SmartRow live metrics
- SmartRow reset
- new workout/activity links
- Coach API refreshes and decisions
- new training-history analyses
- new training-plan drafts or reviews
- historical activity streams from the PiRowFlo Control API

Endurain is a separate integration.

If Endurain remains reachable while PiRowFlo is unavailable, Endurain
activities and statistics may still be refreshed independently where the
application flow permits it.

## Design principle

The offline cache follows a deliberately simple rule:

```text
PiRowFlo available
        |
        v
load fresh workouts
        |
        v
refresh cache

PiRowFlo unavailable
        |
        v
try local workout cache
        |
        v
show previously known planning data
```

The cache improves resilience without attempting to duplicate the
PiRowFlo backend on the Android device.