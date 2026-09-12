locals {
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + 8)]
  service_names   = ["auth-service", "flag-service", "targeting-service", "evaluation-service", "analytics-service"]
  lab_role_arn    = var.academy_mode ? data.aws_iam_role.academy_lab[0].arn : aws_iam_role.eks[0].arn
  node_role_arn   = var.academy_mode ? data.aws_iam_role.academy_lab[0].arn : aws_iam_role.nodes[0].arn
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}
resource "aws_internet_gateway" "this" { vpc_id = aws_vpc.this.id }
resource "aws_subnet" "public" {
  count                   = length(local.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.cluster_name}-public-${count.index + 1}", "kubernetes.io/role/elb" = "1", "kubernetes.io/cluster/${var.cluster_name}" = "shared" }
}
resource "aws_subnet" "private" {
  count             = length(local.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]
  tags              = { Name = "${var.cluster_name}-private-${count.index + 1}", "kubernetes.io/role/internal-elb" = "1", "kubernetes.io/cluster/${var.cluster_name}" = "shared" }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_eip" "nat" { domain = "vpc" }
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.this]
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
}
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_iam_role" "eks" {
  count              = var.academy_mode ? 0 : 1
  name               = "${var.cluster_name}-eks-role"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "eks.amazonaws.com" }, Action = "sts:AssumeRole" }] })
}
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  count      = var.academy_mode ? 0 : 1
  role       = aws_iam_role.eks[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role" "nodes" {
  count              = var.academy_mode ? 0 : 1
  name               = "${var.cluster_name}-nodes-role"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }] })
}
resource "aws_iam_role_policy_attachment" "nodes" {
  for_each   = var.academy_mode ? toset([]) : toset(["AmazonEKSWorkerNodePolicy", "AmazonEC2ContainerRegistryReadOnly", "AmazonEKS_CNI_Policy", "SecretsManagerReadWrite"])
  role       = aws_iam_role.nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/${each.key}"
}
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = local.lab_role_arn
  vpc_config {
    subnet_ids             = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_public_access = true
  }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = local.node_role_arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["t3.medium"]
  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 4
  }
  depends_on = [aws_iam_role_policy_attachment.nodes]
}

resource "aws_security_group" "data" {
  name   = "${var.cluster_name}-data"
  vpc_id = aws_vpc.this.id
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_db_subnet_group" "this" {
  name       = var.cluster_name
  subnet_ids = aws_subnet.private[*].id
}
resource "aws_db_instance" "postgres" {
  for_each               = toset(["auth", "flags", "targeting"])
  identifier             = "${var.cluster_name}-${each.key}-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "${each.key}db"
  username               = var.database_username
  password               = var.database_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.data.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  storage_encrypted      = true
}
resource "aws_elasticache_subnet_group" "this" {
  name       = var.cluster_name
  subnet_ids = aws_subnet.private[*].id
}
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.cluster_name}-redis"
  description          = "ToggleMaster cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_clusters   = 1
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.data.id]
}
resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"
  attribute {
    name = "event_id"
    type = "S"
  }
}
resource "aws_sqs_queue" "events" {
  name                       = "toggle-master-evaluation-events"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600
}
resource "aws_ecr_repository" "service" {
  for_each             = toset(local.service_names)
  name                 = each.key
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
}
resource "aws_secretsmanager_secret" "application" { name = "${var.cluster_name}/${var.environment}/application" }
resource "aws_secretsmanager_secret_version" "application" {
  secret_id     = aws_secretsmanager_secret.application.id
  secret_string = jsonencode(var.secret_values)
}
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.10.5"
  depends_on       = [aws_eks_node_group.main]
}
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "6.7.18"
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
  depends_on = [aws_eks_node_group.main]
}
