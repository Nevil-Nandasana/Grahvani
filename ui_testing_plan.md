# Grahvani UI Testing Plan

## Purpose
Test the AI model integration, fallback mechanism, and rate limiting in the Grahvani Flutter mobile app.

## Prerequisites
- Flutter SDK installed
- Android/iOS emulator or physical device
- Grahvani backend running with Redis
- API keys configured for both Google Gemini and NVIDIA

## Test Environment Setup

### 1. Configure API Keys
Edit `.env` file in the API service:
```env
# Primary provider (Google Gemini)
GEMINI_API_KEY=your_google_api_key
LLM_PROVIDER=google
LLM_MODEL_NAME=gemini-2.0-flash

# Fallback provider (NVIDIA)
NVIDIA_API_KEY=your_nvidia_api_key
NVIDIA_MODEL_NAME=nvidia/nemotron-3-ultra-550b-instruct
LLM_FALLBACK_PROVIDER=nvidia
```

### 2. Start Backend Services
```bash
cd services/api
docker compose up db redis -d
poetry run alembic upgrade head
poetry run uvicorn app.main:app --reload
```

### 3. Start Flutter App
```bash
cd apps/mobile
flutter pub get
flutter run
```

## Test Cases

### Test Case 1: Normal Operation (Google Gemini)
**Objective**: Verify primary provider works correctly

1. Launch the Flutter app
2. Navigate to the Chat feature
3. Select a birth chart
4. Ask an astrology question (e.g., "What does my Sun sign mean?")
5. Verify:
   - Response streams correctly
   - Citations are shown
   - Response is grounded in classical texts
   - No errors in console

### Test Case 2: API Billing Error Fallback
**Objective**: Verify fallback to NVIDIA when Google Gemini fails

**Method 1: Simulate Billing Error**
1. Temporarily set an invalid Google Gemini API key
2. Ask an astrology question
3. Verify:
   - Error message appears briefly
   - System automatically switches to NVIDIA
   - Response is received from NVIDIA model
   - Response quality is acceptable

**Method 2: Force Fallback via Code**
1. Temporarily modify `llm_provider.py` to always raise `BillingError`
2. Ask an astrology question
3. Verify fallback behavior

### Test Case 3: Rate Limiting (40 requests per minute)
**Objective**: Verify rate limiting works as requested

1. Rapidly send 40+ questions within 60 seconds
2. Verify:
   - First 40 requests succeed
   - 41st request gets rate limit error
   - Error message: "Rate limit exceeded. Maximum 40 requests per minute."
   - After 60 seconds, requests work again

### Test Case 4: UI Error Handling
**Objective**: Verify UI gracefully handles errors

1. Simulate various error conditions:
   - API billing error
   - Rate limit exceeded
   - Network error
   - Server error
2. Verify:
   - User-friendly error messages
   - Retry options where appropriate
   - No crashes or blank screens

## Test Scripts

### Script 1: Automated Rate Limit Testing
```dart
// test/rate_limit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:grahvani/features/chat/services/chat_service.dart';

void main() {
  test('Rate limit test - 40 requests per minute', () async {
    final chatService = ChatService();
    final testPrompt = "Test question";
    
    // Send 40 requests (should succeed)
    for (int i = 1; i <= 40; i++) {
      final response = await chatService.sendMessage(testPrompt);
      expect(response.success, true, reason: "Request $i should succeed");
    }
    
    // 41st request should fail with rate limit error
    try {
      await chatService.sendMessage(testPrompt);
      fail("41st request should have failed");
    } catch (e) {
      expect(e.toString(), contains("Rate limit exceeded"));
    }
  });
}
```

### Script 2: Fallback Mechanism Testing
```dart
// test/fallback_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:grahvani/features/chat/services/chat_service.dart';

void main() {
  test('Fallback test - Google Gemini to NVIDIA', () async {
    final chatService = ChatService();
    
    // Force billing error by using invalid API key temporarily
    // This would be done by modifying the backend configuration
    
    final response = await chatService.sendMessage("Test fallback question");
    
    // Should succeed despite primary provider failure
    expect(response.success, true);
    expect(response.provider, "nvidia"); // Verify fallback provider
  });
}
```

## Expected Results

| Test Case | Expected Result |
|-----------|-----------------|
| Normal Operation | ✅ Successful response from Google Gemini |
| API Billing Fallback | ✅ Automatic switch to NVIDIA, successful response |
| Rate Limiting | ✅ First 40 requests succeed, 41st fails with clear error |
| UI Error Handling | ✅ User-friendly error messages, no crashes |

## Troubleshooting

### Issue: Fallback not working
- **Check**: NVIDIA API key is valid and has credits
- **Check**: `LLM_FALLBACK_PROVIDER` is set to "nvidia"
- **Check**: Backend logs for error details
- **Check**: Network connectivity to NVIDIA API

### Issue: Rate limiting not working
- **Check**: Redis is running and accessible
- **Check**: Rate limit keys are being created in Redis
- **Check**: `REDIS_URL` is correctly configured
- **Check**: Rate limit window (60 seconds) is respected

### Issue: UI not showing responses
- **Check**: WebSocket/SSE connection is established
- **Check**: Flutter app has proper error handling
- **Check**: Backend is streaming responses correctly
- **Check**: Network permissions in mobile app

## Next Steps
1. Run the backend with the new configuration
2. Execute the test cases
3. Verify all requirements are met:
   - ✅ API billing fallback mechanism
   - ✅ 40 requests per minute rate limiting
   - ✅ UI testing with manual model loading
4. Monitor logs for any issues
5. Collect user feedback on response quality