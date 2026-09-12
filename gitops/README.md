# GitOps

Esta pasta é a fonte monitorada pelo ArgoCD. O workflow de CI altera somente a tag SHA em `base/<service>/deployment.yaml`; o ArgoCD detecta o commit e sincroniza os cinco serviços.

Antes de aplicar `argocd/application.yaml`, substitua `REPLACE_OWNER/REPLACE_REPOSITORY` pelo endereço do repositório. O External Secrets Operator lê `toggle-master/staging/application` no Secrets Manager usando as credenciais da role dos nodes. Em conta pessoal, restrinja essa permissão a uma policy específica em produção.
