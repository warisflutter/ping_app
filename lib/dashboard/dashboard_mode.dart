
enum DashboardMode {
  teamLead,
  member,
}


extension MemberListModelExt on DashboardMode {
  bool get isMember => this == DashboardMode.member;

  bool get isTeamLead => this == DashboardMode.teamLead;
}