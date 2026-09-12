# ToggleMaster Tech Challenge

Este repositório contempla a entrega de IaC, DevSecOps e GitOps para os cinco microsserviços.

## Fluxo

1. `terraform/` cria VPC, subnets públicas/privadas, EKS, node group, três PostgreSQL, Redis, DynamoDB, SQS e cinco ECR. O backend é S3 com lockfile.
2. `.github/workflows/` executa build/testes, lint, SAST, SCA, scan da imagem e publica no ECR somente quando não há vulnerabilidade crítica.
3. O workflow altera a tag SHA em `gitops/base/*/deployment.yaml` e faz commit no repositório GitOps.
4. `terraform` instala ArgoCD e External Secrets. A aplicação em `gitops/argocd/application.yaml` habilita sync automático, prune e self-heal.

## Configuração

Configure `AWS_GITHUB_ACTIONS_ROLE_ARN` como secret do GitHub usando OIDC. Substitua o `repoURL` da Application pelo repositório real. Os valores da aplicação devem ser enviados ao Terraform por variáveis sensíveis; não use `k8s/secrets.yaml` nem comite credenciais.

Para a apresentação, mostre `terraform plan`, uma execução falhando no Trivy com vulnerabilidade crítica, a atualização do SHA no GitOps e o sync dos cinco deployments na UI do ArgoCD.
