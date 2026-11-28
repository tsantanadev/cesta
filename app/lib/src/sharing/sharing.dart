import 'package:dio/dio.dart';

import '../api/generated/cesta_api.dart';
import '../api/network.dart';

/// What an operation on Invitations that returns something came to: either
/// [InvitationDone] with its [InvitationDone.value], or an [InvitationFailure].
sealed class InvitationResult<T> {
  const InvitationResult();
}

/// The operation went through.
final class InvitationDone<T> extends InvitationResult<T> {
  const InvitationDone(this.value);

  final T value;
}

/// Why an Invitation couldn't be sent, listed, cancelled, accepted or
/// declined. Operations that return nothing return null when it went through.
sealed class InvitationFailure extends InvitationResult<Never> {
  const InvitationFailure();

  /// The server rejected the address.
  static const invalidEmail = InvitationInvalidEmail();

  /// The address belongs to a Member of the List, the Owner included.
  static const alreadyMember = InvitationAlreadyMember();

  /// The email provider couldn't send the Invitation's email; nothing was made.
  static const notSent = InvitationNotSent();

  /// The List is gone, deleted, or the User is no longer its Owner or a Member.
  static const listGone = InvitationListGone();

  static const rateLimited = InvitationRateLimited();
  static const offline = InvitationOffline();
  static const failed = InvitationFailed();
}

final class InvitationInvalidEmail extends InvitationFailure {
  const InvitationInvalidEmail();
}

final class InvitationAlreadyMember extends InvitationFailure {
  const InvitationAlreadyMember();
}

final class InvitationNotSent extends InvitationFailure {
  const InvitationNotSent();
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

/// The Invitation can't be answered: it is unknown, was cancelled, declined,
/// accepted or expired, or its List is full. [reason] is the server's code.
final class InvitationUnanswerable extends InvitationFailure {
  const InvitationUnanswerable(this.reason);

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

/// How many days an Invitation can be accepted after it is sent (the
/// backend's sharing.ExpiresAfter).
const invitationLifetimeDays = 14;

/// The one form email addresses are compared in: trimmed and lowercased, as
/// the backend stores an Invitation's address.
String canonicalEmail(String address) => address.trim().toLowerCase();

/// The language an Invitation's email is written in: the Owner's app language.
InvitationCreateLanguage invitationLanguage(String languageCode) =>
    languageCode == 'pt' ? InvitationCreateLanguage.ptBr : InvitationCreateLanguage.en;

/// Invitations by email: the Owner invites to, lists and cancels on a List;
/// the User sees, accepts and declines the ones addressed to them. These need
/// the network (ADR-0001); nothing about them is kept on the device.
class Sharing {
  Sharing({required this._api});

  final ApiClient _api;

  /// The open Invitations to List [listId] (pending, or expired without an
  /// answer), newest first. Owner only.
  Future<InvitationResult<List<Invitation>>> openFor(String listId) => _load(() async {
    return switch (await _api.listListInvitations(listId: listId)) {
      ListListInvitations200(:final value) => InvitationDone(value.invitations),
      ListListInvitations404() || ListListInvitations409() || ListListInvitations403() => InvitationFailure.listGone,
      ListListInvitations429() => InvitationFailure.rateLimited,
      ListListInvitations400() || ListListInvitations401() => InvitationFailure.failed,
    };
  });

  /// Invites [email] to List [listId] as an Editor; the email is written in [language].
  Future<InvitationResult<Invitation>> invite(
    String listId,
    String email, {
    required InvitationCreateLanguage language,
  }) => _load(() async {
    final body = InvitationCreate(email: email, language: language);
    return switch (await _api.createInvitation(listId: listId, body: body)) {
      CreateInvitation201(:final value) => InvitationDone(value),
      CreateInvitation400() => InvitationFailure.invalidEmail,
      CreateInvitation409(value: ApiError(code: ApiErrorCode.limitExceeded, :final limit)) => InvitationLimitReached(
        limit,
      ),
      CreateInvitation409(value: ApiError(code: ApiErrorCode.alreadyMember)) => InvitationFailure.alreadyMember,
      CreateInvitation404() || CreateInvitation403() || CreateInvitation409() => InvitationFailure.listGone,
      CreateInvitation502() => InvitationFailure.notSent,
      CreateInvitation429() => InvitationFailure.rateLimited,
      CreateInvitation401() => InvitationFailure.failed,
    };
  });

  /// Cancels [invitation], so its link stops working.
  Future<InvitationFailure?> cancel(Invitation invitation) => _attempt(() async {
    final result = await _api.cancelInvitation(listId: invitation.listId, invitationId: invitation.id);
    return switch (result) {
      CancelInvitation200() => null,
      CancelInvitation404(value: ApiError(:final code)) when code == ApiErrorCode.invitationNotFound =>
        InvitationUnanswerable(code),
      CancelInvitation409(value: ApiError(:final code))
          when code == ApiErrorCode.invitationAccepted || code == ApiErrorCode.invitationDeclined =>
        InvitationUnanswerable(code),
      CancelInvitation404() || CancelInvitation403() || CancelInvitation409() => InvitationFailure.listGone,
      CancelInvitation429() => InvitationFailure.rateLimited,
      CancelInvitation400() || CancelInvitation401() => InvitationFailure.failed,
    };
  });

  /// The pending Invitations addressed to the signed-in User's email, newest first.
  Future<InvitationResult<List<Invitation>>> mine() => _load(() async {
    return switch (await _api.listMyInvitations()) {
      ListMyInvitations200(:final value) => InvitationDone(value.invitations),
      ListMyInvitations429() => InvitationFailure.rateLimited,
      ListMyInvitations401() => InvitationFailure.failed,
    };
  });

  /// The Invitation whose deep link carries [token], whatever its status.
  Future<InvitationResult<Invitation>> lookup(String token) => _load(() async {
    return switch (await _api.lookupInvitation(body: InvitationRef(token: token))) {
      LookupInvitation200(:final value) => InvitationDone(value),
      LookupInvitation404(:final value) => InvitationUnanswerable(value.code),
      LookupInvitation429() => InvitationFailure.rateLimited,
      LookupInvitation400() || LookupInvitation401() => InvitationFailure.failed,
    };
  });

  /// Why [invitation] can't be accepted or declined any more; null while it is pending.
  static InvitationFailure? closed(Invitation invitation) => switch (invitation.status) {
    InvitationStatus.pending => null,
    InvitationStatus.accepted => const InvitationUnanswerable(ApiErrorCode.invitationAccepted),
    InvitationStatus.declined => const InvitationUnanswerable(ApiErrorCode.invitationDeclined),
    InvitationStatus.cancelled => const InvitationUnanswerable(ApiErrorCode.invitationCancelled),
    InvitationStatus.expired => const InvitationUnanswerable(ApiErrorCode.invitationExpired),
  };

  /// Accepts [invitation], making the User an Editor of its List, which it returns.
  Future<InvitationResult<ListSummary>> accept(Invitation invitation) => _accept(InvitationRef(id: invitation.id));

  /// Accepts the Invitation whose deep link carries [token], whoever it was
  /// addressed to, making the User an Editor of its List, which it returns.
  Future<InvitationResult<ListSummary>> acceptLink(String token) => _accept(InvitationRef(token: token));

  Future<InvitationResult<ListSummary>> _accept(InvitationRef ref) => _load(() async {
    return switch (await _api.acceptInvitation(body: ref)) {
      AcceptInvitation200(:final value) => InvitationDone(value),
      AcceptInvitation404(:final value) || AcceptInvitation409(:final value) => _unanswerable(value),
      AcceptInvitation429() => InvitationFailure.rateLimited,
      AcceptInvitation400() || AcceptInvitation401() => InvitationFailure.failed,
    };
  });

  /// Declines [invitation], so its link stops working.
  Future<InvitationFailure?> decline(Invitation invitation) => _decline(InvitationRef(id: invitation.id));

  /// Declines the Invitation whose deep link carries [token], so it stops working.
  Future<InvitationFailure?> declineLink(String token) => _decline(InvitationRef(token: token));

  Future<InvitationFailure?> _decline(InvitationRef ref) => _attempt(() async {
    return switch (await _api.declineInvitation(body: ref)) {
      DeclineInvitation200() => null,
      DeclineInvitation404(:final value) || DeclineInvitation409(:final value) => _unanswerable(value),
      DeclineInvitation429() => InvitationFailure.rateLimited,
      DeclineInvitation400() || DeclineInvitation401() => InvitationFailure.failed,
    };
  });

  static InvitationFailure _unanswerable(ApiError error) => switch (error.code) {
    ApiErrorCode.listDeleted || ApiErrorCode.listNotFound => InvitationFailure.listGone,
    final code => InvitationUnanswerable(code),
  };

  Future<InvitationResult<T>> _load<T>(Future<InvitationResult<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      return _networkFailure(e);
    }
  }

  Future<InvitationFailure?> _attempt(Future<InvitationFailure?> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      return _networkFailure(e);
    }
  }

  static InvitationFailure _networkFailure(DioException e) =>
      isOffline(e) ? InvitationFailure.offline : InvitationFailure.failed;
}
