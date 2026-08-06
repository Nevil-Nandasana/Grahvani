# Authorization & Entitlements Specification

> [[Backend Index](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/README.md) | [Authentication Specs](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/AUTHENTICATION.md) | [Entitlements Engine](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/billing/ENTITLEMENTS.md)]

---

## 1. Overview & Dual-Layer Access Control

Authorization in **Grahvani** is enforced through a dual-layer model:
1. **Role-Based Access Control (RBAC)**: Regulates administrative, editorial, and system operations across application roles (`user`, `editor`, `admin`).
2. **Entitlement-Based Access Control (EBAC)**: Regulates feature access and query quota limits based on the user's subscription tier (`free`, `premium`, `astrologer`).

---

## 2. Role-Based Access Control (RBAC) Matrix

| Application Role | Description & Permissions |
| :--- | :--- |
| **`user`** (Default) | Standard end-user. Can manage own birth profiles, request chart calculations, participate in AI chat sessions, and purchase subscriptions. |
| **`editor`** | Content manager. Can upload, edit, and review classical text document chunks, sloka translations, and knowledge base sources. Cannot access user private charts or billing administration. |
| **`admin`** | Superuser / Operations lead. Full access to user management, system metrics, background task management, entitlement overrides, and security audit logs. |

---

## 3. Tiered Feature Entitlement Matrix

| Feature / Resource | Free Tier (`free`) | Premium Tier (`premium`) | Professional (`astrologer`) |
| :--- | :---: | :---: | :---: |
| **Saved Birth Profiles** | Max 3 profiles | Max 25 profiles | Unlimited |
| **D1 & D9 Chart Generation** | Unlimited | Unlimited | Unlimited |
| **Divisional Charts (D2-D60)** | Basic (D1, D9) | Full (D1 through D60) | Full + Custom Ayanamsa |
| **Daily Grounded AI Chat Queries** | 5 queries / day | 50 queries / day | 500 queries / day |
| **High-Precision PDF Export** | Watermarked | High-res Clean PDF | White-labeled Custom PDF |
| **Vimshottari Dasha Depth** | Major Dasha only | Antardasha + Pratyantardasha | Full 5-level Dasha breakdown |

---

## 4. FastAPI Policy Dependency Implementation

```python
# Location: services/api/security/authorization.py
from fastapi import HTTPException, Depends, status
from services.api.security.auth import get_current_user
from services.api.database import get_db_session

def require_role(required_role: str):
    """FastAPI dependency enforcing application RBAC role checks."""
    async def role_checker(current_user: dict = Depends(get_current_user)):
        user_role = current_user.get("role", "user")
        if user_role != required_role and user_role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Action requires '{required_role}' administrative privileges."
            )
        return current_user
    return role_checker

async def check_profile_ownership(profile_id: str, current_user: dict, db_session):
    """Enforces multi-tenant data isolation: users may only access their own profiles."""
    profile = await db_session.get_profile(profile_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found.")
    if profile.user_id != current_user["user_id"] and current_user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You do not have permission to access this birth profile."
        )
    return profile
```

---

## 5. Multi-Tenant Data Isolation Rules

- **Database-Level Filter**: All user entity read/write queries MUST include `WHERE user_id = :current_user_id` to guarantee tenant data isolation.
- **Admin Override Auditing**: Any admin access to non-owned resources is explicitly logged to security audit logs ([Security Setup](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/infrastructure/SECURITY.md)).

---

## 6. Related Documents

- [Authentication Specs](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/backend/AUTHENTICATION.md) — Firebase JWT verification and user identity extraction.
- [Entitlements Engine](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/billing/ENTITLEMENTS.md) — Subscription tier entitlement engine rules.
- [Database Security](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/security/THREAT_MODEL.md) — Multi-tenant threat mitigations.
