## v1.9.0 — Diálogos privados por convite
- Convites privados associados a uma reflexão, com mensagem completa visível antes da aceitação.
- Um convite por pessoa e por reflexão; uma nova reflexão permite um novo convite à mesma pessoa.
- Diálogos de 24 horas, prolongáveis por mais 24 horas apenas com consentimento dos dois participantes durante as últimas seis horas.
- Mensagens apenas de texto, sem ligações ou anexos nesta primeira fase.
- Recusar, denunciar e bloquear antes ou durante um diálogo; possibilidade de desbloquear.
- Preferência individual para aceitar ou não novos convites.
- Migração Supabase dedicada com RLS e operações de escrita através de RPCs validadas no servidor.

# Changelog

## v1.7.0 — Paletas Aporia selecionáveis
- Repostas as cinco paletas clássicas: Bosque, Oceano, Ameixa, Terracota e Sálvia.
- Adicionadas variações escuras de roxo, violeta, azul meia-noite, safira e dourado/âmbar.
- O tema original Aporia passa a ter um roxo de fundo ligeiramente mais intenso, mantendo o símbolo A dourado e a esfera central.
- Reintroduzido o seletor de cores em Perfil, com nomes localizados em português e inglês e preferência guardada no dispositivo.
- Adicionada a prancha visual gerada em `docs/aporia-branding-moodboard.png` como referência de design; a interface continua a ser composta por widgets Flutter interativos.
- Mantidos o layout adaptativo do Z Fold, idioma PT/EN, duas reações, limite diário, bloqueio de auto-reação e Supabase. Nenhuma migração SQL necessária.

## v1.6.0 — Identidade visual Aporia
- Paleta consistente azul-meia-noite, índigo, dourado, âmbar e marfim.
- Símbolo abstrato original no wordmark; retirado o ícone genérico de livro.
- Ícones Android/PWA/Web, favicon e splash Android atualizados.
- Script de branding preparado para atualizar o conjunto de ícones iOS quando a plataforma estiver gerada.
- Removido o seletor de cores para manter uma identidade de marca consistente; Português/English continua disponível.
- Mantido o identificador Android, o nome técnico do pacote, as funcionalidades atuais e a configuração Supabase. Nenhuma migração SQL é necessária para esta atualização visual.

## v1.5.3
- Alterado o nome visível da aplicação para Aporia, mantendo o identificador técnico existente.

## v1.5.2
- Corrigido o overflow horizontal no ecrã de configuração.

## v1.5.1
- Corrigido o erro de expressão constante na navegação bilingue.

## v1.5.0
- Duas reações: Gosto e Levo comigo.
- Uma publicação por conta por dia, com data calculada em Europe/Lisbon.
- Bloqueio de reações próprias na interface e no servidor.
- Mantidos feed cronológico, rankings DIA/SEMANA/MÊS, idioma PT/EN e layout adaptativo Z Fold.
