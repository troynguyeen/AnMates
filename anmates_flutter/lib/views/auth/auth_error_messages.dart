/// Maps `FirebaseAuthException.code` to a user-facing Vietnamese message.
/// Codes catalog: https://firebase.google.com/docs/auth/admin/errors
String friendlyPhoneAuthError(String code) {
  switch (code) {
    case 'invalid-phone-number':
      return 'Số điện thoại không hợp lệ.';
    case 'invalid-verification-code':
      return 'Mã OTP không đúng. Kiểm tra lại.';
    case 'session-expired':
      return 'Mã OTP đã hết hạn. Gửi lại.';
    case 'too-many-requests':
      return 'Quá nhiều yêu cầu. Thử lại sau vài phút.';
    case 'quota-exceeded':
      return 'Hạn mức SMS đã hết. Liên hệ hỗ trợ.';
    case 'captcha-check-failed':
      return 'reCAPTCHA thất bại. Thử lại.';
    case 'app-not-authorized':
    case 'invalid-app-credential':
      return 'App chưa được uỷ quyền. Liên hệ hỗ trợ.';
    case 'network-request-failed':
      return 'Mất kết nối mạng. Thử lại.';
    default:
      return 'Không xác thực được ($code).';
  }
}
