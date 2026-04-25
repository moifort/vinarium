terraform {
  backend "gcs" {
    bucket = "vinarium-prod-tfstate"
    prefix = "vinarium"
  }
}
