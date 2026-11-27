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
  String get welcomeHeadline => 'Uma lista de compras para a casa toda.';

  @override
  String get welcomeSubtitle => 'Adicione o que falta, veja o que os outros adicionaram e marque tudo no mercado.';

  @override
  String get welcomeSampleOranges => 'Laranjas';

  @override
  String get welcomeSampleBread => 'Pão';

  @override
  String get welcomeSampleCoffee => 'Café';

  @override
  String get welcomeSampleEggs => 'Ovos';

  @override
  String get welcomeSampleCheese => 'Queijo';

  @override
  String get welcomeContinueWithGoogle => 'Continuar com Google';

  @override
  String get welcomeContinueWithEmail => 'Continuar com e-mail';

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
  String get userMenu => 'Menu do usuário';

  @override
  String get userMenuChangeDisplayName => 'Alterar nome de exibição';

  @override
  String get userMenuServerStatus => 'Status do servidor';

  @override
  String get userMenuSignOut => 'Sair';

  @override
  String get loading => 'Carregando…';

  @override
  String get userLoadFailed => 'Não foi possível carregar seus dados.';

  @override
  String get userLoadRetry => 'Tentar de novo';

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
  String get errorListLimitGeneric => 'Você atingiu o limite de listas. Exclua uma para criar outra.';

  @override
  String get errorListNotFound => 'Esta lista não está mais disponível.';

  @override
  String get errorListDeleted => 'Esta lista foi excluída. Você pode restaurá-la em Excluídas recentemente.';

  @override
  String get errorListNotRestorable => 'Esta lista não está mais disponível e não pode ser restaurada.';

  @override
  String listToBuyInBasket(int toBuy, int inBasket) {
    return '$toBuy a comprar, $inBasket na cesta';
  }

  @override
  String get listInTheBasket => 'Na cesta';

  @override
  String get listAddAnItem => 'Adicionar um item';

  @override
  String get listCheckedByYou => 'Você';

  @override
  String get itemCheck => 'Marcar como comprado';

  @override
  String get itemUncheck => 'Desmarcar';

  @override
  String get addItemsSearch => 'Buscar itens';

  @override
  String get addItemsDone => 'Concluir';

  @override
  String addItemsAddAsNew(String name) {
    return 'Adicionar “$name” como novo item';
  }

  @override
  String get newItemTitle => 'Novo item';

  @override
  String get newItemName => 'Nome';

  @override
  String get newItemHowMuch => 'Quantidade';

  @override
  String get newItemQuantity => 'Quantidade';

  @override
  String get newItemLess => 'Menos';

  @override
  String get newItemMore => 'Mais';

  @override
  String get newItemNoteHint => 'Adicione uma observação, como “bem maduros”';

  @override
  String newItemAddTo(String list) {
    return 'Adicionar a $list';
  }

  @override
  String get unitUn => 'un';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'L';

  @override
  String get unitMl => 'ml';

  @override
  String get unitPack => 'pct';

  @override
  String itemAdded(String item, String list) {
    return '$item adicionado a $list';
  }

  @override
  String get itemUndo => 'Desfazer';

  @override
  String get errorItemNameRequired => 'Digite um nome.';

  @override
  String errorItemNameTooLong(int max) {
    return 'Use até $max caracteres.';
  }

  @override
  String get errorItemQuantityInvalid => 'Use um número maior que zero, como 2 ou 1,5.';

  @override
  String listOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sem conexão · $count alterações aguardando sincronização',
      one: 'Sem conexão · 1 alteração aguardando sincronização',
      zero: 'Sem conexão',
    );
    return '$_temp0';
  }

  @override
  String get listNothingToBuyYet => 'Nada para comprar ainda';

  @override
  String get listEmptyTitle => 'Comece sua lista';

  @override
  String get listEmptyBody => 'Adicione o que você precisa. Todos nesta lista veem na hora.';

  @override
  String get itemEditTitle => 'Editar item';

  @override
  String get itemSave => 'Salvar';

  @override
  String itemAddedBy(String name) {
    return 'Adicionado por $name';
  }

  @override
  String get itemAddedByYou => 'Adicionado por você';

  @override
  String itemCheckedBy(String name) {
    return 'Marcado por $name';
  }

  @override
  String get itemCheckedByYou => 'Marcado por você';

  @override
  String get itemRemove => 'Remover item';

  @override
  String itemRemoved(String item) {
    return '$item removido';
  }

  @override
  String itemRejectedRemoved(String name) {
    return 'Não foi possível salvar “$name”. Ele foi removido.';
  }

  @override
  String itemRejectedListGone(String name) {
    return 'Não foi possível salvar “$name”. A lista não está mais disponível.';
  }

  @override
  String itemRejected(String name) {
    return 'Não foi possível salvar “$name”.';
  }

  @override
  String get itemLimitTitle => 'Esta lista está cheia';

  @override
  String itemLimitBody(int max) {
    return 'Uma lista pode ter até $max itens. Limpe os itens marcados ou remova os que você não precisa mais para abrir espaço.';
  }
}
