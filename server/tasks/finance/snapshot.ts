import { Finance } from '~/finance/index'

export default defineTask({
  meta: {
    name: 'finance:snapshot',
    description: 'Calcule et persiste le rapport financier mensuel de la cave',
  },
  async run() {
    await Finance.saveMonthlyReport()
    return { result: 'Success' }
  },
})
