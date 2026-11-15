import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageStore.instance.load();
  await ThemeStore.instance.load();

  var backendReady = false;
  String? initError;
  if (_supabaseUrl.startsWith('https://') &&
      _supabasePublishableKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _supabasePublishableKey,
      );
      backendReady = true;
    } catch (error) {
      initError = error.toString();
    }
  }

  runApp(EntrelinhasApp(backendReady: backendReady, initError: initError));
}

class EntrelinhasApp extends StatefulWidget {
  const EntrelinhasApp({super.key, required this.backendReady, this.initError});

  final bool backendReady;
  final String? initError;

  @override
  State<EntrelinhasApp> createState() => _EntrelinhasAppState();
}

class _EntrelinhasAppState extends State<EntrelinhasApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    if (widget.backendReady) {
      _signedIn = Supabase.instance.client.auth.currentSession != null;
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (state) {
          if (mounted) setState(() => _signedIn = state.session != null);
        },
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageStore.instance.language,
      builder: (context, language, _) {
        return ValueListenableBuilder<AppPalette>(
          valueListenable: ThemeStore.instance.palette,
          builder: (context, palette, _) {
            return MaterialApp(
              title: 'Aporia',
              debugShowCheckedModeBanner: false,
              theme: _buildTheme(palette),
              home: !widget.backendReady
                  ? SetupScreen(error: widget.initError)
                  : _signedIn
                      ? MainShell()
                      : AuthScreen(),
            );
          },
        );
      },
    );
  }
}

ThemeData _buildTheme(AppPalette palette) {
  final colorScheme = ColorScheme.fromSeed(seedColor: palette.primary).copyWith(
    primary: palette.primary,
    secondary: palette.accent,
    surface: palette.surface,
    onSurface: palette.text,
    onPrimary: Colors.white,
    error: const Color(0xFF9D3C36),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.background,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: TextStyle(color: palette.muted),
      labelStyle: TextStyle(color: palette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: palette.primary),
    ),
    dividerColor: palette.border,
  );
}


enum AppLanguage { portuguese, english }

class LanguageStore {
  LanguageStore._();
  static final LanguageStore instance = LanguageStore._();
  final ValueNotifier<AppLanguage> language =
      ValueNotifier(AppLanguage.portuguese);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    language.value = preferences.getString('entrelinhas.language') == 'english'
        ? AppLanguage.english
        : AppLanguage.portuguese;
  }

  Future<void> setLanguage(AppLanguage value) async {
    language.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'entrelinhas.language',
      value == AppLanguage.english ? 'english' : 'portuguese',
    );
  }
}

const Map<String, String> _portugueseTranslations = {
  'Invalid login credentials': 'Email ou palavra-passe incorretos.',
  'Email not confirmed': 'O email ainda não foi confirmado.',
  'User already registered': 'Este email já está registado.',
  'Password should be at least 6 characters': 'A palavra-passe deve ter pelo menos 6 caracteres.',
  'The community isn’t connected yet': 'Falta ligar a comunidade',
  'This app does not include sample reflections or demo accounts. To enable sign-up, posts, and voting across devices, configure Supabase and run the app with the two variables below.':
      'A app não inclui reflexões fictícias nem contas de demonstração. Para ativar o registo, as publicações e os votos entre dispositivos, configura o Supabase e inicia a app com as duas variáveis abaixo.',
  'Run command:': 'Comando de arranque:',
  'Use only the client publishable key. Never include the secret/service_role key in the app.':
      'Usa apenas a chave publicável do cliente. Nunca incluas a chave secret/service_role na aplicação.',
  'Initialization error': 'Erro de inicialização',
  'Account created. Confirm your email address, then sign in.': 'Conta criada. Confirma o teu email e inicia sessão.',
  'Could not complete the request. Check your connection and try again.': 'Não foi possível concluir o pedido. Verifica a ligação e tenta novamente.',
  'Create account': 'Criar conta',
  'Back to ideas': 'Volta às ideias',
  'Create a profile to write and discover reflections.': 'Cria um perfil para escrever e descobrir reflexões.',
  'Sign in to read, write, and react to reflections.': 'Entra para ler, escrever e reagir às reflexões.',
  'Display name': 'Nome público',
  'Enter a name with at least 2 characters.': 'Indica um nome com pelo menos 2 caracteres.',
  'Maximum 36 characters.': 'Máximo de 36 caracteres.',
  'Email': 'Email',
  'Enter a valid email address.': 'Indica um email válido.',
  'Password': 'Palavra-passe',
  'Hide password': 'Ocultar palavra-passe',
  'Show password': 'Mostrar palavra-passe',
  'Use at least 8 characters.': 'Usa pelo menos 8 caracteres.',
  'Sign in': 'Entrar',
  'Already have an account? Sign in': 'Já tenho conta — entrar',
  'Don’t have an account? Sign up': 'Ainda não tenho conta — registar',
  'Forgot password?': 'Esqueci-me da palavra-passe',
  'Enter your email first to receive a password reset link.': 'Preenche primeiro o email para receberes a ligação de recuperação.',
  'If this email is registered, you’ll receive password reset instructions.': 'Se o email estiver registado, receberás instruções para recuperar a palavra-passe.',
  'Could not send the password reset email.': 'Não foi possível enviar o email de recuperação.',
  'Explore': 'Explorar',
  'Write': 'Escrever',
  'Saved': 'Guardadas',
  'Profile': 'Perfil',
  'DAY': 'DIA',
  'WEEK': 'SEMANA',
  'MONTH': 'MÊS',
  'User': 'Utilizador',
  'Sign in to publish.': 'Inicia sessão para publicar.',
  'MOST POPULAR': 'MAIS POPULARES',
  'No reflections for this period yet.': 'Ainda não há reflexões neste período.',
  'Publish the first reflection and start the conversation.': 'Publica a primeira reflexão e dá início à conversa.',
  'TODAY’S FEED': 'FEED DO DIA',
  'Nothing here yet today.': 'Hoje ainda está em branco.',
  'New reflections will appear here.': 'As novas reflexões vão aparecer aqui.',
  'Close': 'Fechar',
  'Like': 'Gosto',
  'I’ll carry this with me': 'Levo comigo',
  'Remove from saved': 'Remover das guardadas',
  'Save reflection': 'Guardar reflexão',
  'Report': 'Denunciar',
  'Report reflection': 'Denunciar reflexão',
  'Spam or advertising': 'Spam ou publicidade',
  'Harassment or abusive content': 'Assédio ou conteúdo abusivo',
  'Other reason': 'Outro motivo',
  'Report submitted for review.': 'Denúncia enviada para revisão.',
  'Your reflection must be at least 10 characters long.': 'A reflexão tem de ter pelo menos 10 caracteres.',
  'You have already published today. Come back tomorrow.': 'Já publicaste hoje. Volta amanhã.',
  'Checking today’s posting limit…': 'A verificar o limite de publicações de hoje…',
  'One reflection per day. Make it count.': 'Uma reflexão por dia. Faz com que conte.',
  'Could not verify today’s posting limit. Try again.': 'Não foi possível verificar se já publicaste hoje. Tenta novamente.',
  'You cannot react to your own reflection.': 'Não podes reagir à tua própria reflexão.',
  'Maximum: 1,200 characters': 'Máximo: 1.200 caracteres.',
  'Reflection published.': 'Reflexão publicada.',
  'WRITE': 'ESCREVER',
  'An idea in your own words.': 'Uma ideia tua, nas tuas palavras.',
  'Don’t write just to collect votes. Share something you believe, a question, or a reflection you want others to read.': 'Não escrevas apenas para acumular votos. Partilha algo em que acreditas, uma pergunta ou uma reflexão que queiras que os outros leiam.',
  'Write your reflection…': 'Escreve a tua reflexão…',
  'Minimum: 10 characters': 'Mínimo: 10 caracteres',
  'Publishing…': 'A publicar…',
  'Publish reflection': 'Publicar reflexão',
  'SAVED': 'GUARDADAS',
  'You haven’t saved any reflections yet.': 'Ainda não guardaste nenhuma reflexão.',
  'Open a reflection and choose Save to find it here.': 'Abre uma reflexão e escolhe Guardar para a encontrares aqui.',
  'PROFILE': 'PERFIL',
  'Your account': 'A tua conta',
  'LANGUAGE': 'IDIOMA',
  'APP COLOURS': 'CORES DA APLICAÇÃO',
  'Sign out': 'Terminar sessão',
  'Could not load the data.': 'Não foi possível carregar os dados.',
  'Try again': 'Tentar novamente',
  'The database rejected this action due to insufficient permissions. Check the Supabase RLS policies.': 'A base de dados recusou a operação por falta de permissões. Confirma as políticas RLS do Supabase.',
  'Could not connect to the server. Check your internet connection and try again.': 'Não foi possível ligar ao servidor. Verifica a ligação à Internet e tenta novamente.',
  'Forest': 'Bosque',
  'Ocean': 'Oceano',
  'Plum': 'Ameixa',
  'Terracotta': 'Terracota',
  'Sage': 'Sálvia',
};

String uiText(String english) {
  if (LanguageStore.instance.language.value == AppLanguage.english) {
    return english;
  }
  return _portugueseTranslations[english] ?? english;
}

String _localizedPaletteName(String id, String englishName) {
  switch (id) {
    case 'bosque': return uiText('Forest');
    case 'oceano': return uiText('Ocean');
    case 'ameixa': return uiText('Plum');
    case 'terracota': return uiText('Terracotta');
    case 'salvia': return uiText('Sage');
    default: return englishName;
  }
}

class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.bubble,
    required this.text,
    required this.muted,
    required this.border,
  });

  final String id;
  final String name;
  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color bubble;
  final Color text;
  final Color muted;
  final Color border;

  static const List<AppPalette> all = [
    AppPalette(
      id: 'bosque', name: 'Forest', primary: Color(0xFF354B3B),
      accent: Color(0xFF9B815E), background: Color(0xFFF6F4EE),
      surface: Color(0xFFFFFEFA), bubble: Color(0xFFEFEEE5),
      text: Color(0xFF252D27), muted: Color(0xFF777D74),
      border: Color(0xFFE0DED3),
    ),
    AppPalette(
      id: 'oceano', name: 'Ocean', primary: Color(0xFF215770),
      accent: Color(0xFF73A7B9), background: Color(0xFFF1F6F8),
      surface: Color(0xFFFFFFFF), bubble: Color(0xFFE5F0F4),
      text: Color(0xFF202D34), muted: Color(0xFF6B7E86),
      border: Color(0xFFD6E2E7),
    ),
    AppPalette(
      id: 'ameixa', name: 'Plum', primary: Color(0xFF6B476E),
      accent: Color(0xFFB18AAE), background: Color(0xFFF7F2F7),
      surface: Color(0xFFFFFCFF), bubble: Color(0xFFF0E6F0),
      text: Color(0xFF302533), muted: Color(0xFF827485),
      border: Color(0xFFE5D8E5),
    ),
    AppPalette(
      id: 'terracota', name: 'Terracotta', primary: Color(0xFF964831),
      accent: Color(0xFFD39A75), background: Color(0xFFFAF3EE),
      surface: Color(0xFFFFFCF9), bubble: Color(0xFFF4E5DA),
      text: Color(0xFF352821), muted: Color(0xFF8A7569),
      border: Color(0xFFEAD8CB),
    ),
    AppPalette(
      id: 'salvia', name: 'Sage', primary: Color(0xFF2E615C),
      accent: Color(0xFF8CB1A4), background: Color(0xFFF1F6F2),
      surface: Color(0xFFFFFFFF), bubble: Color(0xFFE3EEE8),
      text: Color(0xFF25332E), muted: Color(0xFF71817A),
      border: Color(0xFFD5E2DA),
    ),
  ];

  static AppPalette byId(String? id) => all.firstWhere(
        (palette) => palette.id == id,
        orElse: () => all.first,
      );
}

class ThemeStore {
  ThemeStore._();
  static final ThemeStore instance = ThemeStore._();
  final ValueNotifier<AppPalette> palette = ValueNotifier(AppPalette.all.first);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    palette.value = AppPalette.byId(preferences.getString('entrelinhas.palette'));
  }

  Future<void> setPalette(AppPalette value) async {
    palette.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('entrelinhas.palette', value.id);
  }
}


class _LanguageQuickSwitch extends StatelessWidget {
  const _LanguageQuickSwitch();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageStore.instance.language,
      builder: (context, current, _) => TextButton.icon(
        onPressed: () {
          LanguageStore.instance.setLanguage(
            current == AppLanguage.portuguese
                ? AppLanguage.english
                : AppLanguage.portuguese,
          );
        },
        icon: const Icon(Icons.language, size: 18),
        label: Text(current == AppLanguage.portuguese ? 'English' : 'Português'),
      ),
    );
  }
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key, this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _LanguageQuickSwitch(),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _BrandMark(palette: palette, large: true),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    uiText('The community isn’t connected yet'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    uiText('This app does not include sample reflections or demo accounts. To enable sign-up, posts, and voting across devices, configure Supabase and run the app with the two variables below.'),
                  ),
                  const SizedBox(height: 20),
                  const _CodePanel(
                    text: 'SUPABASE_URL=https://YOUR-PROJECT.supabase.co\n'
                        'SUPABASE_PUBLISHABLE_KEY=your-publishable-key',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    uiText('Run command:'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const _CodePanel(
                    text: 'flutter run --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co ' 
                        '--dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_KEY',
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      "${uiText('Initialization error')}: $error",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    uiText('Use only the client publishable key. Never include the secret/service_role key in the app.'),
                    style: TextStyle(color: palette.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  bool _isRegistering = false;
  bool _loading = false;
  bool _showPassword = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_isRegistering) {
        final response = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'display_name': _displayName.text.trim()},
        );
        if (response.session == null) {
          setState(() {
            _message = uiText('Account created. Confirm your email address, then sign in.');
            _messageIsError = false;
            _isRegistering = false;
          });
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      setState(() {
        _message = uiText(error.message);
        _messageIsError = true;
      });
    } catch (_) {
      setState(() {
        _message = uiText('Could not complete the request. Check your connection and try again.');
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: palette.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(alignment: Alignment.centerRight, child: _LanguageQuickSwitch()),
                      Center(child: _BrandMark(palette: palette, large: true)),
                      const SizedBox(height: 30),
                      Text(
                        _isRegistering ? uiText('Create account') : uiText('Back to ideas'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegistering
                            ? uiText('Create a profile to write and discover reflections.')
                            : uiText('Sign in to read, write, and react to reflections.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.muted),
                      ),
                      const SizedBox(height: 24),
                      if (_isRegistering) ...[
                        TextFormField(
                          controller: _displayName,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(labelText: uiText('Display name'), prefixIcon: const Icon(Icons.person_outline)),
                          validator: (value) {
                            if (!_isRegistering) return null;
                            if ((value ?? '').trim().length < 2) return uiText('Enter a name with at least 2 characters.');
                            if ((value ?? '').trim().length > 36) return uiText('Maximum 36 characters.');
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(labelText: uiText('Email'), prefixIcon: const Icon(Icons.mail_outline)),
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (!email.contains('@') || !email.contains('.')) return uiText('Enter a valid email address.');
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: !_showPassword,
                        autofillHints: _isRegistering ? const [AutofillHints.newPassword] : const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: uiText('Password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _showPassword ? uiText('Hide password') : uiText('Show password'),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 8) return uiText('Use at least 8 characters.');
                          return null;
                        },
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _messageIsError ? const Color(0xFFFFE8E5) : const Color(0xFFE5F0E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_message!, style: TextStyle(color: _messageIsError ? const Color(0xFF8C2E28) : const Color(0xFF28543A))),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_isRegistering ? uiText('Create account') : uiText('Sign in')),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                  _isRegistering = !_isRegistering;
                                  _message = null;
                                }),
                        child: Text(_isRegistering ? uiText('Already have an account? Sign in') : uiText('Don’t have an account? Sign up')),
                      ),
                      if (!_isRegistering) ...[
                        Center(
                          child: TextButton(
                            onPressed: _loading ? null : _resetPassword,
                            child: Text(uiText('Forgot password?')),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() {
        _message = uiText('Enter your email first to receive a password reset link.');
        _messageIsError = true;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      setState(() {
        _message = uiText('If this email is registered, you’ll receive password reset instructions.');
        _messageIsError = false;
      });
    } catch (_) {
      setState(() {
        _message = uiText('Could not send the password reset email.');
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _goTo(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPalette>(
      valueListenable: ThemeStore.instance.palette,
      builder: (context, palette, _) => _buildScaffold(context, palette),
    );
  }

  Widget _buildScaffold(BuildContext context, AppPalette palette) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final destinations = [
      _Destination(uiText('Explore'), Icons.explore_outlined, Icons.explore),
      _Destination(uiText('Write'), Icons.edit_note_outlined, Icons.edit_note),
      _Destination(uiText('Saved'), Icons.bookmark_border, Icons.bookmark),
      _Destination(uiText('Profile'), Icons.person_outline, Icons.person),
    ];

    Widget page;
    switch (_selectedIndex) {
      case 1:
        page = WritePage(onPublished: () => _goTo(0));
        break;
      case 2:
        page = SavedPage();
        break;
      case 3:
        page = ProfilePage();
        break;
      default:
        page = ExplorePage();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: _BrandMark(palette: palette),
        actions: compact
            ? [
                IconButton(
                  tooltip: uiText('Profile'),
                  onPressed: () => _goTo(3),
                  icon: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: 6),
              ]
            : [
                for (var i = 0; i < destinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: TextButton.icon(
                      onPressed: () => _goTo(i),
                      icon: Icon(i == _selectedIndex ? destinations[i].selectedIcon : destinations[i].icon, size: 19),
                      label: Text(destinations[i].label),
                      style: TextButton.styleFrom(
                        backgroundColor: i == _selectedIndex ? palette.bubble : Colors.transparent,
                        foregroundColor: palette.text,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
              ],
      ),
      body: SafeArea(child: page),
      bottomNavigationBar: compact
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _goTo,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            )
          : null,
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

enum RankingPeriod { day, week, month }

extension RankingPeriodLabel on RankingPeriod {
  String get label => switch (this) {
        RankingPeriod.day => uiText('DAY'),
        RankingPeriod.week => uiText('WEEK'),
        RankingPeriod.month => uiText('MONTH'),
      };

  DateTime get start {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      RankingPeriod.day => today,
      RankingPeriod.week => today.subtract(Duration(days: today.weekday - DateTime.monday)),
      RankingPeriod.month => DateTime(now.year, now.month),
    };
  }
}

class Reflection {
  Reflection({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    required this.reactionCount,
    required this.myReaction,
    required this.isSaved,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final int reactionCount;
  final String? myReaction;
  final bool isSaved;
}

class ReflectionService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Reads the server-enforced daily publication limit (Europe/Lisbon).
  static Future<bool> hasPublishedToday() async {
    final result = await _client.rpc('has_published_today');
    return result == true;
  }

  static Future<List<Reflection>> loadRange({
    required DateTime from,
    int limit = 100,
    bool rankByPopularity = false,
  }) async {
    final rows = await _client
        .from('reflections')
        .select('id, author_id, author_name, body, created_at')
        .gte('created_at', from.toUtc().toIso8601String())
        .lte('created_at', DateTime.now().toUtc().toIso8601String())
        // Chronological feed: latest publication first, regardless of popularity.
        .order('created_at', ascending: false)
        .limit(limit);
    return _enrichRows(List<Map<String, dynamic>>.from(rows), rankByPopularity: rankByPopularity);
  }

  static Future<List<Reflection>> loadSaved() async {
    final userId = _client.auth.currentUser!.id;
    final saves = await _client
        .from('saved_reflections')
        .select('reflection_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(200);
    final ids = List<Map<String, dynamic>>.from(saves)
        .map((row) => row['reflection_id'] as String)
        .toList();
    if (ids.isEmpty) return [];
    final rows = await _client
        .from('reflections')
        .select('id, author_id, author_name, body, created_at')
        .inFilter('id', ids)
        .limit(200);
    final result = await _enrichRows(List<Map<String, dynamic>>.from(rows));
    final order = {for (var i = 0; i < ids.length; i++) ids[i]: i};
    result.sort((a, b) => (order[a.id] ?? 999).compareTo(order[b.id] ?? 999));
    return result;
  }

  static Future<List<Reflection>> _enrichRows(
    List<Map<String, dynamic>> rows, {
    bool rankByPopularity = false,
  }) async {
    if (rows.isEmpty) return [];
    final ids = rows.map((row) => row['id'] as String).toList();
    final userId = _client.auth.currentUser!.id;
    // Counts are returned by a restricted SECURITY DEFINER RPC so the client
    // does not need SELECT access to other users' individual reaction rows.
    final rawCounts = await _client.rpc(
      'get_reaction_counts',
      params: {'p_reflection_ids': ids},
    );
    final reactionCounts = <String, int>{};
    for (final dynamic value in rawCounts as List) {
      final row = Map<String, dynamic>.from(value as Map);
      final reflectionId = row['reflection_id'] as String;
      final countValue = row['reaction_count'];
      final count = countValue is num ? countValue.toInt() : int.tryParse('$countValue') ?? 0;
      reactionCounts[reflectionId] = (reactionCounts[reflectionId] ?? 0) + count;
    }

    // Under RLS, users can read only their own reaction records.
    final ownReactionRows = await _client
        .from('reactions')
        .select('reflection_id,reaction_type')
        .eq('user_id', userId)
        .inFilter('reflection_id', ids);
    final myReactions = <String, String>{};
    for (final dynamic value in ownReactionRows) {
      final row = Map<String, dynamic>.from(value as Map);
      myReactions[row['reflection_id'] as String] = row['reaction_type'] as String;
    }

    final savedRows = await _client
        .from('saved_reflections')
        .select('reflection_id')
        .eq('user_id', userId)
        .inFilter('reflection_id', ids);
    final savedIds = List<Map<String, dynamic>>.from(savedRows)
        .map((row) => row['reflection_id'] as String)
        .toSet();

    final items = rows.map((row) {
      final id = row['id'] as String;
      return Reflection(
        id: id,
        authorId: row['author_id'] as String,
        authorName: (row['author_name'] as String?)?.trim().isNotEmpty == true
            ? row['author_name'] as String
            : uiText('User'),
        body: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        reactionCount: reactionCounts[id] ?? 0,
        myReaction: myReactions[id],
        isSaved: savedIds.contains(id),
      );
    }).toList();

    if (rankByPopularity) {
      items.sort((a, b) {
        final byVotes = b.reactionCount.compareTo(a.reactionCount);
        return byVotes != 0 ? byVotes : b.createdAt.compareTo(a.createdAt);
      });
    } else {
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return items;
  }

  static Future<void> createReflection(String body) async {
    final user = _client.auth.currentUser;
    if (user == null) throw AuthException(uiText('Sign in to publish.'));
    await _client.from('reflections').insert({
      'author_id': user.id,
      'body': body.trim(),
    });
  }

  static Future<void> toggleReaction(Reflection reflection, String type) async {
    final userId = _client.auth.currentUser!.id;
    if (reflection.authorId == userId) {
      throw StateError('self_reaction_not_allowed');
    }
    if (type != 'gosto' && type != 'levar') {
      throw ArgumentError.value(type, 'type', 'Unsupported reaction type');
    }
    if (reflection.myReaction == type) {
      await _client
          .from('reactions')
          .delete()
          .eq('reflection_id', reflection.id)
          .eq('user_id', userId);
    } else {
      await _client.from('reactions').upsert({
        'reflection_id': reflection.id,
        'user_id': userId,
        'reaction_type': type,
      }, onConflict: 'reflection_id,user_id');
    }
  }

  static Future<void> toggleSaved(Reflection reflection) async {
    final userId = _client.auth.currentUser!.id;
    if (reflection.isSaved) {
      await _client
          .from('saved_reflections')
          .delete()
          .eq('reflection_id', reflection.id)
          .eq('user_id', userId);
    } else {
      await _client.from('saved_reflections').insert({
        'reflection_id': reflection.id,
        'user_id': userId,
      });
    }
  }

  static Future<void> reportReflection(String reflectionId, String reason) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('reports').insert({
      'reflection_id': reflectionId,
      'reporter_id': userId,
      'reason': reason,
    });
  }

  static Future<String> displayName() async {
    final user = _client.auth.currentUser;
    if (user == null) return uiText('User');
    try {
      final profile = await _client
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();
      final name = profile?['display_name'] as String?;
      if (name != null && name.trim().isNotEmpty) return name;
    } catch (_) {}
    final metaName = user.userMetadata?['display_name'] as String?;
    return (metaName != null && metaName.trim().isNotEmpty)
        ? metaName
        : (user.email?.split('@').first ?? uiText('User'));
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  RankingPeriod _period = RankingPeriod.day;
  List<Reflection> _popular = [];
  List<Reflection> _today = [];
  bool _loading = true;
  String? _error;
  dynamic _channel;
  Timer? _refreshTimer;
  Timer? _periodicRefreshTimer;
  bool _isSamsungFold = false;

  @override
  void initState() {
    super.initState();
    _detectSamsungFold();
    _reload();
    _channel = Supabase.instance.client.channel('entrelinhas-reflections-live')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reflections',
        callback: (_) => _scheduleReload(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reactions',
        callback: (_) => _scheduleReload(),
      )
      ..subscribe();

    // Once reads of all individual reactions are restricted by RLS, Realtime
    // cannot reveal other users' reaction rows to this client. Periodic refresh
    // keeps aggregate counts and rankings reasonably fresh without exposing IDs.
    _periodicRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _reload(showLoader: false);
    });
  }

  Future<void> _detectSamsungFold() async {
    // Keep the cover-screen two-column layout for Galaxy Z Fold devices, while
    // ordinary phones keep the stacked layout at narrow widths. Device model
    // is read locally and is not sent to the Entrelinhas backend.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final manufacturer = info.manufacturer.toLowerCase();
      final model = info.model.toUpperCase().replaceAll(' ', '-');
      final isFold = manufacturer.contains('samsung') &&
          RegExp(r'^SM-F9\d{2}').hasMatch(model);
      if (mounted && isFold && !_isSamsungFold) {
        setState(() => _isSamsungFold = true);
      }
    } catch (_) {
      // If device information is unavailable, fall back to width-based layout.
    }
  }

  void _scheduleReload() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _reload(showLoader: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _periodicRefreshTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _reload({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait<List<Reflection>>([
        ReflectionService.loadRange(from: _period.start, limit: 100, rankByPopularity: true),
        ReflectionService.loadRange(
          from: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
          limit: 15,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _popular = results[0];
        _today = results[1];
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
        _loading = false;
      });
    }
  }

  Future<void> _openReflection(Reflection reflection) async {
    await showDialog<void>(
      context: context,
      builder: (context) => ReflectionDetailDialog(
        reflection: reflection,
        onChanged: () async => _reload(showLoader: false),
      ),
    );
    if (mounted) await _reload(showLoader: false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return RefreshIndicator(
      onRefresh: _reload,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Foldable devices keep the right-hand Day Feed even on the cover
          // screen. On the Galaxy Z Fold cover display, the sidebar and cards
          // become narrower/denser. Ordinary phones retain the stacked layout.
          final compactFold = _isSamsungFold && constraints.maxWidth < 480;
          final wide = constraints.maxWidth >= 640 || _isSamsungFold;
          final sidebarWidth = compactFold
              ? 116.0
              : constraints.maxWidth < 720
                  ? 180.0
                  : constraints.maxWidth < 1000
                      ? 235.0
                      : 300.0;
          final columnGap = compactFold
              ? 8.0
              : constraints.maxWidth < 720
                  ? 14.0
                  : constraints.maxWidth < 1000
                      ? 20.0
                      : 30.0;
          final horizontalPadding = compactFold
              ? 8.0
              : !wide
                  ? 16.0
                  : constraints.maxWidth < 720
                      ? 14.0
                      : 28.0;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PeriodSelector(selected: _period, onSelected: (value) {
                      setState(() => _period = value);
                      _reload();
                    }),
                    const SizedBox(height: 28),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: _buildPopular(palette, compact: compactFold)),
                          SizedBox(width: columnGap),
                          SizedBox(width: sidebarWidth, child: _buildTodayFeed(palette, compact: compactFold)),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPopular(palette),
                          const SizedBox(height: 34),
                          _buildTodayFeed(palette),
                        ],
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopular(AppPalette palette, {bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(uiText('MOST POPULAR'), style: TextStyle(color: palette.muted, letterSpacing: compact ? 0.8 : 1.7, fontSize: compact ? 10 : 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          _ErrorPanel(message: _error!, onRetry: _reload)
        else if (_popular.isEmpty)
          _EmptyPanel(
            title: uiText('No reflections for this period yet.'),
            message: uiText('Publish the first reflection and start the conversation.'),
          )
        else
          ..._popular.take(12).map((reflection) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PopularReflectionCard(
                  reflection: reflection,
                  compact: compact,
                  onTap: () => _openReflection(reflection),
                ),
              )),
      ],
    );
  }

  Widget _buildTodayFeed(AppPalette palette, {bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(uiText('TODAY’S FEED'), style: TextStyle(color: palette.muted, letterSpacing: compact ? 0.4 : 1.7, fontSize: compact ? 10 : 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        if (!_loading && _today.isEmpty && _error == null)
          _EmptyPanel(title: uiText('Nothing here yet today.'), message: uiText('New reflections will appear here.'))
        else
          ..._today.take(15).map((reflection) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TodayFeedRow(reflection: reflection, compact: compact, onTap: () => _openReflection(reflection)),
              )),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected});
  final RankingPeriod selected;
  final ValueChanged<RankingPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return Row(
      children: RankingPeriod.values.map((period) {
        final isSelected = period == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 26),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: () => onSelected(period),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 9, top: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    period.label,
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.4,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? palette.primary : palette.muted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 2.5,
                    width: isSelected ? 34 : 0,
                    decoration: BoxDecoration(color: palette.primary, borderRadius: BorderRadius.circular(3)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PopularReflectionCard extends StatelessWidget {
  const _PopularReflectionCard({required this.reflection, required this.onTap, this.compact = false});
  final Reflection reflection;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return Material(
      color: palette.bubble,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          // Compact card: one line of reflection plus one author line, both inside the bubble.
          height: compact ? 68 : 78,
          padding: EdgeInsets.fromLTRB(compact ? 9 : 16, compact ? 8 : 11, compact ? 9 : 16, compact ? 7 : 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                reflection.body.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.text, fontSize: compact ? 12 : 15, height: 1.2, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  reflection.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.muted, fontSize: compact ? 10 : 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayFeedRow extends StatelessWidget {
  const _TodayFeedRow({required this.reflection, required this.onTap, this.compact = false});
  final Reflection reflection;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 11,
            vertical: compact ? 7 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 9 : 12),
            border: Border.all(color: palette.border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      reflection.body.replaceAll('\n', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: palette.text, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reflection.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 9, color: palette.muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        reflection.body.replaceAll('\n', ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: palette.text, height: 1.3),
                      ),
                    ),
                    const SizedBox(width: 9),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 74),
                      child: Text(
                        reflection.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 10, color: palette.muted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class ReflectionDetailDialog extends StatefulWidget {
  const ReflectionDetailDialog({super.key, required this.reflection, required this.onChanged});
  final Reflection reflection;
  final Future<void> Function() onChanged;

  @override
  State<ReflectionDetailDialog> createState() => _ReflectionDetailDialogState();
}

class _ReflectionDetailDialogState extends State<ReflectionDetailDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onChanged();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    final reflection = widget.reflection;
    final isOwnReflection = Supabase.instance.client.auth.currentUser?.id == reflection.authorId;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(reflection.authorName, style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700))),
                  IconButton(tooltip: uiText('Close'), onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 10),
              Text(reflection.body, style: TextStyle(color: palette.text, fontSize: 18, height: 1.55)),
              const SizedBox(height: 14),
              Text(_formatDate(reflection.createdAt), style: TextStyle(color: palette.muted, fontSize: 12)),
              const SizedBox(height: 16),
              Text(LanguageStore.instance.language.value == AppLanguage.portuguese
                  ? '${reflection.reactionCount} reações'
                  : '${reflection.reactionCount} reactions', style: TextStyle(color: palette.muted, fontSize: 13)),
              const SizedBox(height: 10),
              if (isOwnReflection)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    uiText('You cannot react to your own reflection.'),
                    style: TextStyle(color: palette.muted, fontSize: 13),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ReactionButton(label: uiText('Like'), selected: reflection.myReaction == 'gosto', busy: _busy, onTap: () => _runAction(() => ReflectionService.toggleReaction(reflection, 'gosto'))),
                    _ReactionButton(label: uiText('I’ll carry this with me'), selected: reflection.myReaction == 'levar', busy: _busy, onTap: () => _runAction(() => ReflectionService.toggleReaction(reflection, 'levar'))),
                  ],
                ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _runAction(() => ReflectionService.toggleSaved(reflection)),
                icon: Icon(reflection.isSaved ? Icons.bookmark_added_outlined : Icons.bookmark_add_outlined),
                label: Text(reflection.isSaved ? uiText('Remove from saved') : uiText('Save reflection')),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _busy ? null : _showReportDialog,
                  icon: const Icon(Icons.flag_outlined, size: 17),
                  label: Text(uiText('Report')),
                ),
              ),
              if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReportDialog() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(uiText('Report reflection')),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 'spam'), child: Text(uiText('Spam or advertising'))),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 'abuso'), child: Text(uiText('Harassment or abusive content'))),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 'other'), child: Text(uiText('Other reason'))),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    await _runAction(() => ReflectionService.reportReflection(widget.reflection.id, reason));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiText('Report submitted for review.'))));
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.label, required this.selected, required this.busy, required this.onTap});
  final String label;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return OutlinedButton(
      onPressed: busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? palette.bubble : Colors.transparent,
        side: BorderSide(color: selected ? palette.primary : palette.border),
        foregroundColor: palette.text,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class WritePage extends StatefulWidget {
  const WritePage({super.key, required this.onPublished});
  final VoidCallback onPublished;
  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _checkingDailyLimit = true;
  bool _alreadyPublishedToday = false;
  bool _dailyLimitCheckFailed = false;
  String? _error;
  static const int _maxLength = 1200;

  @override
  void initState() {
    super.initState();
    _checkDailyLimit();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkDailyLimit() async {
    if (mounted && !_checkingDailyLimit) {
      setState(() {
        _checkingDailyLimit = true;
        _dailyLimitCheckFailed = false;
        _error = null;
      });
    }
    try {
      final alreadyPublished = await ReflectionService.hasPublishedToday();
      if (!mounted) return;
      setState(() {
        _alreadyPublishedToday = alreadyPublished;
        _checkingDailyLimit = false;
        _dailyLimitCheckFailed = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checkingDailyLimit = false;
        _dailyLimitCheckFailed = true;
        _error = _friendlyError(error);
      });
    }
  }

  Future<void> _publish() async {
    if (_checkingDailyLimit || _dailyLimitCheckFailed || _alreadyPublishedToday) return;
    final body = _controller.text.trim();
    if (body.length < 10) {
      setState(() => _error = uiText('Your reflection must be at least 10 characters long.'));
      return;
    }
    if (body.length > _maxLength) {
      setState(() => _error = uiText('Maximum: 1,200 characters'));
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ReflectionService.createReflection(body);
      if (!mounted) return;
      setState(() => _alreadyPublishedToday = true);
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiText('Reflection published.'))));
      widget.onPublished();
    } catch (error) {
      final message = error.toString();
      if (message.contains('daily_reflection_limit')) {
        if (mounted) {
          setState(() {
            _alreadyPublishedToday = true;
            _error = null;
          });
        }
      } else if (mounted) {
        setState(() => _error = _friendlyError(error));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _dailyLimitNotice(AppPalette palette, String message, {bool loading = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loading)
            const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Icon(Icons.event_available_outlined, color: palette.primary, size: 21),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: palette.text, height: 1.4))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(uiText('WRITE'), style: TextStyle(color: palette.muted, letterSpacing: 1.7, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(uiText('An idea in your own words.'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(uiText('Don’t write just to collect votes. Share something you believe, a question, or a reflection you want others to read.'), style: TextStyle(color: palette.muted, height: 1.5)),
              const SizedBox(height: 10),
              Text(uiText('One reflection per day. Make it count.'), style: TextStyle(color: palette.muted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 22),
              if (_checkingDailyLimit)
                _dailyLimitNotice(palette, uiText('Checking today’s posting limit…'), loading: true)
              else if (_alreadyPublishedToday)
                _dailyLimitNotice(palette, uiText('You have already published today. Come back tomorrow.'))
              else if (_dailyLimitCheckFailed)
                _ErrorPanel(
                  message: _error ?? uiText('Could not verify today’s posting limit. Try again.'),
                  onRetry: _checkDailyLimit,
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: palette.border)),
                  child: TextField(
                    controller: _controller,
                    maxLength: _maxLength,
                    minLines: 8,
                    maxLines: 14,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: uiText('Write your reflection…'),
                      border: InputBorder.none,
                      filled: false,
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${_controller.text.length}/$_maxLength', style: TextStyle(color: palette.muted, fontSize: 12)),
                    const Spacer(),
                    Text(uiText('Minimum: 10 characters'), style: TextStyle(color: palette.muted, fontSize: 12)),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _publish,
                    icon: _sending ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_upward_rounded),
                    label: Text(_sending ? uiText('Publishing…') : uiText('Publish reflection')),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});
  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  bool _loading = true;
  String? _error;
  List<Reflection> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ReflectionService.loadSaved();
      if (mounted) setState(() { _items = items; _error = null; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _error = _friendlyError(error); _loading = false; });
    }
  }

  Future<void> _open(Reflection item) async {
    await showDialog<void>(context: context, builder: (context) => ReflectionDetailDialog(reflection: item, onChanged: _load));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          Text(uiText('SAVED'), style: TextStyle(color: palette.muted, letterSpacing: 1.7, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (_loading) const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator()))
          else if (_error != null) _ErrorPanel(message: _error!, onRetry: _load)
          else if (_items.isEmpty) _EmptyPanel(title: uiText('You haven’t saved any reflections yet.'), message: uiText('Open a reflection and choose Save to find it here.'))
          else ..._items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _PopularReflectionCard(reflection: item, onTap: () => _open(item)))),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    final user = Supabase.instance.client.auth.currentUser;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(uiText('PROFILE'), style: TextStyle(color: palette.muted, letterSpacing: 1.7, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: palette.border)),
          child: Row(
            children: [
              CircleAvatar(radius: 25, backgroundColor: palette.bubble, child: Icon(Icons.person_outline, color: palette.primary, size: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(future: ReflectionService.displayName(), builder: (context, snapshot) => Text(snapshot.data ?? uiText('Your account'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
                    const SizedBox(height: 3),
                    Text(user?.email ?? '', style: TextStyle(color: palette.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(uiText('LANGUAGE'), style: TextStyle(color: palette.muted, letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ValueListenableBuilder<AppLanguage>(
          valueListenable: LanguageStore.instance.language,
          builder: (context, language, _) => SegmentedButton<AppLanguage>(
            segments: const [
              ButtonSegment(value: AppLanguage.portuguese, label: Text('Português')),
              ButtonSegment(value: AppLanguage.english, label: Text('English')),
            ],
            selected: {language},
            onSelectionChanged: (selection) {
              LanguageStore.instance.setLanguage(selection.first);
            },
          ),
        ),
        const SizedBox(height: 28),
        Text(uiText('APP COLOURS'), style: TextStyle(color: palette.muted, letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppPalette.all.map((option) {
            final selected = option.id == palette.id;
            return InkWell(
              onTap: () => ThemeStore.instance.setPalette(option),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 142,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: option.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? option.primary : option.border, width: selected ? 2 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(_localizedPaletteName(option.id, option.name), style: TextStyle(color: option.text, fontWeight: FontWeight.w700))),
                      if (selected) Icon(Icons.check_circle, size: 17, color: option.primary),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      for (final color in [option.primary, option.accent, option.bubble])
                        Container(width: 24, height: 24, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7))),
                    ]),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
          },
          icon: const Icon(Icons.logout),
          label: Text(uiText('Sign out')),
          style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15)),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.palette, this.large = false});
  final AppPalette palette;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: large ? 49 : 36,
          height: large ? 49 : 36,
          decoration: BoxDecoration(color: palette.primary, borderRadius: BorderRadius.circular(large ? 15 : 11)),
          child: Icon(Icons.menu_book_rounded, color: Colors.white, size: large ? 27 : 21),
        ),
        SizedBox(width: large ? 13 : 10),
        Text(
          'Aporia',
          style: TextStyle(
            fontFamily: 'Georgia',
            color: palette.text,
            fontSize: large ? 29 : 23,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.1,
          ),
        ),
      ],
    );
  }
}

class _CodePanel extends StatelessWidget {
  const _CodePanel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: palette.bubble, borderRadius: BorderRadius.circular(12), border: Border.all(color: palette.border)),
      // Long environment variables and commands should remain usable on
      // narrow screens. The inner horizontal viewport prevents a flex
      // overflow while preserving selectable/copyable command text.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          text,
          maxLines: null,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeStore.instance.palette.value;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: palette.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: palette.text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(message, style: TextStyle(color: palette.muted, height: 1.45)),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFFFE9E7), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(uiText('Could not load the data.'), style: TextStyle(color: Color(0xFF812A24), fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(message, style: const TextStyle(color: Color(0xFF812A24), fontSize: 13)),
        const SizedBox(height: 10),
        TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(uiText('Try again'))),
      ]),
    );
  }
}

String _friendlyError(Object error) {
  if (error is AuthException) return uiText(error.message);
  final message = error is PostgrestException ? error.message : error.toString();
  if (message.contains('daily_reflection_limit')) {
    return uiText('You have already published today. Come back tomorrow.');
  }
  if (message.contains('self_reaction_not_allowed')) {
    return uiText('You cannot react to your own reflection.');
  }
  if (error is PostgrestException) {
    if (error.code == '42501') return uiText('The database rejected this action due to insufficient permissions. Check the Supabase RLS policies.');
    return error.message;
  }
  if (message.contains('SocketException') || message.contains('Failed host lookup')) {
    return uiText('Could not connect to the server. Check your internet connection and try again.');
  }
  return message.replaceFirst('Exception: ', '');
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} · ${two(date.hour)}:${two(date.minute)}';
}
