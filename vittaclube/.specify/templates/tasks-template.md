---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are MANDATORY. Include automated tests appropriate to the
feature risk and platform: unit tests for rules/formatters, widget/UI tests for
critical components and states, integration tests for business journeys,
contract tests for API boundaries, accessibility checks, performance checks,
and regression tests for fixed bugs.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.

  The /speckit-tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/

  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment

  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools
- [ ] T004 [P] Configure automated test tooling and coverage/report commands
- [ ] T005 [P] Configure accessibility, performance, and SEO/local metadata validation tooling where applicable

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

Examples of foundational tasks (adjust based on your project):

- [ ] T006 Setup database schema and migrations framework
- [ ] T007 [P] Implement authentication/authorization framework
- [ ] T008 [P] Setup API routing and middleware structure
- [ ] T009 Create base models/entities that all stories depend on
- [ ] T010 Configure error handling and logging infrastructure
- [ ] T011 Setup environment configuration management
- [ ] T012 Establish feature-based clean architecture folders and shared boundaries
- [ ] T013 Define reusable UI tokens/components for CTA, trust proof, states, and mobile layout consistency

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 (MANDATORY) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T014 [P] [US1] Unit test for [business rule] in tests/unit/test_[name].py
- [ ] T015 [P] [US1] UI/widget test for mobile layout, CTA visibility, and required states in tests/ui/test_[name].py
- [ ] T016 [P] [US1] Integration test for [user journey] in tests/integration/test_[name].py
- [ ] T017 [P] [US1] Accessibility test/check for focus, labels, contrast, and semantics in tests/accessibility/test_[name].py

### Implementation for User Story 1

- [ ] T018 [P] [US1] Create domain entity/value object in src/features/[feature]/domain/[entity].*
- [ ] T019 [P] [US1] Create application use case in src/features/[feature]/application/[use_case].*
- [ ] T020 [US1] Implement infrastructure adapter/repository in src/features/[feature]/infrastructure/[adapter].*
- [ ] T021 [US1] Implement presentation flow/screen in src/features/[feature]/presentation/[screen].*
- [ ] T022 [US1] Add real content, trust proof, primary CTA, and empty/loading/error/success states
- [ ] T023 [US1] Add validation, error handling, and analytics/logging needed for business outcome

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2 (MANDATORY) ⚠️

- [ ] T024 [P] [US2] Unit test for [business rule] in tests/unit/test_[name].py
- [ ] T025 [P] [US2] UI/widget test for mobile layout, CTA visibility, and required states in tests/ui/test_[name].py
- [ ] T026 [P] [US2] Integration test for [user journey] in tests/integration/test_[name].py

### Implementation for User Story 2

- [ ] T027 [P] [US2] Create domain entity/value object in src/features/[feature]/domain/[entity].*
- [ ] T028 [US2] Implement application use case in src/features/[feature]/application/[use_case].*
- [ ] T029 [US2] Implement presentation flow/screen in src/features/[feature]/presentation/[screen].*
- [ ] T030 [US2] Integrate with User Story 1 components only through defined feature/shared boundaries

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 3 (MANDATORY) ⚠️

- [ ] T031 [P] [US3] Unit test for [business rule] in tests/unit/test_[name].py
- [ ] T032 [P] [US3] UI/widget test for mobile layout, CTA visibility, and required states in tests/ui/test_[name].py
- [ ] T033 [P] [US3] Integration test for [user journey] in tests/integration/test_[name].py

### Implementation for User Story 3

- [ ] T034 [P] [US3] Create domain entity/value object in src/features/[feature]/domain/[entity].*
- [ ] T035 [US3] Implement application use case in src/features/[feature]/application/[use_case].*
- [ ] T036 [US3] Implement presentation flow/screen in src/features/[feature]/presentation/[screen].*

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Documentation updates in docs/
- [ ] TXXX Code cleanup and refactoring
- [ ] TXXX Performance optimization across all stories
- [ ] TXXX [P] Additional automated tests and regression coverage in tests/
- [ ] TXXX Security hardening
- [ ] TXXX Accessibility validation across completed flows
- [ ] TXXX Mobile viewport validation for primary journeys
- [ ] TXXX SEO local and semantic metadata validation for public web surfaces
- [ ] TXXX Content review to remove placeholders, vague copy, and inconsistent clinic/loyalty-card claims
- [ ] TXXX Run quickstart.md validation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Domain/application rules before infrastructure and presentation wiring
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for [business rule] in tests/unit/test_[name].py"
Task: "UI/widget test for mobile CTA and states in tests/ui/test_[name].py"
Task: "Integration test for [user journey] in tests/integration/test_[name].py"
Task: "Accessibility check for [screen] in tests/accessibility/test_[name].py"

# Launch all models for User Story 1 together:
Task: "Create [Entity1] in src/features/[feature]/domain/[entity1].*"
Task: "Create [Entity2] in src/features/[feature]/domain/[entity2].*"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Automated tests, mobile validation, accessibility, performance, and content review are delivery gates
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
