output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.paynora_vpc.id
}

output "kyc_bucket_name" {
  description = "Name of the encrypted KYC documents storage bucket"
  value       = aws_s3_bucket.kyc_documents.id
}
