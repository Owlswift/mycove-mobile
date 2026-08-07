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
import '../data/models/spotlight.dart';
import '../data/models/visitor_pass.dart';

enum AuthStage { bootstrapping, welcome, estateCode, login, forgot, otp, newPassword, forceReset, app }

enum Role { resident, guard }

enum PaymentStep { idle, processing, success }

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
    this.currentUser,
    this.estateName,
    this.estateCodeInput = '',
    this.estateCodeError = '',
    this.estateCodeLoading = false,
    this.loginPhone = '',
    this.loginPassword = '',
    this.loginError = '',
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
    this.spotlight,
  }) : visitorPasses = visitorPasses ?? [],
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
       complaints = complaints ?? [];

  final AuthStage authStage;
  final Role role;
  final bool isLoading;
  final CurrentUser? currentUser;

  final String? estateName;
  final String estateCodeInput;
  final String estateCodeError;
  final bool estateCodeLoading;

  final String loginPhone;
  final String loginPassword;
  final String loginError;

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
  final Spotlight? spotlight;

  DuesEntry? get lastPayment {
    for (final h in duesHistory) {
      if (h.type == DuesEntryType.payment) return h;
    }
    return null;
  }

  String get duesBalanceLabel => formatNaira(duesBalance);
  String get duesBalanceLabelPre => formatNaira(lastPayment?.amount ?? duesBalance);
  String get receiptAmountLabel => formatNaira(lastPayment?.amount ?? 0);
  String get receiptRef => 'PSK-${lastPayment?.id.toUpperCase() ?? 'N/A'}';
  int get activePassCount => visitorPasses.where((p) => p.isInside).length;

  AppState copyWith({
    AuthStage? authStage,
    Role? role,
    bool? isLoading,
    Object? currentUser = _sentinel,
    Object? estateName = _sentinel,
    String? estateCodeInput,
    String? estateCodeError,
    bool? estateCodeLoading,
    String? loginPhone,
    String? loginPassword,
    String? loginError,
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
    Object? spotlight = _sentinel,
  }) {
    return AppState(
      authStage: authStage ?? this.authStage,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      currentUser: identical(currentUser, _sentinel) ? this.currentUser : currentUser as CurrentUser?,
      estateName: identical(estateName, _sentinel) ? this.estateName : estateName as String?,
      estateCodeInput: estateCodeInput ?? this.estateCodeInput,
      estateCodeError: estateCodeError ?? this.estateCodeError,
      estateCodeLoading: estateCodeLoading ?? this.estateCodeLoading,
      loginPhone: loginPhone ?? this.loginPhone,
      loginPassword: loginPassword ?? this.loginPassword,
      loginError: loginError ?? this.loginError,
      forgotPhone: forgotPhone ?? this.forgotPhone,
      otpCode: otpCode ?? this.otpCode,
      devOtp: identical(devOtp, _sentinel) ? this.devOtp : devOtp as String?,
      resetToken: identical(resetToken, _sentinel) ? this.resetToken : resetToken as String?,
      newPass1: newPass1 ?? this.newPass1,
      newPass2: newPass2 ?? this.newPass2,
      resetMsg: resetMsg ?? this.resetMsg,
      setupFullName: setupFullName ?? this.setupFullName,
      setupHouse: setupHouse ?? this.setupHouse,
      setupEmail: setupEmail ?? this.setupEmail,
      setupEmergencyContactName: setupEmergencyContactName ?? this.setupEmergencyContactName,
      setupEmergencyContactPhone: setupEmergencyContactPhone ?? this.setupEmergencyContactPhone,
      setupVehiclePlates: setupVehiclePlates ?? this.setupVehiclePlates,
      vfName: vfName ?? this.vfName,
      vfPhone: vfPhone ?? this.vfPhone,
      vfPlate: vfPlate ?? this.vfPlate,
      vfError: vfError ?? this.vfError,
      visitorPasses: visitorPasses ?? this.visitorPasses,
      paymentStep: paymentStep ?? this.paymentStep,
      paymentReference: identical(paymentReference, _sentinel) ? this.paymentReference : paymentReference as String?,
      duesBalance: duesBalance ?? this.duesBalance,
      duesHistory: duesHistory ?? this.duesHistory,
      guardCode: guardCode ?? this.guardCode,
      guardResult: identical(guardResult, _sentinel) ? this.guardResult : guardResult as GuardResult?,
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
      spotlight: identical(spotlight, _sentinel) ? this.spotlight : spotlight as Spotlight?,
    );
  }
}

const _sentinel = Object();
