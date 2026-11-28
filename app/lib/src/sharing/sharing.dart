import 'package:dio/dio.dart';

import '../api/generated/cesta_api.dart';
import '../api/network.dart';

/// Why an Invitation couldn't be sent, listed, cancelled, accepted or
/// declined. Operations return null when it went through.
sealed class InvitationFailure {
  const InvitationFailure();

  /// The server rejected the address.
  static const invalidEmail = InvitationInvalidEmail();

  /// The List is gone, deleted, or the User is no longer its Owner or a Member.
  static const listGone = InvitationListGone();

  static const rateLimited = InvitationRateLimited();
  static const offline = InvitationOffline();
  static const failed = InvitationFailed();
}

final class InvitationInvalidEmail extends InvitationFailure {
  const InvitationInvalidEmail();
}

/// The User already sent the most Invitations allowed in 24 hours.
final class InvitationLimitReached extends InvitationFailure {
  const InvitationLimitReached(this.limit);

  /// The maximum reported by the server, if provided.
  final int? limit;
}

final class InvitationListGone extends InvitationFailure {
  const InvitationListGone();
}

/// The Invitation was cancelled, declined, accepted, expired or is unknown,
/// or its List is full: [reason] is the server's code.
final class InvitationNoLongerValid extends InvitationFailure {
  const InvitationNoLongerValid(this.reason);

  final ApiErrorCode reason;
}

final class InvitationRateLimited extends InvitationFailure {
  const InvitationRateLimited();
}

final class InvitationOffline extends InvitationFailure {
  const InvitationOffline();
}

final class InvitationFailed extends InvitationFailure {
  const InvitationFailed();
}

/// The language an Invitation's email is written in: the Owner's app language.
InvitationCreateLanguage invitationLanguage(String languageCode) =>
    languageCode == 'pt' ? InvitationCreateLanguage.ptBr : InvitationCreateLanguage.en;

/// Invitations by email: the Owner invites to, lists and cancels on a List;
/// the User sees, accepts and declines the ones addressed to them. These need
/// the network (ADR-0001); nothing about them is kept on the device.
class Sharing {
  Sharing({required this._api});

  final ApiClient _api;

  /// The pending Invitations to List [listId], newest first. Owner only.
  Future<(List<Invitation>?, InvitationFailure?)> pendingFor(String listId) => _load(() async {
    return switch (await _api.listListInvitations(listId: listId)) {
      ListListInvitations200(:final value) => (value.invitations, null),
      ListListInvitations404() ||
      ListListInvitations409() ||
      ListListInvitations403() => (null, InvitationFailure.listGone),
      ListListInvitations429() => (null, InvitationFailure.rateLimited),
      ListListInvitations400() || ListListInvitations401() => (null, InvitationFailure.failed),
    };
  });

  /// Invites [email] to List [listId] as an Editor; the email is written in [language].
  Future<(Invitation?, InvitationFailure?)> invite(
    String listId,
    String email, {
    required InvitationCreateLanguage language,
  }) => _load(() async {
    final body = InvitationCreate(email: email.trim(), language: language);
    return switch (await _api.createInvitation(listId: listId, body: body)) {
      CreateInvitation201(:final value) => (value, null),
      CreateInvitation400() => (null, InvitationFailure.invalidEmail),
      CreateInvitation409(value: ApiError(code: ApiErrorCode.limitExceeded, :final limit)) => (
        null,
        InvitationLimitReached(limit),
      ),
      CreateInvitation404() || CreateInvitation403() || CreateInvitation409() => (null, InvitationFailure.listGone),
      CreateInvitation429() => (null, InvitationFailure.rateLimited),
      CreateInvitation401() => (null, InvitationFailure.failed),
    };
  });

  /// Cancels [invitation], so its link stops working.
  Future<InvitationFailure?> cancel(Invitation invitation) async {
    final (_, failure) = await _load(() async {
      final result = await _api.cancelInvitation(listId: invitation.listId, invitationId: invitation.id);
      return switch (result) {
        CancelInvitation200() => (null, null),
        CancelInvitation404(value: ApiError(:final code)) when code == ApiErrorCode.invitationNotFound => (
          null,
          InvitationNoLongerValid(code),
        ),
        CancelInvitation409(value: ApiError(:final code))
            when code == ApiErrorCode.invitationAccepted || code == ApiErrorCode.invitationDeclined =>
          (null, InvitationNoLongerValid(code)),
        CancelInvitation404() || CancelInvitation403() || CancelInvitation409() => (null, InvitationFailure.listGone),
        CancelInvitation429() => (null, InvitationFailure.rateLimited),
        CancelInvitation400() || CancelInvitation401() => (null, InvitationFailure.failed),
      };
    });
    return failure;
  }

  /// The pending Invitations addressed to the signed-in User's email, newest first.
  Future<(List<Invitation>?, InvitationFailure?)> mine() => _load(() async {
    return switch (await _api.listMyInvitations()) {
      ListMyInvitations200(:final value) => (value.invitations, null),
      ListMyInvitations429() => (null, InvitationFailure.rateLimited),
      ListMyInvitations401() => (null, InvitationFailure.failed),
    };
  });

  /// Accepts [invitation], making the User an Editor of its List, which it returns.
  Future<(ListSummary?, InvitationFailure?)> accept(Invitation invitation) => _load(() async {
    return switch (await _api.acceptInvitation(body: InvitationRef(id: invitation.id))) {
      AcceptInvitation200(:final value) => (value, null),
      AcceptInvitation404(:final value) || AcceptInvitation409(:final value) => (null, _noLongerValid(value)),
      AcceptInvitation429() => (null, InvitationFailure.rateLimited),
      AcceptInvitation400() || AcceptInvitation401() => (null, InvitationFailure.failed),
    };
  });

  /// Declines [invitation], so its link stops working.
  Future<InvitationFailure?> decline(Invitation invitation) async {
    final (_, failure) = await _load(() async {
      return switch (await _api.declineInvitation(body: InvitationRef(id: invitation.id))) {
        DeclineInvitation200() => (null, null),
        DeclineInvitation404(:final value) || DeclineInvitation409(:final value) => (null, _noLongerValid(value)),
        DeclineInvitation429() => (null, InvitationFailure.rateLimited),
        DeclineInvitation400() || DeclineInvitation401() => (null, InvitationFailure.failed),
      };
    });
    return failure;
  }

  static InvitationFailure _noLongerValid(ApiError error) => switch (error.code) {
    ApiErrorCode.listDeleted || ApiErrorCode.listNotFound => InvitationFailure.listGone,
    final code => InvitationNoLongerValid(code),
  };

  Future<(T?, InvitationFailure?)> _load<T>(Future<(T?, InvitationFailure?)> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      return (null, isOffline(e) ? InvitationFailure.offline : InvitationFailure.failed);
    }
  }
}
