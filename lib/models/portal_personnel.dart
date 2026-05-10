/// `PortalPersonnelListDto` ile birebir (sadece görüntüleme için kullanılan
/// alanlar; CRUD ileri faz).
class PortalPersonnel {
  PortalPersonnel({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.email,
    required this.title,
    required this.customerRoleId,
    required this.isActive,
    required this.isLocked,
    this.customerRoleName,
    this.branchName,
    this.photoUrl,
  });

  final int id;
  final String userName;
  final String fullName;
  final String email;
  final String title;
  final int customerRoleId;
  final String? customerRoleName;
  final String? branchName;
  final bool isActive;
  final bool isLocked;
  final String? photoUrl;

  factory PortalPersonnel.fromJson(Map<String, dynamic> json) {
    return PortalPersonnel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userName: json['userName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      title: json['title'] as String? ?? '',
      customerRoleId: (json['customerRoleId'] as num?)?.toInt() ?? 0,
      customerRoleName: json['customerRoleName'] as String?,
      branchName: json['branchName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
