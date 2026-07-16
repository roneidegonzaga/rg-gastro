# Painel RG Gastrô | Guia de publicação

Seu sistema de gestão da consultoria: financeiro por linha de receita com filtros de período, contas a pagar e receber, CRM com funil e arrastar-e-soltar, projetos e tarefas, processos documentados por área (fluxo, texto, mapa mental e imagem), agenda com Google Calendar, equipe com papéis, clientes de consultoria com Sistema D.O.S.E., linha do tempo, documentos e dashboard automático, mentorados com sessões e plano de ação, e cursos com acompanhamento de matrícula até o certificado.

## Ver funcionando agora (sem configurar nada)

Extraia a pasta e dê dois cliques no `index.html`. Clique em Entrar. O painel abre em modo demonstração, já cheio de dados de exemplo. Explore tudo: os módulos, um cliente com o D.O.S.E. dentro, um mentorado com sessões.

## O que tem aqui

```
rg-gastro/
  index.html          login (email/senha + Google)
  app.html            o painel completo
  config.js           VOCÊ PRECISA PREENCHER
  dose-sync.js        isolamento dos dados D.O.S.E. por cliente
  setup-supabase.sql  banco de dados completo
  ferramentas/        as 21 ferramentas do Sistema D.O.S.E.
```

## Passo 1: Supabase

1. Crie um projeto novo em supabase.com (separado do projeto do produto D.O.S.E. dos alunos, se você publicar os dois).
2. SQL Editor > New query > cole o `setup-supabase.sql` inteiro > Run.
3. Settings > API: copie a Project URL e a anon public key pro `config.js`.
4. Pronto: com a URL e a chave preenchidas no `config.js`, o modo demonstração desliga sozinho.

### Como funcionam os acessos

A primeira conta criada vira admin automaticamente (crie a sua primeiro). Depois o Lehi cria a dele, você aprova na tela Equipe e define como admin. Equipe entra como pendente até alguém aprovar.

Papéis na v1: **admin** vê tudo. **equipe** vê CRM, projetos, agenda, clientes e mentorados, mas não vê Financeiro nem Contas (nem consegue acessar pelo banco, a trava é no servidor).

## Passo 2: Google Agenda (opcional)

1. Acesse console.cloud.google.com, crie um projeto (gratuito).
2. APIs e serviços > Biblioteca > ative a "Google Calendar API".
3. APIs e serviços > Tela de consentimento OAuth > configure (tipo Externo, preencha nome e email; pode deixar em "Testing" e adicionar seu email e o do Lehi como test users).
4. APIs e serviços > Credenciais > Criar credenciais > ID do cliente OAuth > tipo "Aplicativo da Web". Em "Origens JavaScript autorizadas", adicione o endereço do seu site (ex: https://painel.rggastro.com.br) e http://localhost:8000 pra testes.
5. Copie o Client ID pro campo `GOOGLE_CLIENT_ID` do `config.js`.

No painel, o botão "Conectar Google Agenda" passa a puxar seus eventos e a criar sessões e compromissos direto na sua agenda do Google.

## Passo 3: Publicar

Igual ao produto D.O.S.E.: suba a pasta na Vercel e aponte seu domínio (ex: painel.rggastro.com.br). Depois confira no Supabase, em Authentication > URL Configuration, se o Site URL aponta pro endereço final.

## Como o D.O.S.E. por cliente funciona

Dentro da ficha de cada cliente tem as 21 ferramentas. Tudo o que você preencher ali fica gravado naquele cliente (tabela própria no banco). Pode trabalhar com 30 clientes que os dados nunca se misturam. Ao marcar uma conta como paga ou recebida, o valor entra sozinho no Financeiro. Lead fechado no CRM vira cliente ou mentorado com um clique.

## O que avaliei e ficou pra fase 2

Contratos e documentos por cliente (precisa de storage de arquivos), emissão de cobrança e link de pagamento, relatórios em PDF pro cliente, permissões finas por seção (hoje é admin vs equipe), notificações por email ou WhatsApp de contas vencendo, e integração da agenda com criação automática de Meet. Tudo encaixa nessa base sem refazer nada.
