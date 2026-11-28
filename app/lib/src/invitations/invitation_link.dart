import 'package:dio/dio.dart';

import '../api/generated/cesta_api.dart';
import '../api/network.dart';
import '../lists/lists_controller.dart';

/// Why an Invitation opened from its deep link can't be looked up, accepted
/// or declined.
enum InvitationProblem {
  /// The link's token matches no Invitation.
  notFound,
  accepted,
  declined,
  cancelled,
  expired,

  /// Its List was deleted.
  listDeleted,

  /// Its List already has the most Members a List can have.
  listFull,
  rateLimited,
  offline,
  failed,
}

/// The Invitation an Invitation deep link carries the token of: what the
/// accept screen shows, and accepting or declining it as the signed-in User.
class InvitationLink {
  InvitationLink({required this.token, required this._api, required this._lists});

  final String token;
  final ApiClient _api;
  final ListsController _lists;

  InvitationRef get _ref => InvitationRef(token: token);

  /// The Invitation whatever its status, or why it couldn't be loaded.
  Future<(Invitation?, InvitationProblem?)> lookup() => _attempt(() async {
    return switch (await _api.lookupInvitation(body: _ref)) {
      LookupInvitation200(:final value) => (value, null),
      LookupInvitation404() => (null, InvitationProblem.notFound),
      LookupInvitation429() => (null, InvitationProblem.rateLimited),
      LookupInvitation400() || LookupInvitation401() => (null, InvitationProblem.failed),
    };
  });

  /// Makes the User an Editor of the Invitation's List, which then shows on
  /// the Lists screen; or says why not.
  Future<(ListSummary?, InvitationProblem?)> accept() => _attempt(() async {
    switch (await _api.acceptInvitation(body: _ref)) {
      case AcceptInvitation200(:final value):
        await _lists.joined(value);
        return (value, null);
      case AcceptInvitation404():
        return (null, InvitationProblem.notFound);
      case AcceptInvitation409(:final value):
        return (null, _problem(value.code));
      case AcceptInvitation429():
        return (null, InvitationProblem.rateLimited);
      case AcceptInvitation400() || AcceptInvitation401():
        return (null, InvitationProblem.failed);
    }
  });

  /// Declines the Invitation, so its link stops working; null when it did.
  Future<InvitationProblem?> decline() async {
    final (_, problem) = await _attempt(() async {
      return switch (await _api.declineInvitation(body: _ref)) {
        DeclineInvitation200() => (null, null),
        DeclineInvitation404() => (null, InvitationProblem.notFound),
        DeclineInvitation409(:final value) => (null, _problem(value.code)),
        DeclineInvitation429() => (null, InvitationProblem.rateLimited),
        DeclineInvitation400() || DeclineInvitation401() => (null, InvitationProblem.failed),
      };
    });
    return problem;
  }

  /// Why an Invitation with [status] can no longer be answered; null while
  /// it is pending.
  static InvitationProblem? closed(InvitationStatus status) => switch (status) {
    InvitationStatus.pending => null,
    InvitationStatus.accepted => InvitationProblem.accepted,
    InvitationStatus.declined => InvitationProblem.declined,
    InvitationStatus.cancelled => InvitationProblem.cancelled,
    InvitationStatus.expired => InvitationProblem.expired,
  };

  static InvitationProblem _problem(ApiErrorCode code) => switch (code) {
    ApiErrorCode.invitationAccepted => InvitationProblem.accepted,
    ApiErrorCode.invitationDeclined => InvitationProblem.declined,
    ApiErrorCode.invitationCancelled => InvitationProblem.cancelled,
    ApiErrorCode.invitationExpired => InvitationProblem.expired,
    ApiErrorCode.invitationNotFound => InvitationProblem.notFound,
    ApiErrorCode.listDeleted || ApiErrorCode.listNotFound => InvitationProblem.listDeleted,
    ApiErrorCode.listFull => InvitationProblem.listFull,
    _ => InvitationProblem.failed,
  };

  static Future<(T?, InvitationProblem?)> _attempt<T>(Future<(T?, InvitationProblem?)> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      return (null, isOffline(e) ? InvitationProblem.offline : InvitationProblem.failed);
    }
  }
}
