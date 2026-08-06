"""Backend API unit test — validates push notification FCM token & preference endpoints."""
import pytest
from app.modules.notifications.router import (
    FCMTokenRequest,
    NotificationPreferencesRequest,
    NotificationPreferencesResponse,
    ProfileNotificationStatusResponse,
)


class TestNotificationEngine:
    """Test suite for notification schema validation and preference models."""

    def test_fcm_token_request_validation(self):
        """Verifies FCM token request model accepts valid token string."""
        req = FCMTokenRequest(fcm_token="sample_fcm_token_string_1234567890")
        assert req.fcm_token == "sample_fcm_token_string_1234567890"

    def test_fcm_token_too_short_raises_validation_error(self):
        """FCM token shorter than 10 characters raises error."""
        with pytest.raises(ValueError):
            FCMTokenRequest(fcm_token="short")

    def test_notification_preferences_request_partial_update(self):
        """Verifies partial preference update fields."""
        req = NotificationPreferencesRequest(transit_alerts=False, quiet_hours_start="23:00")
        dump = req.model_dump(exclude_unset=True)
        assert dump == {"transit_alerts": False, "quiet_hours_start": "23:00"}
        assert "dasha_alerts" not in dump

    def test_profile_notification_status_response_schema(self):
        """Verifies full notification status response serialization."""
        response = ProfileNotificationStatusResponse(
            profile_id="123e4567-e89b-12d3-a456-426614174000",
            profile_name="John Doe",
            notification_enabled=True,
            preferences=NotificationPreferencesResponse(
                transit_alerts=True,
                sade_sati_alerts=True,
                dasha_alerts=False,
                major_transit_alerts=True,
                quiet_hours_start="22:00",
                quiet_hours_end="07:00",
                last_sade_sati_notification={},
                last_dasha_notification="",
            ),
        )
        assert response.notification_enabled is True
        assert response.preferences.dasha_alerts is False
        assert response.preferences.quiet_hours_start == "22:00"
