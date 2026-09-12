import { AttachmentCommand } from '~/domain/attachment/command'
import type { AttachmentId, ByteSize, ContentType, FileName } from '~/domain/attachment/types'
import { BeverageQuery } from '~/domain/beverage/query'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'

// Attaching is an owner's act. Reading follows the bottle (a housemate sees the
// files of a bottle standing in the shared cellar), but writing to someone else's
// wine is refused here, once, for both halves of the upload — which is why the
// beverage check lives in a use case rather than in the command.
export namespace AttachmentUseCase {
  export const reserveSlot = async (
    userId: UserId,
    beverageId: BeverageId,
    contentType: ContentType,
    size: ByteSize,
  ) => {
    if ((await BeverageQuery.byId(userId, beverageId)) === 'not-found')
      return 'beverage-not-found' as const
    return await AttachmentCommand.reserveSlot(userId, beverageId, contentType, size)
  }

  export const register = async (
    userId: UserId,
    beverageId: BeverageId,
    attachmentId: AttachmentId,
    fileName: FileName,
  ) => {
    if ((await BeverageQuery.byId(userId, beverageId)) === 'not-found')
      return 'beverage-not-found' as const
    return await AttachmentCommand.register(userId, beverageId, attachmentId, fileName)
  }
}
