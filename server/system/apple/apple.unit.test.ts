import { beforeEach, describe, expect, mock, test } from 'bun:test'

// The real config reads Nitro's runtime config, which only exists in a request.
let appleAppId: number | undefined
let appleEnvironment: string | undefined
mock.module('~/system/config/index', () => ({
  config: () => ({ appleAppId, appleEnvironment }),
}))

const { Apple } = await import('~/system/apple')

beforeEach(() => {
  appleAppId = undefined
  appleEnvironment = undefined
})

describe('verifying something Apple did not sign', () => {
  // The App Store id only exists once App Store Connect has handed it over, and
  // Apple's verifier refuses to be built for Production without it. That must
  // read as "this did not verify" rather than take down the purchase path.
  test('answers invalid-signature while the App Store id is still unknown', async () => {
    expect(await Apple.verifyTransaction('not-a-jws')).toBe('invalid-signature')
    expect(await Apple.verifyNotification('not-a-jws')).toBe('invalid-signature')
  })

  test('answers invalid-signature once the App Store id is known', async () => {
    appleAppId = 6789688303

    expect(await Apple.verifyTransaction('not-a-jws')).toBe('invalid-signature')
  })

  test('answers invalid-signature with a pinned environment', async () => {
    appleEnvironment = 'Sandbox'

    expect(await Apple.verifyTransaction('not-a-jws')).toBe('invalid-signature')
  })

  test('refuses a forged payload rather than decoding it', async () => {
    // A syntactically valid JWS whose signature chains to nothing of Apple's.
    const forged = [
      Buffer.from(JSON.stringify({ alg: 'ES256', x5c: [] })).toString('base64url'),
      Buffer.from(
        JSON.stringify({ productId: 'com.polyforms.vinarium.app.premium.yearly' }),
      ).toString('base64url'),
      'c2lnbmF0dXJl',
    ].join('.')

    expect(await Apple.verifyTransaction(forged)).toBe('invalid-signature')
  })
})
