# Aporia Flutter v1.5.3 — Português / English

Aporia é o novo nome visível da aplicação existente Entrelinhas. Esta versão altera a marca apresentada na interface, o nome do ícone Android e o título/nome da Web para **Aporia**. O idioma predefinido continua a ser Português, com opção English no Perfil.

**Compatibilidade mantida de propósito:** o nome do pacote Flutter (`entrelinhas`), o identificador Android (`com.entrelinhas.entrelinhas`), as chaves de preferências locais, o projeto Supabase, as tabelas, as políticas e os dados existentes não são renomeados. Isto permite atualizar a aplicação instalada sem migrar contas ou dados. O desenho do ícone não muda nesta versão.

**Esta alteração é apenas de nome/marca. Não executes qualquer SQL no Supabase por causa desta atualização.**

## Regras implementadas nesta versão

- Uma publicação por conta por dia, com o dia de calendário calculado no fuso `Europe/Lisbon`.
- O limite é aplicado na interface e reservado no servidor com uma chave única por conta/dia; apagar a reflexão não liberta o lugar desse dia.
- Publicações de 10 a 1.200 caracteres (validação da interface e constraint da base de dados existente).
- Duas reações: `Gosto` (`gosto`) e `Levo comigo` (`levar`).
- Uma única reação ativa por utilizador e publicação. Mudar de reação atualiza o registo existente; não cria um voto adicional.
- O autor não pode reagir à própria publicação; a interface e um trigger da base de dados aplicam a regra.
- Cada reação de um utilizador a uma publicação conta como um voto. Contagens não incluem reações próprias históricas.
- O Feed do Dia continua cronológico; as reações não alteram a ordem desse feed.
- DIA / SEMANA / MÊS continuam a usar o mecanismo de populares já existente; esta versão não introduz uma nova teoria de popularidade.
- Layout adaptativo de Galaxy Z Fold, incluindo o Feed do Dia à direita no ecrã exterior/interior.

## Supabase: não é necessária qualquer migração nesta versão

Esta versão só altera a marca visível para **Aporia**. Mantém as mesmas tabelas, políticas, funções, contas, reflexões, reações e regras de publicação. **Não executes nenhum ficheiro SQL por causa desta atualização.** Em particular, não voltes a executar `supabase/entrelinhas_schema.sql` nem `supabase/migration_daily_post_two_reactions.sql` no projeto já existente.

## Atualizar uma instalação de desenvolvimento já preparada

Se já tens as pastas `android/` e `web/` geradas no teu projeto funcional, não precisas de voltar a executar o script que recria essas plataformas. Copia o `lib/main.dart` e `scripts/set_app_display_name.py` desta versão para o teu projeto existente e executa:

```bash
python3 scripts/set_app_display_name.py
flutter analyze
flutter test
```

O script atualiza o nome do launcher Android para Aporia e os títulos da Web. Não altera o identificador da aplicação, as credenciais, as tabelas ou os dados.

Se estiveres a preparar este ZIP como um projeto novo no teu Mac, segue a preparação no macOS abaixo; o script de bootstrap gera Android/Web e aplica o nome Aporia.

## Requisitos

- Flutter stable / Dart 3.9 ou mais recente.
- Android Studio / Android SDK e um dispositivo Android ou emulador.
- URL e publishable key do Supabase.

## Preparação no macOS

Na pasta deste projeto:

```bash
bash scripts/bootstrap_platforms.sh
flutter analyze
flutter test
```

O script já executa `flutter pub get`. A pasta `android/` e `web/` são geradas no computador de desenvolvimento.

## Executar no Android

```bash
flutter run -d ID_DO_DISPOSITIVO \
  --dart-define=SUPABASE_URL="https://O-TEU-PROJETO.supabase.co" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="A-TUA-CHAVE-PUBLICAVEL"
```

## Executar na Web localmente

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 \
  --dart-define=SUPABASE_URL="https://O-TEU-PROJETO.supabase.co" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="A-TUA-CHAVE-PUBLICAVEL"
```

Depois abre `http://localhost:8080`.

Usa apenas a publishable key no cliente. Nunca coloques `service_role` ou `sb_secret_` na app. O ficheiro `.env` não é carregado automaticamente pelo Flutter; para este projeto usam-se `--dart-define`.

## SQL files

- `supabase/entrelinhas_schema.sql`: esquema completo para um projeto Supabase novo, já com as regras v1.5.
- `supabase/migration_daily_post_two_reactions.sql`: migração para o projeto existente. É o ficheiro a executar agora.
- `supabase/secure_reactions_migration.sql`: referência histórica; não é necessário executar separadamente após a migração v1.5.
- `supabase/verify_security.sql`: consultas de verificação; não altera dados.

## Antes do lançamento público

Ainda é necessário testar no Mac: `flutter analyze`, `flutter test`, publicação diária, bloqueio de auto-reação, mudança de reação, contagens entre Android/Web e a apresentação no Z Fold. Também são necessários fluxos completos de eliminação de conta, privacidade e moderação antes de abrir publicamente.
