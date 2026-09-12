import { objectStore } from '~/domain/attachment/infrastructure/object-store'
import * as repository from '~/domain/attachment/infrastructure/repository'
import type { Attachment } from '~/domain/attachment/types'
import type { BeverageId } from '~/domain/beverage/types'

export namespace AttachmentQuery {
  export const ofBeverage = async (beverageId: BeverageId) =>
    sortedByAge(await repository.findByBeverage(beverageId))

  /** Batch-load for the per-request loader behind `Beverage.attachments`. */
  export const byBeverageIds = async (beverageIds: BeverageId[]) =>
    sortedByAge(await repository.findManyByBeverageIds(beverageIds))

  /** The short-lived URL the client downloads the file from. Signed on demand,
   *  one object at a time: a caller that does not select the URL pays for no
   *  signature at all, and a signature never outlives the screen that asked for it. */
  export const downloadUrl = async (attachment: Attachment) =>
    await objectStore().downloadUrl(attachment.objectPath)

  // Oldest first: the gallery reads as the order the user attached things in.
  const sortedByAge = (attachments: Attachment[]) =>
    [...attachments].sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime())
}
