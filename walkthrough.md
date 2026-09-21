# TRANSITION / SIH 2026: Frontend & Backend Integration Walkthrough

## Overview
We have integrated the Flutter frontend with the live FastAPI backend (`https://sih-a24k.onrender.com`) and Supabase Authentication. The monolithic `lib/main.dart` (~2,000 lines) was refactored into a scalable, clean layered Flutter architecture without altering the visual design, typography, or styling of any screen.

---

## Key Changes & Architecture

### 1. Project Architecture
```
lib/
├── main.dart                                   # Clean entrypoint with session restore & route dispatch
├── core/
│   ├── config/app_config.dart                  # API Base URL & Supabase credentials configuration
│   ├── networking/
│   │   ├── api_client.dart                     # REST Client with auto-attached Bearer JWT & timeouts
│   │   └── api_exception.dart                  # Structured HTTP error handling
│   ├── auth/auth_manager.dart                  # Supabase session manager & auth state notifier
│   ├── routing/app_view.dart                   # Screen view enumeration
│   └── services/service_locator.dart           # Centralized dependency container
├── models/
│   ├── profile.dart                            # ProfileModel & ProfileCreate
│   ├── issue.dart                              # IssueModel, IssueMediaModel, IssueCreate, IssueListResponse
│   ├── application.dart                        # ApplicationModel & ApplicationCreate
│   ├── solution.dart                           # SolutionModel & SolutionReviewModel
│   ├── evidence.dart                           # EvidenceModel & EvidenceCreate
│   ├── sponsorship.dart                        # SponsorshipModel & SponsorshipCreate
│   └── dashboard.dart                          # Citizen, Student, and Industry Dashboard models
├── services/
│   ├── profile_service.dart                    # GET /profiles/me, POST /profiles/me, PATCH /profiles/me
│   ├── issue_service.dart                      # GET & POST /issues, media attachment, filter queries
│   ├── application_service.dart                # POST /issues/{id}/applications, assign student
│   ├── solution_service.dart                   # Submit solutions & reviews
│   ├── evidence_service.dart                   # Upload photographic evidence & milestones
│   ├── sponsorship_service.dart                # Pledge grants & update sponsorships
│   └── dashboard_service.dart                  # GET /dashboard/{citizen,student,industry}
├── screens/
│   ├── common/
│   │   ├── landing_screen.dart                 # Welcome Screen & Civic Tech overview
│   │   ├── role_selection_screen.dart          # Role selection connected to authenticated profile
│   │   └── auth_dialog.dart                    # Email/Password sign in, sign up, & 1-click demo roles
│   ├── citizen/
│   │   ├── citizen_dashboard_screen.dart       # Live metrics, search, map ops, my reports
│   │   ├── citizen_report_wizard_screen.dart   # 5-step wizard: camera, description, GPS, AI check, submit
│   │   ├── citizen_geofence_screen.dart        # Geofenced problem verification & karma
│   │   └── problem_detail_screen.dart          # Docket details, impact vector, lifecycle milestones
│   ├── student/
│   │   ├── student_dashboard_screen.dart       # Live metrics, challenge discovery
│   │   ├── student_application_screen.dart     # Proposal submission to mentors
│   │   ├── student_workspace_screen.dart       # Assigned issue workspace & checklist
│   │   └── student_evidence_screen.dart        # Dual-proof photographic audit submission
│   └── industrialist/
│       ├── industrialist_dashboard_screen.dart # Industry metrics, vetted interventions
│       ├── squad_selection_screen.dart         # Review student proposals & assign squads
│       ├── live_feed_screen.dart               # Live mentor-student workspace feed & guidance
│       └── audit_verdict_screen.dart           # Independent audit verdict (Resolved, Rework, Disputed)
└── widgets/
    ├── app_top_bar.dart                        # Dark header with role switcher & auth profile badge
    ├── role_navigation_bar.dart                # Bottom navigation bar adapted for active role
    ├── stat_boxes.dart                         # StatBox and StatBoxSmall components
    └── state_views.dart                        # LoadingView, ErrorView, EmptyView
```

---

## 2. Workflows Integrated

### Citizen Workflow
- **Dashboard**: Retrieves real analytics (`GET /dashboard/citizen`) and citizen's submitted reports (`GET /issues/me/reported`).
- **Reporting Wizard**:
  - Step 1: Real photo capture/selection via `ImagePicker`.
  - Step 2: Form validation for title, description, category, and priority.
  - Step 3: Real GPS coordinates acquired via `Geolocator` with location permission checks and address preview.
  - Step 4: AI verification preview.
  - Step 5: Submits via `POST /issues` and `POST /issues/{issue_id}/media`, receiving an actual backend Issue UUID.
- **Tracking**: Real issue details (`GET /issues/{issue_id}`) with live 9-stage lifecycle milestone audit.

### Student Workflow
- **Dashboard**: Retrieves real metrics (`GET /dashboard/student`) and explores active challenges (`GET /issues`).
- **Application**: Submits proposals directly to the backend via `POST /issues/{issue_id}/applications`.
- **Workspace**: Fetches student-assigned issues (`GET /issues/me/assigned`) with interactive checklist items.
- **Evidence**: Captures resolved after-evidence via camera/gallery and submits milestone documentation via `POST /issues/{issue_id}/evidence`.

### Industrialist Workflow
- **Dashboard**: Retrieves live patronage metrics (`GET /dashboard/industry`) and vetted civic interventions.
- **Squad Selection**: Inspects candidate applicant proposals (`GET /issues/{issue_id}/applications`) and assigns the student via `POST /issues/{issue_id}/assign`.
- **Sponsorship**: Locks grant funding into escrow via `POST /issues/{issue_id}/sponsorships`.
- **Live Feed & Audit**: Submits mentor guidance, reviews student evidence, and updates issue status to `RESOLVED` on the backend.

---

## 3. Verification & Testing

### Static Analysis
```bash
flutter analyze
```
**Result**: `No issues found! (ran in 1.9s)` — 0 errors, 0 warnings, 0 lints.

### Unit Tests
```bash
flutter test
```
**Result**:
- `ProfileModel Tests`: ProfileModel parses from JSON correctly & ProfileCreate serializes
- `IssueModel Tests`: Full JSON parsing with nested media & IssueCreate serialization
- `Application & Solution Tests`: ApplicationModel, SolutionModel, and SolutionReviewModel parsing
- `Evidence & Sponsorship Tests`: EvidenceModel and SponsorshipModel parsing
- `Dashboard Models Tests`: Citizen, Student, and Industry dashboard counters parsing
- `ApiException Tests`: Correct identification of 401, 403, 404, 422, and network errors
**12 / 12 tests passed!**

---

## How to Run
```bash
# Run on connected device (Android, Chrome, or Windows)
flutter run

# Or pass custom Supabase environment variables if desired:
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-key
```
