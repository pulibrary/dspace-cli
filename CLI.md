# DSpace Command-Line Interface

## DataSpace Administration

### Senior Theses Community

#### Importing Departments

```bash
bundle exec thor dspace:dataspace:import_thesis_department -d 'Creative Writing' -y 2020
```

Then, while on the server:

```bash
export COLLECTION="88435/dsp01gx41mh91n"
export EPERSON="jrg5@princeton.edu"
export MAPFILE=`date +%s.map`
export SOURCE=/tmp/creative_writing

/dspace/bin/dspace import \
  --add \
  --collection $COLLECTION \
  --eperson $EPERSON \
  --mapfile $MAPFILE \
  --source $SOURCE \
  --workflow
```

#### PDF Management

Generating a PDF with a cover sheet:

```bash
export SUBMISSION_PDF=imports/senior_theses/creative_writing/submission_8081/ALAGAPPAN-SERENA-THESIS.pdf
export PDF_SOURCE=imports/senior_theses/creative_writing/submission_8081/ORIG-ALAGAPPAN-SERENA-THESIS.pdf
cp $SUBMISSION_PDF $PDF_SOURCE
export PDF_COVER_PAGE=imports/senior_theses/cover_page_template.pdf
bundle exec thor dspace:dataspace:generate_cover_page -p $PDF_SOURCE -c $PDF_COVER_PAGE -o $SUBMISSION_PDF
```

#### Metadata Management

```bash
bundle exec thor dspace:dataspace:insert_metadata -s 8081 -d 'creative_writing' -S pu -e date -q classyear -v 2020
bundle exec thor dspace:dataspace:insert_metadata -s 8081 -d 'creative_writing' -S pu -e contributor -q authorid -v 961235565
bundle exec thor dspace:dataspace:insert_metadata -s 8081 -d 'creative_writing' -S pu -e pdf -q coverpage -v SeniorThesisCoverPage
bundle exec thor dspace:dataspace:insert_metadata -s 8081 -d 'creative_writing' -S pu -e department -v Mathematics
bundle exec thor dspace:dataspace:insert_metadata -s 8081 -d 'creative_writing' -S pu -e certificate -v 'Finance Program'
```

For adding an embargo date:

```bash
bundle exec thor dspace:dataspace:insert_metadata -s 8081 -d 'creative_writing' -S pu -e embargo -q terms -v '2021-07-01'
```

For adding Mudd Library restrictions:

```bash
bundle exec thor dspace:dataspace:insert_metadata -s 8081 -d 'creative_writing' -S pu -e mudd -q walkin -v 'yes'
bundle exec thor dspace:dataspace:insert_metadata -s 8081 -d 'creative_writing' -S dc -e rights -q accessRights -v 'Walk-in Access. This thesis can only be viewed on computer terminals at the <a href=http://mudd.princeton.edu>Mudd Manuscript Library</a>.'
```
