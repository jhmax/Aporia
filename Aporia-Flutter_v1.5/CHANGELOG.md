# Changelog

## v1.5.3
- Changed visible brand to Aporia in the Flutter wordmark, app title, Android launcher label and generated Web title/manifest.
- Kept the existing Flutter package name, Android application ID and Supabase schema/data unchanged for compatibility.
- No Supabase migration is required for this display-name change.


## 1.5.0
- Duas reações: Gosto e Levo comigo; votos anteriores preservados através de mapeamento de valores.
- Uma publicação por conta por dia (Europe/Lisbon), protegida por reserva única na base de dados.
- O limite diário continua aplicado mesmo se a publicação for apagada.
- Bloqueio de auto-reação no UI e no servidor; contagens agregadas excluem reações próprias históricas.
- Mantidos PT/EN, layout adaptativo Z Fold, feed cronológico e backend partilhado.


## v1.5.1
- Corrigido o erro `const_eval_method_invocation` no menu de navegação bilingue, removendo `const` da lista de destinos que chama `uiText()`.

## v1.5.2
- Corrigido overflow horizontal no ecrã de configuração em ecrãs estreitos: seletor de idioma/logótipo reduzem a escala quando necessário e painéis de comandos permitem deslocamento horizontal.
- Mantém as regras v1.5.1, o layout Z Fold, o idioma PT/EN e as integrações Supabase.
