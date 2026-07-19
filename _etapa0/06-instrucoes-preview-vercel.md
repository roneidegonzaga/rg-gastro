# Proposta de preview da Vercel (Checkpoint 0.8)

**Nada aqui foi executado.** É uma proposta escrita, para quando o Supabase de desenvolvimento (Checkpoint 0.7) já existir — o preview depende das credenciais dele.

## Exige ação manual?

Sim — não tenho acesso autenticado à Vercel nesta sessão. A configuração de variáveis de ambiente e a vinculação de branch precisam ser feitas por você no painel da Vercel (ou, se preferir, posso preparar instruções ainda mais detalhadas passo a passo quando chegarmos lá).

## Proposta

| Item | Proposta |
|---|---|
| Branch utilizada | `desenvolvimento` (já criada nesta etapa) |
| Endereço de preview | O domínio automático que a Vercel gera por branch (ex.: `rg-gastro-git-desenvolvimento-<org>.vercel.app`) — evitar por enquanto um domínio customizado de preview, para não criar mais uma configuração de DNS a gerenciar |
| Variáveis exclusivas de desenvolvimento | Configuradas no painel da Vercel em **Settings → Environment Variables**, com o escopo marcado explicitamente como **Preview** (não "All Environments") — usando os mesmos nomes de chave que `config.dev.js`, mas nunca os valores de produção |
| Proteção contra uso da URL/chave de produção | Nunca configurar a variável de Preview com fallback para a de Production; ver regra abaixo |
| Identificação visual do ambiente | Proposta: o próprio `config.dev.js`/preview usa `NOME_SISTEMA: "RG Gastrô (DEV)"` (já assim no `config.dev.example.js` criado) — aparece no título/cabeçalho do painel, tornando impossível confundir visualmente com produção |

## Regras de segurança propostas

- **Nenhuma variável de produção deve servir de fallback no preview.** Se a variável de desenvolvimento não estiver configurada, o build/carregamento deve falhar de forma visível e segura — nunca "cair" silenciosamente para a URL de produção.
- Isso é equivalente, em espírito, ao comportamento que `app.html` já tem para o modo demonstração (`DEMO = !configured`) — a diferença é que hoje, se `config.js` estiver vazio, ele cai em modo demo; a proposta aqui é que, no ambiente de preview, a ausência da configuração de desenvolvimento **nunca** deve resultar em conexão com o Supabase de produção.

## Não será feito nesta etapa

- Nenhuma variável de ambiente será criada na Vercel
- Nenhum deploy será feito, nem no domínio real nem no de preview
- Nenhuma branch será vinculada a um projeto Vercel

Este documento fica pronto para quando o Checkpoint 0.7 estiver concluído e você quiser avançar para a configuração real do preview.
