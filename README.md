# Create Walters Repository CSV

Recreate the OPenn repository CSV format for repository 0020 folders
WaltersManuscripts and OtherColllections.  The following is a sample of an
OPenn repository CSV.

From `0007_contents.csv`:

    document_id,path,title,metadata_type,created,updated
    665,0007/SCMS0142,"Copy of Engineers Private Journal on Harlem Bridge, 1860-1861",TEI,2015-08-12T19:57:01+00:00,2015-10-07T00:31:20+00:00
    670,0007/SCMS0281_v01,Estelle Johnston Diaries,TEI,2015-08-13T14:04:52+00:00,2015-10-07T00:31:20+00:00
    671,0007/SCMS0281_v02,Estelle Johnston Diaries,TEI,2015-08-13T14:35:51+00:00,2015-10-07T00:31:20+00:00
    672,0007/SCMS0014_v01,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T15:21:20+00:00,2015-10-07T00:31:19+00:00
    673,0007/SCMS0014_v02,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T16:11:36+00:00,2015-10-07T00:31:19+00:00
    674,0007/SCMS0014_v03,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T17:22:34+00:00,2015-10-07T00:31:19+00:00
    677,0007/SCMS0014_v04,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T18:53:56+00:00,2015-10-07T00:31:20+00:00
    679,0007/SCMS0014_v05,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T19:38:47+00:00,2015-10-07T00:31:20+00:00
    680,0007/SCMS0014_v06,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T20:06:44+00:00,2015-10-07T00:31:20+00:00

COLUMNS

  `document_id`   -- not available, leave as ''

  `path`          -- `0020/Data/{WaltersManuscripts,OtherColllections}`

  `title`         -- extract from metadata.xml `<dc:title>` (e.g., `OtherCollections/PC1/data/metadata.xml`)

  `metadata_type` -- always 'Walters TEI'

  `created`       -- directory mtime

  `updated`       -- directory mtime

