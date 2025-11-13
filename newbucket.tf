resource "aws_s3_bucket_object" "manifest_file" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "manifests/my_manifest.json"
  content = jsonencode({
    entries = [
      { url = "s3://my-bucket/data/file1.csv" },
      { url = "s3://my-bucket/data/file2.csv" }
    ]
  })
  content_type = "application/json"
}
