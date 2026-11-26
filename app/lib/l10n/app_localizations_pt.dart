// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Cesta';

  @override
  String get healthTitle => 'Status do servidor';

  @override
  String get healthChecking => 'Verificando o servidor…';

  @override
  String get healthServerUp => 'Servidor no ar';

  @override
  String get healthServerDegraded => 'Servidor instável';

  @override
  String get healthDatabaseUp => 'Banco de dados: conectado';

  @override
  String get healthDatabaseDown => 'Banco de dados: inacessível';

  @override
  String get healthOffline => 'Você está offline';

  @override
  String get healthOfflineNoData => 'Não foi possível acessar o servidor.';

  @override
  String get healthLastKnown => 'Último status conhecido';

  @override
  String get healthCheckFailed => 'Não foi possível verificar o status do servidor.';

  @override
  String get healthRetry => 'Verificar novamente';

  @override
  String get welcomeTagline => 'Listas de compras compartilhadas que funcionam no mercado, com ou sem sinal.';

  @override
  String get welcomeContinueWithGoogle => 'Continuar com Google';

  @override
  String get welcomeContinueWithEmail => 'Continuar com e-mail';

  @override
  String get welcomeHaveAccount => 'Já tem uma conta? Entrar';

  @override
  String get signInTitle => 'Entrar';

  @override
  String get signInButton => 'Entrar';

  @override
  String get signInForgotPassword => 'Esqueceu a senha?';

  @override
  String get signInNoAccount => 'Primeira vez? Crie uma conta';

  @override
  String get signUpTitle => 'Criar conta';

  @override
  String get signUpButton => 'Criar conta';

  @override
  String get signUpHaveAccount => 'Já tem uma conta? Entrar';

  @override
  String get fieldEmail => 'E-mail';

  @override
  String get fieldPassword => 'Senha';

  @override
  String get fieldPasswordShow => 'Mostrar senha';

  @override
  String get fieldPasswordHide => 'Ocultar senha';

  @override
  String get fieldPasswordHint => 'Pelo menos 8 caracteres';

  @override
  String get errorEmailRequired => 'Digite seu e-mail.';

  @override
  String get errorEmailInvalid => 'Digite um e-mail válido.';

  @override
  String get errorPasswordRequired => 'Digite sua senha.';

  @override
  String get errorPasswordTooShort => 'Use pelo menos 8 caracteres.';

  @override
  String get errorWrongCredentials => 'E-mail ou senha incorretos.';

  @override
  String get errorEmailInUse => 'Já existe uma conta com este e-mail. Entre com ela.';

  @override
  String get errorWeakPassword => 'Escolha uma senha mais forte.';

  @override
  String get errorOffline => 'Você está sem conexão. Conecte-se à internet e tente de novo.';

  @override
  String get errorTooManyAttempts => 'Muitas tentativas. Aguarde um pouco e tente de novo.';

  @override
  String get errorAccountDisabled => 'Esta conta foi desativada.';

  @override
  String get errorOtherSignInMethod => 'Este e-mail já é usado com outra forma de entrar. Entre por ela.';

  @override
  String get errorUnknown => 'Algo deu errado. Tente de novo.';

  @override
  String get resetTitle => 'Redefinir senha';

  @override
  String get resetExplanation => 'Digite o e-mail da sua conta e enviaremos um link para você escolher uma nova senha.';

  @override
  String get resetButton => 'Enviar link';

  @override
  String resetSent(String email) {
    return 'Se existir uma conta para $email, enviamos para ela um link para redefinir a senha.';
  }

  @override
  String get resetBackToSignIn => 'Voltar para entrar';

  @override
  String get displayNameOnboardingTitle => 'Como podemos te chamar?';

  @override
  String get displayNameExplanation => 'Os outros membros das suas listas veem este nome.';

  @override
  String get displayNameEditTitle => 'Nome de exibição';

  @override
  String get fieldDisplayName => 'Nome de exibição';

  @override
  String get displayNameContinue => 'Continuar';

  @override
  String get displayNameSave => 'Salvar';

  @override
  String get errorDisplayNameRequired => 'Digite um nome.';

  @override
  String get errorDisplayNameTooLong => 'Use até 50 caracteres.';

  @override
  String get errorDisplayNameInvalid => 'Esse nome não pode ser usado. Tente outro.';

  @override
  String get listsTitle => 'Suas listas';

  @override
  String get listsEmptyTitle => 'Nenhuma lista ainda';

  @override
  String get listsEmptyBody => 'As listas que você criar ou para as quais for convidado aparecerão aqui.';

  @override
  String get userMenu => 'Conta';

  @override
  String get userMenuChangeDisplayName => 'Alterar nome de exibição';

  @override
  String get userMenuServerStatus => 'Status do servidor';

  @override
  String get userMenuSignOut => 'Sair';

  @override
  String get loading => 'Carregando…';

  @override
  String get sheetClose => 'Fechar';

  @override
  String get listsNew => 'Nova lista';

  @override
  String get listsToBuy => 'a comprar';

  @override
  String get listsNothingToBuy => 'Nada a comprar';

  @override
  String get listsOnlyYou => 'Só você';

  @override
  String listsSharedWithPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pessoas', one: '1 pessoa');
    return 'Compartilhada com $_temp0';
  }

  @override
  String get listsSharedWithYou => 'Compartilhada com você';

  @override
  String get listsNewSheetTitle => 'Nova lista';

  @override
  String get fieldListName => 'Nome';

  @override
  String get listsCreate => 'Criar lista';

  @override
  String listsOptions(String name) {
    return 'Opções de $name';
  }

  @override
  String get listsRename => 'Renomear';

  @override
  String get listsRenameSheetTitle => 'Renomear lista';

  @override
  String get listsSave => 'Salvar';

  @override
  String get listsDelete => 'Excluir lista';

  @override
  String listsDeleted(String name) {
    return '“$name” excluída';
  }

  @override
  String get listsUndo => 'Desfazer';

  @override
  String get listsRestore => 'Restaurar';

  @override
  String listsRestored(String name) {
    return '“$name” restaurada';
  }

  @override
  String get listsRecentlyDeleted => 'Excluídas recentemente';

  @override
  String listsRecentlyDeletedExplanation(int days) {
    return 'Listas excluídas podem ser restauradas por $days dias. Depois disso, somem de vez.';
  }

  @override
  String listsRecentlyDeletedEmpty(int days) {
    return 'Nada excluído nos últimos $days dias.';
  }

  @override
  String listsDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Faltam $days dias',
      one: 'Falta 1 dia',
      zero: 'Some hoje',
    );
    return '$_temp0';
  }

  @override
  String get errorListNameRequired => 'Digite um nome.';

  @override
  String errorListNameTooLong(int max) {
    return 'Use até $max caracteres.';
  }

  @override
  String get errorListNameInvalid => 'Esse nome não pode ser usado. Tente outro.';

  @override
  String errorListLimit(int limit) {
    return 'Você atingiu o limite de $limit listas. Exclua uma para criar outra.';
  }

  @override
  String get errorListNotFound => 'Esta lista não está mais disponível.';

  @override
  String get errorListDeleted => 'Esta lista foi excluída. Você pode restaurá-la em Excluídas recentemente.';

  @override
  String get errorListNotRestorable => 'Esta lista não está mais disponível e não pode ser restaurada.';
}
