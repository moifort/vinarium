terraform {
  backend "gcs" {
    bucket = "vinarium-prod-tfstate"
    prefix = "cave-a-vin"
  }
}
