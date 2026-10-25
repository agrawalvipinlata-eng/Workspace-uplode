# Library Legal & Copyright Compliance File

**Product:** Never Miss Bus — Library module  
**Prepared by:** Manus AI  
**Register date:** 2026-10-25  
**Current catalogue snapshot:** 120 demo metadata entries  

> **Important legal status.** This document is a rights-management policy and a review register. It is not a lawyer’s opinion, government certificate, or proof that every item is legally distributable in every country. The current catalogue is marked **candidate / pending verification**, not “legally certified.” A responsible person or qualified copyright lawyer must approve each title, edition, translation, cover, and audio recording before republication or commercial distribution.

## 1. Purpose and scope

The Library may display bibliographic metadata and may provide reading or listening access only when the underlying text, edition, cover image, recording, and hosting method have a documented right to be used. Metadata alone does not grant a right to reproduce or distribute the underlying work.

This file covers the 120 static demo entries currently present in `lib/services/library_service.dart`, the Firestore `libraryBooks` records, and any future PDF, audio, cover, or R2 object connected to those records. The machine-readable per-book register is in [`library_rights_manifest.csv`](library_rights_manifest.csv).

## 2. What “approved” means

A book may be marked `approved` only when one of the following is documented:

- The exact text/edition is public domain in every intended distribution country, including India if the app is operated or used there.
- The rightsholder has granted written permission covering hosting, in-app display, downloading/streaming, translation, cover art, and audio use as applicable.
- The exact asset has a compatible open licence, such as a Creative Commons licence, and the required attribution and share-alike conditions are recorded.

An author’s death date or an old title is not enough by itself. A translation, annotation, typesetting, cover, scan, narration, soundtrack, and modern adaptation can have separate rights.

## 3. India and jurisdiction review

India’s Copyright Act states that, subject to exceptions, copyright in a published literary work lasts until 60 years from the beginning of the calendar year following the author’s death. Joint authorship, anonymous or pseudonymous works, government works, posthumous works, translations, adaptations, and other categories can change the analysis. See the official Act at [1].

Project Gutenberg expressly warns that an item may be public domain in the United States but restricted in another country, and tells non-US users to check local law. Its permission guidance also says that its public-domain determinations are US-based. See [2] and [3].

Accordingly, the current demo items must not be described in the app or marketing as “all legal in India” until the country review is completed. The safe app label is `Public-domain candidate — verify local rights`.

## 4. Text and PDF policy

For a text resource, the register must record the exact source landing page, edition or release identifier, publication details where available, jurisdiction checked, and the URL or R2 object actually served to users. Project Gutenberg asks applications to link to the book landing page rather than deep-linking to its internal files. It also asks high-volume catalogue users to use its offline catalogue/mirrors rather than repeatedly scraping the main site. See [2] and [3].

The current 120 demo entries use Project Gutenberg landing/search links as source references. They are not a completed legal clearance, and they are not a licence to copy or bulk-mirror Project Gutenberg files.

## 5. Audio policy

An audio recording is a separate asset. It must have its own recording source, licence/public-domain statement, performer/producer details where available, and permitted use in the intended country. LibriVox says its recordings are released to the public domain, but also warns that its public-domain analysis is based on US law and that users outside the US should check the status of the underlying work in their own country. See [4].

In the current app build, only a direct audio file URL such as `.mp3`, `.m4a`, `.aac`, `.ogg`, or `.wav` activates the in-app audio player. The current catalogue has no verified direct audio file stored in R2; non-direct LibriVox search links are intentionally not treated as playable audio. Those entries are therefore read-only until a specific recording is cleared and a direct licensed/public-domain file URL is added.

## 6. Cover-art policy

Book cover images are not automatically public domain merely because the underlying novel is old. Each cover must be an original school-created asset, a public-domain scan, a compatible open-licence image, or a separately licensed image. The current app uses a generated generic 3D library-book asset as a UI visual and does not claim it is the historical cover of any book. Any real cover added later must have its own record in the manifest.

## 7. R2 and Firestore operating rules

Cloudflare R2 may store only assets whose rights record has status `approved`. Firestore should store metadata and the rights fields below; it should not be treated as proof of ownership:

```text
rightsStatus
rightsJurisdiction
licenseType
licenseUrl
sourceUrl
sourceEdition
textClearanceBy
textClearanceDate
audioStatus
audioLicenseUrl
coverStatus
coverLicenseUrl
takedownContact
reviewExpiresAt
```

Each R2 object should use a stable path such as `library/<book-id>/book.pdf`, `library/<book-id>/audio.mp3`, and `library/<book-id>/cover.png`. The app may stream an approved direct file URL in-app, but it must not infer a licence from the file extension or from a website search result.

## 8. Required review workflow

1. Identify the exact text, edition, translation, cover, and recording.
2. Check the intended country, especially India, and record the legal basis.
3. Verify the source or licence page and save a snapshot or stable record where permitted.
4. Record attribution, restrictions, and the reviewer/date in the manifest.
5. Upload only cleared assets to R2 and create the Firestore record with `rightsStatus: approved`.
6. Test in-app reading and audio playback without relying on a third-party search page.
7. Review complaints and expiring permissions, and remove or disable an item when clearance is uncertain.

## 9. Takedown and complaints

Provide a visible copyright contact address in the app and project documentation. A complaint should identify the work, claimant, rights basis, URL/object path, and contact details. On receipt, disable the affected Firestore record and R2 object while the claim is investigated. Preserve the record, source URL, and correspondence; do not restore the item until the claim is resolved or written permission is received.

## 10. Current catalogue status

- Catalogue entries: **120**.
- Entries with a recorded source/licence field: **120**.
- Entries with no audio configured: **20**.
- Entries with a non-empty LibriVox catalogue/search reference but no verified direct playable audio file: **100**.
- Entries fully cleared for distribution in India: **0 recorded in this register**.
- Entries approved for R2 mirroring: **0 until per-item review is completed**.

The current safe presentation is therefore: **readable source-candidate catalogue, pending local rights review; no cleared audio claim**. This wording should remain until the per-item register is completed.

## 11. Sign-off block

```text
School / operator: ______________________________
Responsible rights reviewer: _____________________
Jurisdiction(s): _________________________________
Review date: ____________________________________
Contact for copyright notices: ____________________
Signature: ______________________________________
```

## References

[1]: https://copyright.gov.in/documents/copyrightrules1957.pdf "The Copyright Act, 1957 — official Copyright Office PDF"
[2]: https://www.gutenberg.org/policy/terms_of_use.html "Project Gutenberg Terms of Use"
[3]: https://www.gutenberg.org/policy/permission.html "Project Gutenberg Permissions, Licensing and Common Requests"
[4]: https://librivox.org/pages/public-domain/ "LibriVox Public Domain policy"
