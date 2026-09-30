import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  arabic,
}

class AppLocalizations {
  static final ValueNotifier<AppLanguage> currentLanguage =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  static bool get isArabic => currentLanguage.value == AppLanguage.arabic;
  static TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  static void toggleLanguage() {
    currentLanguage.value = isArabic ? AppLanguage.english : AppLanguage.arabic;
  }

  static void setLanguage(AppLanguage language) {
    currentLanguage.value = language;
  }

  static final Map<String, Map<AppLanguage, String>> _localizedValues = {
    // App Header & Branding
    'app_title': {
      AppLanguage.english: 'PAL-DFI Citizen & Student Wallet',
      AppLanguage.arabic: 'محفظة الهوية الأكاديمية - جامعة نابلس',
    },
    'sub_title': {
      AppLanguage.english: 'Nablus University for Vocational & Technical Education (NUVTE)',
      AppLanguage.arabic: 'جامعة نابلس للتعليم المهني والتقني (NUVTE)',
    },
    'sandbox_badge': {
      AppLanguage.english: 'PMA Regulatory Sandbox Pilot',
      AppLanguage.arabic: 'بيئة تجريبية لسلطة النقد الفلسطينية',
    },
    'zero_pii_badge': {
      AppLanguage.english: 'Strict Zero On-Chain PII',
      AppLanguage.arabic: 'صفر بيانات شخصية على البلوكشين',
    },

    // ID+ by PMA
    'id_plus_title': {
      AppLanguage.english: 'ID+ by Palestine Monetary Authority',
      AppLanguage.arabic: 'نظام الهوية الرقمية الموحد ID+ (سلطة النقد الفلسطينية)',
    },
    'id_plus_login_desc': {
      AppLanguage.english: 'Decentralized Sovereign National ID Login. No registration needed.',
      AppLanguage.arabic: 'تسجيل دخول سيادي وموحد بالهوية الوطنية الرقمية. لا حاجة لإنشاء حساب.',
    },
    'login_as_student': {
      AppLanguage.english: 'Login as Citizen / Student',
      AppLanguage.arabic: 'الدخول كهوية طالب / مواطن',
    },
    'login_as_management': {
      AppLanguage.english: 'Login as University Management',
      AppLanguage.arabic: 'الدخول كمسؤول إدارة الجامعة (المسجل)',
    },
    'login_as_third_party': {
      AppLanguage.english: 'Login as Third-Party Verifier (Bank / Employer)',
      AppLanguage.arabic: 'الدخول كجهة تحقق خارجية (بنك / جهة توظيف)',
    },
    'authenticated_pma': {
      AppLanguage.english: 'Authenticated via PMA ID+ Enclave',
      AppLanguage.arabic: 'موثق عبر خوادم الهوية الرقمية لسلطة النقد',
    },

    // Modes & Portals
    'mode_student': {
      AppLanguage.english: 'Student Wallet',
      AppLanguage.arabic: 'محفظة الطالب',
    },
    'mode_registrar': {
      AppLanguage.english: 'University Management',
      AppLanguage.arabic: 'إدارة الجامعة',
    },
    'mode_verifier': {
      AppLanguage.english: 'Third-Party Verifier',
      AppLanguage.arabic: 'جهة التحقق (طرف ثالث)',
    },

    // Documents
    'doc_student_id': {
      AppLanguage.english: 'Student ID Card',
      AppLanguage.arabic: 'بطاقة الطالب',
    },
    'doc_graduation': {
      AppLanguage.english: 'Graduation Certificate',
      AppLanguage.arabic: 'شهادة التخرج',
    },
    'doc_clearance': {
      AppLanguage.english: 'Certificate of Discharge',
      AppLanguage.arabic: 'شهادة براءة الذمة',
    },

    // Document Details
    'digital_student_card': {
      AppLanguage.english: 'DIGITAL STUDENT IDENTITY',
      AppLanguage.arabic: 'بطاقة الطالب الرقمية المعتمدة',
    },
    'graduation_diploma': {
      AppLanguage.english: 'OFFICIAL DEGREE DIPLOMA',
      AppLanguage.arabic: 'شهادة الدرجة الجامعية المعتمدة',
    },
    'clearance_title': {
      AppLanguage.english: 'CERTIFICATE OF UNIVERSITY DISCHARGE',
      AppLanguage.arabic: 'شهادة براءة ذمة جامعية شاملة',
    },
    'student_id': {
      AppLanguage.english: 'Student ID',
      AppLanguage.arabic: 'رقم الطالب',
    },
    'full_name': {
      AppLanguage.english: 'Full Name',
      AppLanguage.arabic: 'الاسم الكامل',
    },
    'faculty': {
      AppLanguage.english: 'Faculty',
      AppLanguage.arabic: 'الكلية',
    },
    'program': {
      AppLanguage.english: 'Program & Major',
      AppLanguage.arabic: 'التخصص والبرنامج',
    },
    'degree': {
      AppLanguage.english: 'Degree Level',
      AppLanguage.arabic: 'الدرجة العلمية',
    },
    'status': {
      AppLanguage.english: 'Status',
      AppLanguage.arabic: 'حالة الاعتماد',
    },
    'status_active': {
      AppLanguage.english: 'ACTIVE / VERIFIED',
      AppLanguage.arabic: 'نشط وموثق',
    },
    'status_revoked': {
      AppLanguage.english: 'REVOKED ON-CHAIN',
      AppLanguage.arabic: 'ملغى في البلوكشين',
    },
    'status_expired': {
      AppLanguage.english: 'EXPIRED',
      AppLanguage.arabic: 'منتهي الصلاحية',
    },
    'honors_classification': {
      AppLanguage.english: 'Honors Classification',
      AppLanguage.arabic: 'التقدير ومرتبة الشرف',
    },
    'deans_resolution': {
      AppLanguage.english: 'Deans Council Resolution',
      AppLanguage.arabic: 'قرار مجلس العمداء',
    },
    'clearance_departments': {
      AppLanguage.english: 'Cleared University Departments',
      AppLanguage.arabic: 'الدوائر الجامعية المستوفاة',
    },

    // Quick Actions
    'action_present': {
      AppLanguage.english: 'Share Document',
      AppLanguage.arabic: 'مشاركة الوثيقة',
    },
    'action_scan_issuance': {
      AppLanguage.english: 'Claim Credential',
      AppLanguage.arabic: 'استلام وثيقة جديدة',
    },
    'action_inspect': {
      AppLanguage.english: 'Inspect Proof',
      AppLanguage.arabic: 'فحص التشفير',
    },

    // 3-Step Sharing & Third-Party Requests
    'incoming_requests': {
      AppLanguage.english: 'Incoming Third-Party Requests',
      AppLanguage.arabic: 'طلبات الاعتماد الواردة من جهات خارجية',
    },
    'request_from': {
      AppLanguage.english: 'Request From',
      AppLanguage.arabic: 'طلب وارد من',
    },
    'request_purpose': {
      AppLanguage.english: 'Verification Purpose',
      AppLanguage.arabic: 'الغرض من التحقق',
    },
    'authorize_and_share': {
      AppLanguage.english: 'Authorize & Share Document',
      AppLanguage.arabic: 'الموافقة ومشاركة الوثيقة المشفرة',
    },
    'reject_request': {
      AppLanguage.english: 'Reject Request',
      AppLanguage.arabic: 'رفض الطلب',
    },
    'request_authorized_msg': {
      AppLanguage.english: 'Document decrypted from secure vault and shared with verifier!',
      AppLanguage.arabic: 'تم فك تشفير الوثيقة من الخزنة ومشاركتها مع جهة التحقق بنجاح!',
    },

    // Presentation (OpenID4VP)
    'presentation_title': {
      AppLanguage.english: 'Dynamic Verifiable Presentation',
      AppLanguage.arabic: 'إبراز هوية مؤمن ومحدد بوقت',
    },
    'presentation_instruction': {
      AppLanguage.english: 'Present this dynamic QR code to verifiers. It updates every 60 seconds with fresh nonces.',
      AppLanguage.arabic: 'أظهر هذا الرمز المتجدد لجهة التحقق. يتجدد الرمز تلقائياً كل 60 ثانية مع مفاتيح أمان جديدة.',
    },
    'time_remaining': {
      AppLanguage.english: 'Dynamic Token Refresh in',
      AppLanguage.arabic: 'تجديد الرمز الآمن خلال',
    },
    'seconds': {
      AppLanguage.english: 'sec',
      AppLanguage.arabic: 'ثانية',
    },

    // Verifier Mode
    'verifier_title': {
      AppLanguage.english: 'Third-Party Verification Gateway',
      AppLanguage.arabic: 'بوابة التحقق للجهات الخارجية والمعتمدة',
    },
    'step_1_title': {
      AppLanguage.english: 'Step 1: Request Document from Student',
      AppLanguage.arabic: 'الخطوة 1: إرسال طلب اعتماد إلى الطالب',
    },
    'step_2_title': {
      AppLanguage.english: 'Step 2: Student Authorization & Vault Decryption',
      AppLanguage.arabic: 'الخطوة 2: موافقة الطالب وفك تشفير الوثيقة',
    },
    'step_3_title': {
      AppLanguage.english: 'Step 3: Real-Time Blockchain Verification (<3.0s)',
      AppLanguage.arabic: 'الخطوة 3: التحقق الفوري عبر البلوكشين (أقل من 3 ثوان)',
    },
    'verification_passed': {
      AppLanguage.english: 'CRYPTOGRAPHICALLY VALID & VERIFIED ON-CHAIN',
      AppLanguage.arabic: 'وثيقة صحيحة وموثقة تشفيرياً على البلوكشين',
    },
    'verification_failed_revoked': {
      AppLanguage.english: 'CREDENTIAL REVOKED ON LEDGER',
      AppLanguage.arabic: 'الوثيقة ملغاة على سجل البلوكشين',
    },
    'verification_failed_tampered': {
      AppLanguage.english: 'SIGNATURE TAMPER DETECTED',
      AppLanguage.arabic: 'تم اكتشاف تلاعب في التوقيع الرقمي',
    },

    // University Management Mode
    'registrar_title': {
      AppLanguage.english: 'NUVTE University Management Portal',
      AppLanguage.arabic: 'بوابة إدارة جامعة نابلس (العمادة والمسجل)',
    },
    'issue_documents_title': {
      AppLanguage.english: 'Issue Official University Documents',
      AppLanguage.arabic: 'إصدار الوثائق الجامعية المعتمدة',
    },
    'issue_id_card': {
      AppLanguage.english: 'Issue Student ID Card',
      AppLanguage.arabic: 'إصدار بطاقة طالب',
    },
    'issue_grad_cert': {
      AppLanguage.english: 'Issue Graduation Certificate',
      AppLanguage.arabic: 'إصدار شهادة تخرج',
    },
    'issue_clearance_cert': {
      AppLanguage.english: 'Issue Certificate of Discharge',
      AppLanguage.arabic: 'إصدار شهادة براءة ذمة',
    },
    'toggle_revocation': {
      AppLanguage.english: 'Toggle Revocation on Hyperledger',
      AppLanguage.arabic: 'تغيير حالة الإلغاء على البلوكشين',
    },
  };

  static String tr(String key) {
    final lang = currentLanguage.value;
    final map = _localizedValues[key];
    if (map != null && map.containsKey(lang)) {
      return map[lang]!;
    }
    return key;
  }
}
