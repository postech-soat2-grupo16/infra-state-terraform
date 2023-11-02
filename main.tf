provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-soat"
 
  #Não vai deletar o S3 de maneira acidental
  lifecycle {
    prevent_destroy = true
  }
}

#Habilita o versionamento
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

#Habilita enctriptação server-side, ou seja, se existir alguma secret, será enctriptada
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#Garante o bloqueio ao acesso público do S3
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#Cria um DynamoDB para fazer o LOCKING
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-soat-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

#Configuração do Terraform State
terraform {
  backend "s3" {
    bucket         = "terraform-state-soat"
    key            = "s3-configuration/terraform.tfstate"
    region         = "us-east-1"

    dynamodb_table = "terraform-state-soat-locking"
    encrypt        = true
  }
}