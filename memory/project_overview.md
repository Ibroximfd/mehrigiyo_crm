---
name: project-overview
description: Mehrigiyo CRM Flutter app — architecture, features, and operator sales system implementation
metadata:
  type: project
---

Flutter CRM app for Mehrigiyo. Two systems coexist:

1. **Support system** (existing): `/support/...` endpoints — consultations, orders, dashboard.
2. **Operator Sales system** (new): `/operator/...` endpoints — full CRM with kanban, leads, admin.

**Why:** User needed the full operator sales API integrated as a complete module.
**How to apply:** New operator features live under `lib/features/operators|statuses|leads|kanban|operator_panel/`.

## Architecture
- Flutter BLoC (not Cubit), Clean Architecture, mostly Stateless widgets
- `injectable` for existing code, manual `getIt.registerFactory` for operator features in `di_setup.dart`
- `go_router` with ShellRoutes: admin shell → `/op/admin/*`, seller shell → `/op/seller/*`
- After login, `isAdmin` flag in `UserEntity` determines routing: admin → adminOperators, seller → sellerKanban

## Key routing (route_names.dart)
- `/op/admin/operators` — admin: operator list + create
- `/op/admin/leads` — admin: all leads + assign to operators
- `/op/admin/statuses` — admin: kanban status management
- `/op/admin/consultations` — admin: free consultations (arizalar)
- `/op/seller/kanban` — seller: kanban board
- `/op/seller/leads` — seller: my leads list
- `/op/seller/leads/:id` — seller: lead detail + history + status change
- `/op/seller/consultations` — seller: free consultations (arizalar)

## Auth changes
- Login: POST `/operator/login/` with `{"username": "...", "password": "..."}` (NOT phone!)
- UserEntity.phone field stores the operator's username
- UserEntity now has: isAdmin, filialId, filialName, commissionPercent, refreshToken
- Profile restored from SharedPreferences (no extra API call on startup)
- Keys: auth_token, operator_id, operator_name, operator_is_admin, operator_filial_id, operator_filial_name

## Operator entity
- Field was renamed from `phone` to `username` (API uses `username` not `phone`)
- API create: `{"full_name": "...", "username": "karimov_seller", "password": "...", "commission_percent": 10}`
- API list response has `username` field (not `phone`)

## UI / UX
- Animated collapsible sidebar: `OpAnimatedSidebar` in `lib/features/operator_panel/presentation/widgets/op_animated_sidebar.dart`
  - Starts expanded (240px), collapses to icon-only (64px) with toggle button
  - Used in both admin and seller desktop layouts
- Consultations (Arizalar) tab added to BOTH admin and seller panels with badge count
- All operator pages use neutral `Color(0xFFF8FAFC)` background (not greenish AppColors.background)
- Modern color palette: slate-900 for text, slate-500 for secondary, slate-400 for muted
- Cards: white with subtle shadow (`0x08000000` at 8px blur)

## Bug fixes applied
- `main.dart`: Fixed AuthUnauthenticated routing — now goes to `login` (was wrongly going to `adminOperators`)
- `auth_remote_data_source.dart`: Login payload uses `username` key (was `phone`)
- `login_form_widget.dart`: Label changed to "Login", keyboard type changed to text
- `operator_remote_data_source.dart`: Create payload uses `username` key (was `phone`)
