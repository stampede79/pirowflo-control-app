# PiRowFlo Control – Architecture

PiRowFlo Control is the Flutter-based user interface for the PiRowFlo
training environment.

The app intentionally separates presentation, training orchestration and
access to the external systems used by PiRowFlo.

## System overview

```text
                         Nextcloud
                             |
                    Calendar / availability
                             |
                             v
                    PiRowFlo Control API
                             ^
                             |
                             |
                    PiRowFlo Control App
                      /             \
                     /               \
          PiRowFlo Control API       Endurain
                  |                     |
                  |                     +-- Activities
                  |                     +-- Statistics
                  |
                  +-- PiRowFlo control
                  +-- Hardware status
                  +-- SmartRow live metrics
                  +-- Workouts
                  +-- Workout/activity links
                  +-- Activity streams
                  +-- Training history
                  +-- Coach
                  +-- Training planning
                             |
                             v
                          PiRowFlo
                             |
                   +---------+---------+
                   |                   |
                SmartRow          BLE / ANT+
```

SmartRow remains connected to PiRowFlo. The Flutter app does not open a
second SmartRow Bluetooth connection.

The exception is the optional heart-rate sensor used during a running
workout. The app connects to that sensor directly through Bluetooth.

## Flutter application

`lib/main.dart` is the application orchestration layer.

It is responsible for:

- application startup
- loading and saving configuration
- coordinating data refreshes
- maintaining application-level UI state
- navigation between major screens
- coordinating operations involving multiple services

`main.dart` does not perform PiRowFlo HTTP requests directly. API access
is delegated to services.

## PiRowFlo services

The app uses small domain-specific services instead of one large API
client.

### ControlService

Handles:

- PiRowFlo status
- operating-mode control
- restart and stop operations

Status responses are converted into `PiRowFloStatus`.

### MetricsService

Loads SmartRow live metrics during a running workout and provides the
SmartRow reset operation.

Live metrics are polled frequently and therefore use a short timeout.

### WorkoutService

Handles planned PiRowFlo workouts.

Responsibilities include:

- loading workouts for a date range
- converting API workouts into runnable workouts
- linking a completed Endurain activity with a planned workout

### TrainingHistoryService

Loads workout analyses and their associated activities for the training
history.

### TrainingPlanService

Handles monthly training-plan drafts and plan reviews.

It can:

- load a generated draft
- apply a draft
- load a plan review
- apply reviewed plan changes

### CoachService

Handles the Coach API.

It provides:

- Coach overview
- availability answers
- recommendation decisions

### ActivityStreamService

Loads cleaned activity streams from the PiRowFlo Control API.

These streams are used by the detailed activity view for:

- power
- stroke rate
- heart rate

Although the activity itself originates from Endurain, the detailed
stream data used by the Flutter charts is loaded through the PiRowFlo
Control API.

This is intentional: PiRowFlo performs the stream preparation and signal
quality processing centrally.

## Endurain integration

`EndurainService` communicates directly with Endurain.

It is responsible for:

- authentication
- token refresh
- rowing activities
- rowing statistics

Endurain and the PiRowFlo Control API are separate data sources.

An Endurain activity may later be linked to a planned PiRowFlo workout.

## Workout execution

`WorkoutScreen` owns the lifecycle of a running workout.

It manages:

- workout step progression
- timers
- pause and resume
- countdowns
- audio cues
- SmartRow live metrics
- heart-rate data
- step results
- final workout results

Metric aggregation for individual workout steps is delegated to
`WorkoutStepRecorder`.

## Heart-rate sensor

The heart-rate sensor is independent from SmartRow.

`HeartRateService` manages:

- Bluetooth discovery
- connection
- heart-rate notifications
- stale-data detection
- reconnection
- Bluetooth resource cleanup

The workout screen subscribes to the heart-rate and status streams and
cancels its subscriptions when the screen is disposed.

## Training screen

`TrainingScreen` is a presentation layer for:

- current workouts
- upcoming workouts
- training-plan drafts
- training-plan reviews
- training history
- planned and free activities

The screen does not know PiRowFlo server addresses or API keys.

Navigation and operations requiring application configuration are
delegated through callbacks to the application orchestration layer.

## Coach screen

`CoachScreen` is a presentation layer.

It displays:

- latest workout analysis
- weekly review
- monthly review
- availability questions
- replanning recommendations

Coach actions are delegated through callbacks and ultimately handled by
`CoachService`.

## Server URL handling

PiRowFlo service URLs are normalized through:

```text
lib/utils/server_url.dart
```

A configured trailing slash is removed before API paths are appended.

For example, both:

```text
http://192.168.178.51:8090
```

and:

```text
http://192.168.178.51:8090/
```

produce the same API URLs.

## Error handling

Network timeouts intentionally depend on the operation.

Examples:

- live metrics use a short timeout
- normal API reads use moderate timeouts
- larger history requests allow more time
- plan-changing operations allow longer timeouts

Background status refreshes intentionally suppress transient errors so
that temporary network issues do not continuously interrupt the UI.

User-triggered operations surface errors to the user.

## Design principles

The current architecture follows a few intentionally simple rules:

1. Screens should primarily contain presentation and local UI state.
2. PiRowFlo HTTP access belongs in domain services.
3. `main.dart` coordinates services and application-level state.
4. Endurain remains a separate integration.
5. Domain-specific services are preferred over a generic REST client.
6. Complex training calculations should be testable independently from
   Flutter UI code.
7. Refactoring should preserve the stable workout execution path unless
   there is a concrete maintenance or correctness benefit.
