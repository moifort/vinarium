/* Vinarium landing page.
 *
 * Everything that moves on this page and is not plain CSS is driven from here:
 *  1. The showcase: three iPhones under the hero that fan out as the page
 *     scrolls.
 *  2. The cellar grid filling slot by slot.
 *  3. The cards and titles revealed as they scroll in.
 */

;(() => {
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

  // ---------------------------------------------------------------------------
  // The showcase
  // ---------------------------------------------------------------------------

  // The side phones wait behind the home screen until the page moves, then
  // come out with the scroll, fully fanned after a third of a screen. A
  // browser with scroll-driven animations fans them in CSS and needs none of
  // this; reduced motion leaves them fanned, as the stylesheet draws them.
  const trio = document.querySelector('.trio')
  if (trio && !reducedMotion && !CSS.supports('animation-timeline: scroll()')) {
    let pending = false
    const fan = () => {
      pending = false
      const progress = scrollY / (innerHeight * 0.33)
      trio.style.setProperty('--fan', String(Math.min(1, Math.max(0, progress)).toFixed(3)))
    }
    const schedule = () => {
      if (!pending) {
        pending = true
        requestAnimationFrame(fan)
      }
    }
    addEventListener('scroll', schedule, { passive: true })
    addEventListener('resize', schedule)
    fan()
  }

  // ---------------------------------------------------------------------------
  // The cellar grid
  // ---------------------------------------------------------------------------

  /** Runs `start` once, the first time `el` comes on screen. */
  function whenVisible(el, start) {
    if (!el) return
    let started = false
    new IntersectionObserver(
      (entries) => {
        if (started || !entries.some((e) => e.isIntersecting)) return
        started = true
        start()
      },
      { threshold: 0.3 },
    ).observe(el)
  }

  /** Deterministic noise in [0, 1) for a given integer. */
  function hash(n) {
    const x = Math.sin(n * 127.1 + 311.7) * 43758.5453
    return x - Math.floor(x)
  }

  // Eight columns by six rows, the 48 slots of the home screen's cellar. The
  // capsules wear the icon's colours: burgundy, garnet, plum, gold, amber.
  const CAPSULES = ['#7b1e30', '#a3283c', '#6e3550', '#c9a24a', '#c9852f', '#8e2a3c']
  const SLOTS = 48
  const FILLED = 18

  const rackDemo = document.querySelector('[data-rack-demo]')
  if (rackDemo) {
    const rack = rackDemo.querySelector('[data-rack]')
    const count = rackDemo.querySelector('[data-rack-count] b')
    const slots = []
    for (let i = 0; i < SLOTS; i++) {
      const slot = document.createElement('i')
      slot.style.setProperty('--c', CAPSULES[Math.floor(hash(i) * CAPSULES.length)])
      rack.appendChild(slot)
      slots.push(slot)
    }
    // The order the bottles go in: scattered, as a real cellar fills.
    const order = slots
      .map((slot, i) => ({ slot, key: hash(i + 100) }))
      .sort((a, b) => a.key - b.key)
      .slice(0, FILLED)
      .map((entry) => entry.slot)

    if (reducedMotion) {
      for (const slot of order) slot.classList.add('in')
      count.textContent = String(FILLED)
    } else {
      whenVisible(rackDemo, async () => {
        for (;;) {
          for (const slot of order) slot.classList.remove('in')
          count.textContent = '0'
          await sleep(900)
          for (let i = 0; i < order.length; i++) {
            order[i].classList.add('in')
            count.textContent = String(i + 1)
            await sleep(240)
          }
          await sleep(3600)
        }
      })
    }
  }

  // ---------------------------------------------------------------------------
  // Reveal on scroll
  // ---------------------------------------------------------------------------

  for (const el of document.querySelectorAll(
    '.card, .tile, .faq-list details, .section-title, .section-lead',
  )) {
    el.classList.add('reveal')
  }
  const revealer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add('in')
          revealer.unobserve(entry.target)
        }
      }
    },
    { threshold: 0.15 },
  )
  for (const el of document.querySelectorAll('.reveal')) revealer.observe(el)
})()
