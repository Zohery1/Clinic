import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExtraBranchDraft {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
  }
}

class RegisterStateData {
  final int currentStep;
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final String clinicPath;
  final String selectedRole;
  final String clinicName;
  final String mainBranchName;
  final List<ExtraBranchDraft> extraBranches;
  final String inviteCode;
  final bool isInviteCodeLocked;

  const RegisterStateData({
    this.currentStep = 0,
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.clinicPath = 'create',
    this.selectedRole = 'doctor',
    this.clinicName = '',
    this.mainBranchName = 'الفرع الرئيسي',
    this.extraBranches = const [],
    this.inviteCode = '',
    this.isInviteCodeLocked = false,
  });

  RegisterStateData copyWith({
    int? currentStep,
    String? fullName,
    String? phone,
    String? email,
    String? password,
    String? clinicPath,
    String? selectedRole,
    String? clinicName,
    String? mainBranchName,
    List<ExtraBranchDraft>? extraBranches,
    String? inviteCode,
    bool? isInviteCodeLocked,
  }) {
    return RegisterStateData(
      currentStep: currentStep ?? this.currentStep,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      clinicPath: clinicPath ?? this.clinicPath,
      selectedRole: selectedRole ?? this.selectedRole,
      clinicName: clinicName ?? this.clinicName,
      mainBranchName: mainBranchName ?? this.mainBranchName,
      extraBranches: extraBranches ?? this.extraBranches,
      inviteCode: inviteCode ?? this.inviteCode,
      isInviteCodeLocked: isInviteCodeLocked ?? this.isInviteCodeLocked,
    );
  }
}

class RegisterController extends StateNotifier<RegisterStateData> {
  RegisterController() : super(const RegisterStateData());

  static const int maxStep = 3;

  void setCurrentStep(int step) {
    if (step < 0) {
      state = state.copyWith(currentStep: 0);
      return;
    }
    if (step > maxStep) {
      state = state.copyWith(currentStep: maxStep);
      return;
    }
    state = state.copyWith(currentStep: step);
  }

  void next() {
    if (state.currentStep < maxStep) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void back() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setFullName(String v) => state = state.copyWith(fullName: v);
  void setPhone(String v) => state = state.copyWith(phone: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setPassword(String v) => state = state.copyWith(password: v);
  void setClinicName(String v) => state = state.copyWith(clinicName: v);
  void setMainBranchName(String v) => state = state.copyWith(mainBranchName: v);
  void setInviteCode(String v) => state = state.copyWith(inviteCode: v);

  void setClinicPath(String path) {
    final nextRole = path == 'create' ? 'doctor' : state.selectedRole;
    state = state.copyWith(clinicPath: path, selectedRole: nextRole);
  }

  void setSelectedRole(String role) {
    state = state.copyWith(selectedRole: role);
  }

  void lockInviteCode(String code) {
    state = state.copyWith(
      inviteCode: code,
      isInviteCodeLocked: true,
      clinicPath: 'join',
      selectedRole: 'secretary',
    );
  }

  void addExtraBranch() {
    final next = List<ExtraBranchDraft>.from(state.extraBranches)
      ..add(ExtraBranchDraft());
    state = state.copyWith(extraBranches: next);
  }

  void removeExtraBranch(int index) {
    if (index < 0 || index >= state.extraBranches.length) return;
    final next = List<ExtraBranchDraft>.from(state.extraBranches);
    next[index].dispose();
    next.removeAt(index);
    state = state.copyWith(extraBranches: next);
  }

  void reset() {
    for (final b in state.extraBranches) {
      b.dispose();
    }
    state = const RegisterStateData();
  }

  @override
  void dispose() {
    for (final b in state.extraBranches) {
      b.dispose();
    }
    super.dispose();
  }
}

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, RegisterStateData>(
  (ref) => RegisterController(),
);