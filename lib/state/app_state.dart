import 'package:intl/intl.dart';

import '../data/models/access_log_entry.dart';
import '../data/models/announcement.dart';
import '../data/models/complaint_item.dart';
import '../data/models/dues_entry.dart';
import '../data/models/levy.dart';
import '../data/models/meeting.dart';
import '../data/models/my_pledge.dart';
import '../data/models/notification_item.dart';
import '../data/models/person.dart';
import '../data/models/poll.dart';
import '../data/models/project.dart';
import '../data/models/rules_section.dart';
import '../data/models/session_info.dart';
import '../data/models/spotlight.dart';
import '../data/models/tts_voice_option.dart';
import '../data/models/utility_meter.dart';
import '../data/models/utility_purchase.dart';
import '../data/models/visitor_pass.dart';

enum AuthStage {
  bootstrapping,
  welcome,
  estateCode,
  estateFound,
  login,
  forgot,
  otp,
  newPassword,
  resetSuccess,
  forceReset,
  onboardingComplete,
  app,
  locked,
}

enum Role { resident, guard }

enum PaymentStep { idle, processing, success }

enum VoiceStage { idle, listening, processing, error }

String formatNaira(int amount) => '₦${NumberFormat('#,##0').format(amount)}';

class GuardResult {
  const GuardResult({required this.pass, required this.valid, this.reason});

  final VisitorPass? pass;
  final bool valid;
  final String? reason;
}

class AppState {
  AppState({
    this.authStage = AuthStage.bootstrapping,
    this.role = Role.resident,
    this.isLoading = false,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
    this.currentUser,
    this.estateName,
    this.estateAddress,
    this.estateImage,
    this.estateLocked = false,
    this.estateCodeInput = '',
    this.estateCodeError = '',
    this.estateCodeLoading = false,
    this.pendingEstateCode,
    this.pendingEstateName,
    this.pendingEstateAddress,
    this.pendingEstateImage,
    this.pendingEstateManagedBy,
    this.pendingEstateResidentCount,
    this.loginPhone = '',
    this.loginPassword = '',
    this.loginError = '',
    this.rememberMe = true,
    this.forgotPhone = '',
    this.otpCode = '',
    this.devOtp,
    this.resetToken,
    this.newPass1 = '',
    this.newPass2 = '',
    this.resetMsg = '',
    this.setupFullName = '',
    this.setupHouse = '',
    this.setupEmail = '',
    this.setupEmergencyContactName = '',
    this.setupEmergencyContactPhone = '',
    this.setupVehiclePlates = '',
    this.vfName = '',
    this.vfPhone = '',
    this.vfPlate = '',
    this.vfError = '',
    List<VisitorPass>? visitorPasses,
    this.paymentStep = PaymentStep.idle,
    this.paymentReference,
    this.duesBalance = 0,
    this.duesMonthsPaid = 0,
    this.walletBalance = 0,
    this.historyFilterMonth,
    this.historyFilterYear,
    this.voiceStage = VoiceStage.idle,
    this.voiceTranscript = '',
    this.voiceResponse = '',
    this.voiceNavigationTarget,
    this.pendingAuthorizationFor,
    this.selectedVoice,
    List<TtsVoiceOption>? availableVoices,
    List<DuesEntry>? duesHistory,
    this.guardCode = '',
    this.guardResult,
    List<AccessLogEntry>? accessLog,
    this.allNotifsRead = true,
    this.complaintCategory = 'Maintenance',
    this.complaintDesc = '',
    this.complaintError = '',
    this.complaintRef = '',
    List<Levy>? levies,
    List<Announcement>? announcements,
    List<Meeting>? meetings,
    List<Project>? projects,
    List<Poll>? polls,
    List<NotificationItem>? notifications,
    List<RulesSection>? rulesSections,
    List<MyPledge>? myPledges,
    List<ComplaintItem>? complaints,
    List<SessionInfo>? sessions,
    this.spotlight,
    this.utilityLoading = false,
    this.utilityError = '',
    this.airtimeNetwork = '',
    this.airtimePhone = '',
    this.airtimeAmount = '',
    this.elecDiscoCode = '',
    this.elecDiscoName = '',
    this.elecMeterNumber = '',
    this.elecMeterType = 'PREPAID',
    this.elecPhone = '',
    this.elecAmount = '',
    this.elecAmountPrefilled = false,
    this.elecVerifiedName,
    this.elecVerifiedAddress,
    List<UtilityMeter>? utilityMeters,
    List<UtilityPurchase>? utilityPurchases,
    this.lastUtilityPurchase,
    List<Disco>? discos,
  }) : visitorPasses = visitorPasses ?? [],
       sessions = sessions ?? [],
       duesHistory = duesHistory ?? [],
       accessLog = accessLog ?? [],
       levies = levies ?? [],
       announcements = announcements ?? [],
       meetings = meetings ?? [],
       projects = projects ?? [],
       polls = polls ?? [],
       notifications = notifications ?? [],
       rulesSections = rulesSections ?? [],
       myPledges = myPledges ?? [],
       complaints = complaints ?? [],
       utilityMeters = utilityMeters ?? [],
       utilityPurchases = utilityPurchases ?? [],
       discos = discos ?? [],
       availableVoices = availableVoices ?? [];

  final AuthStage authStage;
  final Role role;
  final bool isLoading;

  /// Whether this resident/guard has opted into Face ID/Touch ID unlock,
  /// and whether this device even supports it (drives whether the toggle
  /// shows on the profile page at all).
  final bool biometricEnabled;
  final bool biometricAvailable;
  final CurrentUser? currentUser;

  final String? estateName;
  final String? estateAddress;

  /// Base64 data URL of this estate's own photo (see [ChDataMedia]) —
  /// fetched once via [pendingEstateImage] when the estate code resolves,
  /// then persisted to EstateStorage on confirm so it's available offline
  /// and doesn't need to be refetched on every launch. Null for estates
  /// that haven't uploaded one; callers fall back to a generic asset.
  final String? estateImage;

  /// True once this resident/guard has actually authenticated against this
  /// estate — a successful login, onboarding, or password reset — as
  /// opposed to merely having entered/confirmed an estate code. Once set,
  /// this device is considered bound to that estate and the "Change"
  /// option on the login screen stops being offered.
  final bool estateLocked;
  final String estateCodeInput;
  final String estateCodeError;
  final bool estateCodeLoading;

  /// Set once [submitEstateCode] finds a match, cleared once the resident
  /// either confirms (→ actually persisted via EstateStorage) or backs out
  /// to try a different code — this is deliberately separate from
  /// [estateName]/[estateCodeInput] so nothing is committed to storage
  /// until the "Estate found" screen is confirmed.
  final String? pendingEstateCode;
  final String? pendingEstateName;
  final String? pendingEstateAddress;
  final String? pendingEstateImage;
  final String? pendingEstateManagedBy;
  final int? pendingEstateResidentCount;

  final String loginPhone;
  final String loginPassword;
  final String loginError;

  /// Off means only the access token gets persisted, not the refresh
  /// token (see AppNotifier.doLogin) — the session then dies with the
  /// 15-minute access token instead of silently renewing indefinitely.
  final bool rememberMe;

  final String forgotPhone;
  final String otpCode;
  final String? devOtp;
  final String? resetToken;
  final String newPass1;
  final String newPass2;
  final String resetMsg;

  final String setupFullName;
  final String setupHouse;
  final String setupEmail;
  final String setupEmergencyContactName;
  final String setupEmergencyContactPhone;
  final String setupVehiclePlates;

  final String vfName;
  final String vfPhone;
  final String vfPlate;
  final String vfError;
  final List<VisitorPass> visitorPasses;

  final PaymentStep paymentStep;
  final String? paymentReference;
  final int duesBalance;

  /// How many months of dues have been paid so far in the current dues
  /// year — computed server-side (`computeDuesAccrual`), resets each
  /// calendar year. Answers the voice assistant's "how many months have I
  /// paid" question.
  final int duesMonthsPaid;
  final int walletBalance;

  /// Set by voice's "how much electricity did I buy in [month]" intent so
  /// `UtilityHistoryPage` can show a filtered/summed view — null means "no
  /// filter, show everything" (the page's default/manual-navigation state).
  final int? historyFilterMonth;
  final int? historyFilterYear;
  final VoiceStage voiceStage;
  final String voiceTranscript;
  final String voiceResponse;

  /// A route for [ResidentShell] to `go()` to, set by the voice pipeline
  /// once it knows enough to jump the resident straight to a real wizard
  /// screen — see [AppNotifier]'s voice dispatch.
  final String? voiceNavigationTarget;

  /// `'electricity'|'airtime'`, set by voice OR by the real Pay/Buy Airtime
  /// buttons — one field, one consumer ([ResidentShell]), so both paths run
  /// through identical authorization + execution + navigation logic.
  final String? pendingAuthorizationFor;

  /// Null means "no preference set, use the device's default TTS voice."
  final TtsVoiceOption? selectedVoice;

  /// Populated lazily (only once the voice-settings row is opened, not at
  /// bootstrap) via `flutter_tts`'s `getVoices` — filtered to English.
  final List<TtsVoiceOption> availableVoices;
  final List<DuesEntry> duesHistory;

  final String guardCode;
  final GuardResult? guardResult;
  final List<AccessLogEntry> accessLog;

  final bool allNotifsRead;
  final List<NotificationItem> notifications;

  final String complaintCategory;
  final String complaintDesc;
  final String complaintError;
  final String complaintRef;

  final List<Levy> levies;
  final List<Announcement> announcements;
  final List<Meeting> meetings;
  final List<Project> projects;
  final List<Poll> polls;
  final List<RulesSection> rulesSections;
  final List<MyPledge> myPledges;
  final List<ComplaintItem> complaints;
  final List<SessionInfo> sessions;
  final Spotlight? spotlight;

  final bool utilityLoading;
  final String utilityError;
  final List<UtilityMeter> utilityMeters;
  final List<UtilityPurchase> utilityPurchases;
  final UtilityPurchase? lastUtilityPurchase;
  final List<Disco> discos;

  final String airtimeNetwork;
  final String airtimePhone;
  final String airtimeAmount;

  final String elecDiscoCode;
  final String elecDiscoName;
  final String elecMeterNumber;
  final String elecMeterType;
  final String elecPhone;
  final String elecAmount;

  /// True only when [elecAmount] was filled in by voice before the meter
  /// steps ran — the only thing `ElectricityConfirmMeterPage`'s Proceed
  /// button checks to decide whether to skip the Amount step entirely.
  final bool elecAmountPrefilled;
  final String? elecVerifiedName;
  final String? elecVerifiedAddress;

  DuesEntry? get lastPayment {
    for (final h in duesHistory) {
      if (h.type == DuesEntryType.payment) return h;
    }
    return null;
  }

  String get duesBalanceLabel => formatNaira(duesBalance);
  String get walletBalanceLabel => formatNaira(walletBalance);
  String get duesBalanceLabelPre =>
      formatNaira(lastPayment?.amount ?? duesBalance);
  String get receiptAmountLabel => formatNaira(lastPayment?.amount ?? 0);
  String get receiptRef => 'PSK-${lastPayment?.id.toUpperCase() ?? 'N/A'}';
  int get activePassCount => visitorPasses.where((p) => p.isInside).length;

  AppState copyWith({
    AuthStage? authStage,
    Role? role,
    bool? isLoading,
    bool? biometricEnabled,
    bool? biometricAvailable,
    Object? currentUser = _sentinel,
    Object? estateName = _sentinel,
    Object? estateAddress = _sentinel,
    Object? estateImage = _sentinel,
    bool? estateLocked,
    String? estateCodeInput,
    String? estateCodeError,
    bool? estateCodeLoading,
    Object? pendingEstateCode = _sentinel,
    Object? pendingEstateName = _sentinel,
    Object? pendingEstateAddress = _sentinel,
    Object? pendingEstateImage = _sentinel,
    Object? pendingEstateManagedBy = _sentinel,
    Object? pendingEstateResidentCount = _sentinel,
    String? loginPhone,
    String? loginPassword,
    String? loginError,
    bool? rememberMe,
    String? forgotPhone,
    String? otpCode,
    Object? devOtp = _sentinel,
    Object? resetToken = _sentinel,
    String? newPass1,
    String? newPass2,
    String? resetMsg,
    String? setupFullName,
    String? setupHouse,
    String? setupEmail,
    String? setupEmergencyContactName,
    String? setupEmergencyContactPhone,
    String? setupVehiclePlates,
    String? vfName,
    String? vfPhone,
    String? vfPlate,
    String? vfError,
    List<VisitorPass>? visitorPasses,
    PaymentStep? paymentStep,
    Object? paymentReference = _sentinel,
    int? duesBalance,
    int? duesMonthsPaid,
    int? walletBalance,
    Object? historyFilterMonth = _sentinel,
    Object? historyFilterYear = _sentinel,
    VoiceStage? voiceStage,
    String? voiceTranscript,
    String? voiceResponse,
    Object? voiceNavigationTarget = _sentinel,
    Object? pendingAuthorizationFor = _sentinel,
    Object? selectedVoice = _sentinel,
    List<TtsVoiceOption>? availableVoices,
    List<DuesEntry>? duesHistory,
    String? guardCode,
    Object? guardResult = _sentinel,
    List<AccessLogEntry>? accessLog,
    bool? allNotifsRead,
    List<NotificationItem>? notifications,
    String? complaintCategory,
    String? complaintDesc,
    String? complaintError,
    String? complaintRef,
    List<Levy>? levies,
    List<Announcement>? announcements,
    List<Meeting>? meetings,
    List<Project>? projects,
    List<Poll>? polls,
    List<RulesSection>? rulesSections,
    List<MyPledge>? myPledges,
    List<ComplaintItem>? complaints,
    List<SessionInfo>? sessions,
    Object? spotlight = _sentinel,
    bool? utilityLoading,
    String? utilityError,
    List<UtilityMeter>? utilityMeters,
    List<UtilityPurchase>? utilityPurchases,
    Object? lastUtilityPurchase = _sentinel,
    List<Disco>? discos,
    String? airtimeNetwork,
    String? airtimePhone,
    String? airtimeAmount,
    String? elecDiscoCode,
    String? elecDiscoName,
    String? elecMeterNumber,
    String? elecMeterType,
    String? elecPhone,
    String? elecAmount,
    bool? elecAmountPrefilled,
    Object? elecVerifiedName = _sentinel,
    Object? elecVerifiedAddress = _sentinel,
  }) {
    return AppState(
      authStage: authStage ?? this.authStage,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      currentUser: identical(currentUser, _sentinel)
          ? this.currentUser
          : currentUser as CurrentUser?,
      estateName: identical(estateName, _sentinel)
          ? this.estateName
          : estateName as String?,
      estateAddress: identical(estateAddress, _sentinel)
          ? this.estateAddress
          : estateAddress as String?,
      estateImage: identical(estateImage, _sentinel)
          ? this.estateImage
          : estateImage as String?,
      estateLocked: estateLocked ?? this.estateLocked,
      estateCodeInput: estateCodeInput ?? this.estateCodeInput,
      estateCodeError: estateCodeError ?? this.estateCodeError,
      estateCodeLoading: estateCodeLoading ?? this.estateCodeLoading,
      pendingEstateCode: identical(pendingEstateCode, _sentinel)
          ? this.pendingEstateCode
          : pendingEstateCode as String?,
      pendingEstateName: identical(pendingEstateName, _sentinel)
          ? this.pendingEstateName
          : pendingEstateName as String?,
      pendingEstateAddress: identical(pendingEstateAddress, _sentinel)
          ? this.pendingEstateAddress
          : pendingEstateAddress as String?,
      pendingEstateImage: identical(pendingEstateImage, _sentinel)
          ? this.pendingEstateImage
          : pendingEstateImage as String?,
      pendingEstateManagedBy: identical(pendingEstateManagedBy, _sentinel)
          ? this.pendingEstateManagedBy
          : pendingEstateManagedBy as String?,
      pendingEstateResidentCount:
          identical(pendingEstateResidentCount, _sentinel)
          ? this.pendingEstateResidentCount
          : pendingEstateResidentCount as int?,
      loginPhone: loginPhone ?? this.loginPhone,
      loginPassword: loginPassword ?? this.loginPassword,
      loginError: loginError ?? this.loginError,
      rememberMe: rememberMe ?? this.rememberMe,
      forgotPhone: forgotPhone ?? this.forgotPhone,
      otpCode: otpCode ?? this.otpCode,
      devOtp: identical(devOtp, _sentinel) ? this.devOtp : devOtp as String?,
      resetToken: identical(resetToken, _sentinel)
          ? this.resetToken
          : resetToken as String?,
      newPass1: newPass1 ?? this.newPass1,
      newPass2: newPass2 ?? this.newPass2,
      resetMsg: resetMsg ?? this.resetMsg,
      setupFullName: setupFullName ?? this.setupFullName,
      setupHouse: setupHouse ?? this.setupHouse,
      setupEmail: setupEmail ?? this.setupEmail,
      setupEmergencyContactName:
          setupEmergencyContactName ?? this.setupEmergencyContactName,
      setupEmergencyContactPhone:
          setupEmergencyContactPhone ?? this.setupEmergencyContactPhone,
      setupVehiclePlates: setupVehiclePlates ?? this.setupVehiclePlates,
      vfName: vfName ?? this.vfName,
      vfPhone: vfPhone ?? this.vfPhone,
      vfPlate: vfPlate ?? this.vfPlate,
      vfError: vfError ?? this.vfError,
      visitorPasses: visitorPasses ?? this.visitorPasses,
      paymentStep: paymentStep ?? this.paymentStep,
      paymentReference: identical(paymentReference, _sentinel)
          ? this.paymentReference
          : paymentReference as String?,
      duesBalance: duesBalance ?? this.duesBalance,
      duesMonthsPaid: duesMonthsPaid ?? this.duesMonthsPaid,
      walletBalance: walletBalance ?? this.walletBalance,
      historyFilterMonth: identical(historyFilterMonth, _sentinel)
          ? this.historyFilterMonth
          : historyFilterMonth as int?,
      historyFilterYear: identical(historyFilterYear, _sentinel)
          ? this.historyFilterYear
          : historyFilterYear as int?,
      voiceStage: voiceStage ?? this.voiceStage,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      voiceResponse: voiceResponse ?? this.voiceResponse,
      voiceNavigationTarget: identical(voiceNavigationTarget, _sentinel)
          ? this.voiceNavigationTarget
          : voiceNavigationTarget as String?,
      pendingAuthorizationFor: identical(pendingAuthorizationFor, _sentinel)
          ? this.pendingAuthorizationFor
          : pendingAuthorizationFor as String?,
      selectedVoice: identical(selectedVoice, _sentinel)
          ? this.selectedVoice
          : selectedVoice as TtsVoiceOption?,
      availableVoices: availableVoices ?? this.availableVoices,
      duesHistory: duesHistory ?? this.duesHistory,
      guardCode: guardCode ?? this.guardCode,
      guardResult: identical(guardResult, _sentinel)
          ? this.guardResult
          : guardResult as GuardResult?,
      accessLog: accessLog ?? this.accessLog,
      allNotifsRead: allNotifsRead ?? this.allNotifsRead,
      notifications: notifications ?? this.notifications,
      complaintCategory: complaintCategory ?? this.complaintCategory,
      complaintDesc: complaintDesc ?? this.complaintDesc,
      complaintError: complaintError ?? this.complaintError,
      complaintRef: complaintRef ?? this.complaintRef,
      levies: levies ?? this.levies,
      announcements: announcements ?? this.announcements,
      meetings: meetings ?? this.meetings,
      projects: projects ?? this.projects,
      polls: polls ?? this.polls,
      rulesSections: rulesSections ?? this.rulesSections,
      myPledges: myPledges ?? this.myPledges,
      complaints: complaints ?? this.complaints,
      sessions: sessions ?? this.sessions,
      spotlight: identical(spotlight, _sentinel)
          ? this.spotlight
          : spotlight as Spotlight?,
      utilityLoading: utilityLoading ?? this.utilityLoading,
      utilityError: utilityError ?? this.utilityError,
      utilityMeters: utilityMeters ?? this.utilityMeters,
      utilityPurchases: utilityPurchases ?? this.utilityPurchases,
      lastUtilityPurchase: identical(lastUtilityPurchase, _sentinel)
          ? this.lastUtilityPurchase
          : lastUtilityPurchase as UtilityPurchase?,
      discos: discos ?? this.discos,
      airtimeNetwork: airtimeNetwork ?? this.airtimeNetwork,
      airtimePhone: airtimePhone ?? this.airtimePhone,
      airtimeAmount: airtimeAmount ?? this.airtimeAmount,
      elecDiscoCode: elecDiscoCode ?? this.elecDiscoCode,
      elecDiscoName: elecDiscoName ?? this.elecDiscoName,
      elecMeterNumber: elecMeterNumber ?? this.elecMeterNumber,
      elecMeterType: elecMeterType ?? this.elecMeterType,
      elecPhone: elecPhone ?? this.elecPhone,
      elecAmount: elecAmount ?? this.elecAmount,
      elecAmountPrefilled: elecAmountPrefilled ?? this.elecAmountPrefilled,
      elecVerifiedName: identical(elecVerifiedName, _sentinel)
          ? this.elecVerifiedName
          : elecVerifiedName as String?,
      elecVerifiedAddress: identical(elecVerifiedAddress, _sentinel)
          ? this.elecVerifiedAddress
          : elecVerifiedAddress as String?,
    );
  }
}

const _sentinel = Object();
