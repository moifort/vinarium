import { fixme } from 'fixme-nitro'

// DSN provided via NITRO_FIXME_DSN (Secret Manager in prod — infra/secrets.tf +
// function.tf — and .env locally), following the repo's NITRO_ convention. The SDK
// takes the dsn as an explicit argument, so it doesn't require the raw FIXME_DSN name.
export default fixme({ dsn: process.env.NITRO_FIXME_DSN })
