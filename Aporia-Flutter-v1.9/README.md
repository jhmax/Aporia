# Aporia Flutter v1.7 — identidade visual e paletas seleccionáveis

Esta versão aplica o branding original Aporia (símbolo “A” dourado com esfera central), usa a paleta roxo/índigo/azul/dourado e volta a disponibilizar temas alternativos no ecrã Perfil.

## Identidade visual

- Paleta Aporia predefinida: roxo profundo, índigo, dourado, âmbar e marfim.
- Variantes escuras: Aporia Original, Deep Violet, Royal Purple, Midnight Blue, Sapphire e Amber Night.
- Paleta clara adicional: Lavender.
- Paletas clássicas restauradas: Forest/Bosque, Ocean/Oceano, Plum/Ameixa, Terracotta/Terracota e Sage/Sálvia.
- As cores podem ser alteradas em **Perfil → Cores da aplicação**. A seleção fica guardada localmente por dispositivo.
- `assets/branding/aporia-mark-transparent-512.png` é o símbolo utilizado no UI Flutter. `assets/branding/aporia-icon-1024.png` e `assets/branding/launcher-icons/` fornecem os ícones das plataformas.
- `docs/aporia-branding-moodboard.png` contém a prancha visual criada durante o design; é uma referência, não uma imagem estática usada como ecrã da app.

## Funcionalidades preservadas

- Português por defeito, com opção English.
- Layout adaptativo para Galaxy Z Fold, Android e Web.
- Feed do Dia cronológico; separadores DIA, SEMANA e MÊS.
- Duas reações: `gosto` e `levar`; uma reação ativa por pessoa/reflexão.
- Limite de uma publicação diária por conta e bloqueio de auto-reação.
- Supabase, autenticação, contas, reflexões, votos, guardados e denúncias permanecem inalterados.

## Atualizar o projeto funcional no Mac

Faz primeiro uma cópia de segurança. Para atualizar a pasta de um projeto já preparado, copia estes itens deste ZIP: `lib/main.dart`, `pubspec.yaml`, a pasta `assets/branding/`, `scripts/set_app_display_name.py`, `test/widget_test.dart`, `README.md`, `CHANGELOG.md` e `docs/aporia-branding-moodboard.png`. Mantém as pastas nativas `android/` e `web/`, o `.gitignore` funcional e quaisquer ficheiros locais que não queiras substituir.

Na raiz do projeto, executa:

```bash
flutter pub get
python3 scripts/set_app_display_name.py
flutter analyze
flutter test
```

O script aplica nome, ícones, splash e favicon às plataformas já geradas. Não altera o Supabase.

## Preparar um projeto novo

O ZIP inclui `.gitignore` e o script de preparação para evitar o problema anterior com a pasta Android. Para gerar Android e Web num projeto novo:

```bash
bash scripts/bootstrap_platforms.sh
flutter analyze
flutter test
```

O script já executa `flutter pub get`.

## Executar no Android

```bash
flutter run -d ID_DO_DISPOSITIVO \
  --dart-define=SUPABASE_URL="https://O-TEU-PROJETO.supabase.co" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="A-TUA-CHAVE-PUBLICAVEL"
```

## Executar a versão Web localmente

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 \
  --dart-define=SUPABASE_URL="https://O-TEU-PROJETO.supabase.co" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="A-TUA-CHAVE-PUBLICAVEL"
```

Depois abre `http://localhost:8080`. O ficheiro `.env` não é carregado automaticamente pelo Flutter; as credenciais são passadas por `--dart-define`. Usa apenas a chave publicável no cliente, nunca `service_role` ou `sb_secret_`.

## Supabase

**Não executes novamente** `supabase/entrelinhas_schema.sql` nem `supabase/migration_daily_post_two_reactions.sql` na tua base de dados existente. Esta versão só altera o código e os recursos visuais; não exige migração SQL.
