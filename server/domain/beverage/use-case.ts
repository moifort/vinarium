import { AttachmentCommand } from '~/domain/attachment/command'
import { BeverageCommand } from '~/domain/beverage/command'
import { BeverageQuery } from '~/domain/beverage/query'
import type { BeverageId, BeverageName, BeverageType } from '~/domain/beverage/types'
import { CellarCommand } from '~/domain/cellar/command'
import { GiftCommand } from '~/domain/gift/command'
import { GiftQuery } from '~/domain/gift/query'
import { JournalCommand } from '~/domain/journal/command'
import { RecommendationCommand } from '~/domain/recommendation/command'
import type { Recommendation } from '~/domain/recommendation/types'
import type { PersonName, UserId } from '~/domain/shared/types'
import { TastingCommand } from '~/domain/tasting/command'
import type { TastingNote } from '~/domain/tasting/types'
import { atomically } from '~/utils/firestore'

type BeverageData = Parameters<typeof BeverageCommand.add>[3]

export namespace BeverageUseCase {
  // Add a beverage together with what the scan form already knows about it: who
  // gave it (the giftedBy field lives in the gift domain — a beverage only carries
  // what it is), the viewer's tasting note and the recommendation behind it. One
  // batch: a failure leaves no bottle without the note the user just wrote.
  export const add = async (
    userId: UserId,
    name: BeverageName,
    beverageType: BeverageType,
    data: BeverageData,
    extras: {
      receivedFrom?: PersonName
      tasting?: Omit<TastingNote, 'userId' | 'beverageId'>
      recommendation?: Omit<Recommendation, 'userId' | 'beverageId'>
    } = {},
  ) =>
    await atomically(async (batch) => {
      const result = await BeverageCommand.add(userId, name, beverageType, data, batch)
      if (typeof result === 'string') return result
      const { receivedFrom, tasting, recommendation } = extras
      if (receivedFrom) await GiftCommand.receiveFrom(userId, result.id, receivedFrom, batch)
      if (tasting) await TastingCommand.create({ userId, beverageId: result.id, ...tasting }, batch)
      if (recommendation)
        await RecommendationCommand.create(
          { userId, beverageId: result.id, ...recommendation },
          batch,
        )
      return result
    })

  export const update = async (
    userId: UserId,
    id: BeverageId,
    data: Parameters<typeof BeverageCommand.update>[2],
    receivedFrom?: PersonName,
    erase: Parameters<typeof BeverageCommand.update>[3] = [],
  ) => {
    const result = await BeverageCommand.update(userId, id, data, erase)
    if (typeof result !== 'string' && receivedFrom)
      await GiftCommand.receiveFrom(userId, id, receivedFrom)
    return result
  }

  // One screen, one save. The wine sheet edits four records at once (the bottle,
  // its tasting note, the gift it was, the recommendation behind it); sending them
  // as four mutations meant four round trips and a half-written sheet whenever the
  // second one failed. Everything below lands together or not at all.
  //
  // Each part is optional: what the user did not touch is not sent, so a bottle
  // that was never tasted does not grow an empty tasting note just because its
  // name was corrected. Without the bottle part, the sheet only carries the
  // viewer's own records, so it may be saved on any wine they can see — a
  // housemate's bottle they heart or were recommended included.
  export const saveSheet = async (
    userId: UserId,
    id: BeverageId,
    sheet: {
      beverage?: Parameters<typeof BeverageCommand.update>[2]
      erase?: Parameters<typeof BeverageCommand.update>[3]
      receivedFrom?: PersonName
      tasting?: Omit<TastingNote, 'userId' | 'beverageId'>
      gift?: { recipientName?: PersonName; date?: Date }
      recommendation?: Omit<Recommendation, 'userId' | 'beverageId'>
    },
  ) => {
    // Every refusal is settled before the first write is enlisted: a batch commits
    // whatever it already holds, so a part refused halfway would leave the earlier
    // ones written — the very thing this exists to prevent. The beverage rules
    // (colour, subtype, existence) refuse before writing on their own; the gift
    // precondition and the visibility of someone else's wine are read up front.
    if (sheet.gift && !(await GiftQuery.byBeverage(userId, id))?.given)
      return 'gift-not-found' as const
    const visible = sheet.beverage ? undefined : await BeverageQuery.byIdForViewer(userId, id)
    if (visible === 'not-found') return 'not-found' as const

    return await atomically(async (batch) => {
      const saved =
        visible ??
        (await BeverageCommand.update(userId, id, sheet.beverage ?? {}, sheet.erase, batch))
      if (typeof saved === 'string') return saved

      if (sheet.gift || sheet.receivedFrom)
        await GiftCommand.correct(
          userId,
          id,
          { given: sheet.gift, receivedFrom: sheet.receivedFrom },
          batch,
        )
      if (sheet.tasting)
        await TastingCommand.create({ userId, beverageId: id, ...sheet.tasting }, batch)
      if (sheet.recommendation)
        await RecommendationCommand.create(
          { userId, beverageId: id, ...sheet.recommendation },
          batch,
        )
      return saved
    })
  }

  const eraseRecords = async (userId: UserId, id: BeverageId) =>
    await atomically(async (batch) => {
      const error = await BeverageCommand.remove(userId, id, batch)
      if (error === 'not-found') return 'not-found' as const
      // Every domain enlists its deletions into the same batch: the beverage and
      // all related entries vanish together or not at all. CellarCommand
      // .eraseBeverage skips bottle-out journaling because the whole journal is
      // wiped here.
      await Promise.all([
        CellarCommand.eraseBeverage(userId, id, batch),
        TastingCommand.removeBeverage(userId, id, batch),
        GiftCommand.removeBeverage(userId, id, batch),
        RecommendationCommand.removeBeverage(userId, id, batch),
        JournalCommand.removeBeverage(userId, id, batch),
        AttachmentCommand.removeBeverage(id, batch),
      ])
      return undefined
    })

  export const removeCompletely = async (userId: UserId, id: BeverageId) => {
    const outcome = await eraseRecords(userId, id)
    if (outcome === 'not-found') return outcome
    // Only now. A bucket cannot enlist in the batch above, so the files are
    // erased once the records are gone for good: a commit that fails has to
    // leave the beverage exactly as it was, photos included.
    await AttachmentCommand.eraseFiles(userId, id)
    return undefined
  }
}
