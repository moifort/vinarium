import { AttachmentQuery } from '~/domain/attachment/query'
import type { Attachment } from '~/domain/attachment/types'
import { BeverageType } from '~/domain/beverage/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'

const AttachmentKindEnum = builder.enumType('AttachmentKind', {
  description: 'How the app is meant to present an attached file.',
  values: {
    image: { description: 'A photo, shown inline in the gallery.' },
    document: { description: 'A PDF, opened in a document viewer.' },
  },
})

export const AttachmentType = builder.objectRef<Attachment>('Attachment').implement({
  description:
    'A file kept alongside a bottle: a label photo, a shot of the cellar it came from, the purchase invoice.\n\n' +
    'A wine holds at most five, each up to 10 MB. Only the owner of the wine may add or delete one; anyone who can see the wine can read them, which includes a household member looking at a bottle standing in the shared cellar. Exposed as `Beverage.attachments`.',
  fields: (t) => ({
    id: t.expose('id', { type: 'AttachmentId', description: 'Unique identifier of the file.' }),
    kind: t.expose('kind', {
      type: AttachmentKindEnum,
      description: 'Whether to show the file inline or open it in a viewer.',
    }),
    contentType: t.expose('contentType', {
      type: 'ContentType',
      description: 'The media type the file was stored with.',
    }),
    fileName: t.expose('fileName', {
      type: 'FileName',
      description: 'The name to display next to the file.',
    }),
    size: t.expose('size', {
      type: 'ByteSize',
      description: 'Size in bytes, as measured on the stored object rather than announced.',
    }),
    createdAt: t.expose('createdAt', {
      type: 'DateTime',
      description: 'When the file was attached.',
    }),
    url: t.field({
      type: 'SignedUrl',
      description:
        'A one-hour download URL, signed for this file only.\n\n' +
        'Signed on demand: a caller that does not select this field triggers no signature at all. Do not store it, it expires.',
      resolve: (attachment) => AttachmentQuery.downloadUrl(attachment),
    }),
  }),
})

builder.objectField(BeverageType, 'attachments', (t) =>
  t.field({
    type: [AttachmentType],
    description:
      'The files attached to the wine, oldest first.\n\n' +
      'Empty when nothing was ever attached. Resolved through a per-request loader (no N+1), so a page of wines costs one keyed read rather than one per row.',
    resolve: async (wine, _, { loaders }) => (await loaders.attachments.load(wine.id)) ?? [],
  }),
)
