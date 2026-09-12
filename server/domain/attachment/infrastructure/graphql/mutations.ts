import { match } from 'ts-pattern'
import {
  acceptedContentTypes,
  MAX_ATTACHMENT_BYTES,
  MAX_ATTACHMENTS_PER_BEVERAGE,
} from '~/domain/attachment/business-rules'
import { AttachmentCommand } from '~/domain/attachment/command'
import type { PendingUpload } from '~/domain/attachment/types'
import { AttachmentUseCase } from '~/domain/attachment/use-case'
import { builder } from '~/domain/shared/graphql/builder'
import { domainError, notFound } from '~/domain/shared/graphql/errors'
import { AttachmentType } from './types'

const PendingUploadType = builder.objectRef<PendingUpload>('PendingUpload').implement({
  description:
    'An upload slot: where to send one file, and until when.\n\n' +
    'Nothing is stored yet. Send the bytes with a `PUT` to `uploadUrl`, carrying exactly the `Content-Type` given here, then call `registerAttachment` with the same `attachmentId`. An upload never registered leaves no attachment and is swept from storage on its own.',
  fields: (t) => ({
    attachmentId: t.expose('attachmentId', {
      type: 'AttachmentId',
      description: 'Identifier to pass back to `registerAttachment` once the bytes are in.',
    }),
    uploadUrl: t.expose('uploadUrl', {
      type: 'SignedUrl',
      description: 'The `PUT` target, signed for this single object.',
    }),
    contentType: t.expose('contentType', {
      type: 'ContentType',
      description:
        'The `Content-Type` header the `PUT` must carry. The signature covers it, so a value that differs at all is rejected.',
    }),
    expiresAt: t.expose('expiresAt', {
      type: 'DateTime',
      description: 'When the upload URL stops being accepted (15 minutes out).',
    }),
  }),
})

builder.mutationField('prepareAttachmentUpload', (t) =>
  t.field({
    type: PendingUploadType,
    description:
      'Reserve an upload slot for a file to attach to a beverage.\n\n' +
      `Accepts ${acceptedContentTypes.join(', ')}, up to ${MAX_ATTACHMENT_BYTES} bytes, ` +
      `and at most ${MAX_ATTACHMENTS_PER_BEVERAGE} files per beverage. Any beverage takes them, not only a wine, and only its owner may attach to it. ` +
      'Fails with `NOT_FOUND` on a beverage that is not yours, `UNSUPPORTED_MEDIA_TYPE`, `FILE_TOO_LARGE` or `TOO_MANY_ATTACHMENTS`.',
    args: {
      beverageId: t.arg({
        type: 'BeverageId',
        required: true,
        description: 'The beverage the file will hang on.',
      }),
      contentType: t.arg({
        type: 'ContentType',
        required: true,
        description: 'Media type of the file about to be sent.',
      }),
      size: t.arg({
        type: 'ByteSize',
        required: true,
        description:
          'Size of the file about to be sent. Checked again against the stored object at registration, so an understated value gains nothing.',
      }),
    },
    resolve: async (_root, { beverageId, contentType, size }, { userId }) => {
      const result = await AttachmentUseCase.reserveSlot(userId, beverageId, contentType, size)
      return match(result)
        .with('beverage-not-found', () => notFound('Beverage not found'))
        .with('unsupported-type', () =>
          domainError(
            'UNSUPPORTED_MEDIA_TYPE',
            `Accepted types: ${acceptedContentTypes.join(', ')}`,
          ),
        )
        .with('too-large', () =>
          domainError('FILE_TOO_LARGE', `A file may not exceed ${MAX_ATTACHMENT_BYTES} bytes`),
        )
        .with('too-many', () =>
          domainError(
            'TOO_MANY_ATTACHMENTS',
            `A beverage holds at most ${MAX_ATTACHMENTS_PER_BEVERAGE} attachments`,
          ),
        )
        .otherwise((pending) => pending)
    },
  }),
)

builder.mutationField('registerAttachment', (t) =>
  t.field({
    type: AttachmentType,
    description:
      'Turn an uploaded file into an attachment on the beverage.\n\n' +
      'Call this after the `PUT` to the upload URL succeeded. The stored object is read back for its real type and size, so the limits hold whatever the client announced earlier. Fails with `UPLOAD_MISSING` when no file was received at that slot.',
    args: {
      beverageId: t.arg({
        type: 'BeverageId',
        required: true,
        description: 'The beverage the slot was reserved on.',
      }),
      attachmentId: t.arg({
        type: 'AttachmentId',
        required: true,
        description: 'The identifier returned by `prepareAttachmentUpload`.',
      }),
      fileName: t.arg({
        type: 'FileName',
        required: true,
        description: 'The name to display next to the file.',
      }),
    },
    resolve: async (_root, { beverageId, attachmentId, fileName }, { userId }) => {
      const result = await AttachmentUseCase.register(userId, beverageId, attachmentId, fileName)
      return match(result)
        .with('beverage-not-found', () => notFound('Beverage not found'))
        .with('upload-missing', () =>
          domainError('UPLOAD_MISSING', 'No file was uploaded to that slot'),
        )
        .with('unsupported-type', () =>
          domainError(
            'UNSUPPORTED_MEDIA_TYPE',
            `Accepted types: ${acceptedContentTypes.join(', ')}`,
          ),
        )
        .with('too-large', () =>
          domainError('FILE_TOO_LARGE', `A file may not exceed ${MAX_ATTACHMENT_BYTES} bytes`),
        )
        .with('too-many', () =>
          domainError(
            'TOO_MANY_ATTACHMENTS',
            `A beverage holds at most ${MAX_ATTACHMENTS_PER_BEVERAGE} attachments`,
          ),
        )
        .otherwise((attachment) => attachment)
    },
  }),
)

builder.mutationField('deleteAttachment', (t) =>
  t.field({
    type: 'Boolean',
    description:
      'Delete an attachment and the file behind it.\n\n' +
      'Only the owner may. Fails with `NOT_FOUND` on an attachment that is not yours.',
    args: {
      attachmentId: t.arg({
        type: 'AttachmentId',
        required: true,
        description: 'The attachment to remove.',
      }),
    },
    resolve: async (_root, { attachmentId }, { userId }) => {
      const result = await AttachmentCommand.remove(userId, attachmentId)
      if (result === 'not-found') return notFound('Attachment not found')
      return true
    },
  }),
)
