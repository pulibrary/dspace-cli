# DSpace Command-Line Interface (CLI)
## Overview

This project serves to provide Classes and procedures implemented in JRuby for
developing a command-line interface for performing operational tasks within a
DSpace installation. However, it should be noted that, for those DSpace
installations which are maintained by the Princeton University Library, there
are additional tiers of functionality which are structured for usage from the
command-line. Hence, the current state of DSpace CLI operations are structured
as such:

1. dspace-cli (JRuby)
1. `tcsh` scripts (These typically wrap either the dspace-cli procedures, custom JRuby procedures, or the DSpace Java CLI)
1. dspace-jruby (Underlying JRuby API)
1. DSpace Java CLI (From DSpace core)

It should please be noted that these were originally developed in order to
extend the functionality and behavior for the DSpace Java CLI. In an attempt to
outline the current functionality for the Java CLI operations, please see the
following tables:

### Bitstream Management
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace cleanup | removed deleted bitstream files from storage | ❌ | ❌ | ❌ |
| dspace filter-media | generate derivatives for bitstreams | ❌ | ❌ | ❌ |
| dspace packager | packaging for items in DSpace | ❌ | ✅ | ✅ |

### Community and Collection Commands

| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace checker | validate the integrity of bitstreams by comparing MD5 checksums | ❌ | ❌ | ❌ |
| dspace community-filiator | managing parent/child relationships between communities | ❌ | ❌ | ❌ |
| dspace create-administrator | create an administrator user for DSpace | ❌ | ✅ | ❌ |
| dspace structure-builder | initialize DSpace community and collection structure | ❌ | ❌ | ❌ |

### Database Commands
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace database | perform database testing and diagnosing tasks | ❌ | ❌ | ❌ |
| dspace setup-database | initialize the database tables for DSpace installations | ❌ | ❌ | ❌ |

### Diagnostic Commands

| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace checker-emailer | sends the results of bitstream checksum validation by e-mail | ❌ | ❌ | ❌ |
| dspace classpath | display the Java classpath used for running DSpace | ❌ | ❌ | ❌ |
| dspace dsprop | view a DSpace property from dspace.cfg | ❌ | ❌ | ❌ |
| dspace dsrun | run a Java class directly | ❌ | ❌ | ❌ |
| dspace read | pipe or stream a series of DSpace commands | ❌ | ❌ | ❌ |
| dspace validate-date | test the date/time formatting rules | ❌ | ❌ | ❌ |
| dspace version | display the version of DSpace installed | ❌ | ❌ | ❌ |


### DOI Commands
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace doi-organiser | synchronize DOI updates with the DOI registration agency | ❌ | ❌ | ❌ |

### Embargo Management
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace embargo-lifter | check, list, and lift item embargoes | ❌ | ❌ | ✅ |
| dspace migrate-embargo | migration for embargo policies from DSpace 3.x releases | ❌ | ❌ | ❌ |

### E-Mail Notification Management
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace checker-emailer | sends the results of bitstream checksum validation by e-mail | ❌ | ❌ | ❌ |
| dspace sub-daily | send daily subscription e-mail messsages | ❌ | ❌ | ❌ |
| dspace test-email | test the e-mail server settings for DSpace | ❌ | ❌ | ❌ |

### Handle Management
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace make-handle-config | generate a configuration for a handle server | ❌ | ❌ | ❌ |
| dspace update-handle-prefix | update handle records when migrating between handle servers | ❌ | ❌ | ❌ |

### Item Curation Commands
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace curate | perform a curation task on a DSpace item | ❌ | ❌ | ❌ |
| dspace checker | validate the integrity of bitstreams by comparing MD5 checksums | ❌ | ❌ | ❌ |

### Item Management
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace export | export items or collections using the DSpace Simple Archive format | ❌ | ❌ | ✅ |
| dspace import | import items or collections using the DSpace Simple Archive format | ❌ | ❌ | ✅ |

### Legacy Statistics Commands
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace stat-general | (legacy) compile the general statistics | ❌ | ❌ | ❌ |
| dspace stat-initial | (legacy) compile the initial statistics | ❌ | ❌ | ❌ |
| dspace stat-monthly | (legacy) compile the monthly statistics | ❌ | ❌ | ❌ |
| dspace stat-report-general | (legacy) generate the generic statistics report | ❌ | ❌ | ❌ |
| dspace stat-report-initial | (legacy) generate the initial statistics report | ❌ | ❌ | ❌ |
| dspace stat-report-monthly | (legacy) generate the monthly statistics report | ❌ | ❌ | ❌ |

### Metadata Management
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace metadata-export | export metadata for a set of items | ✅ | ✅ | ✅ |
| dspace metadata-import | import metadata for a set of items | ✅ | ✅ | ✅ |
| dspace rdfizer | RDF encoding for item metadata in DSpace | ❌ | ❌ | ❌ |
| dspace registry-loader | load data into a metadata registry | ❌ | ❌ | ❌ |

### OAI-PMH Management
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace harvest | manage the OAI-PMH harvesting endpoint | ❌ | ❌ | ❌ |
| dspace oai | management for OAI scripts | ❌ | ❌ | ❌ |

### Sitemap Commands
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace generate-sitemaps | generates sitemaps for communities, collections, items, and bitstreams | ❌ | ❌ | ❌ |

### Solr Commands
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace index-authority | import of subject heading authorities into Solr | ❌ | ❌ | ❌ |
| dspace index-db-browse | management of Solr for indexing and search features | ❌ | ❌ | ❌ |
| dspace index-discovery | synchronized the Solr index with the DSpace database | ❌ | ❌ | ❌ |
| dspace index-lucene-init | initialize the search and browse indexes in Solr | ❌ | ❌ | ❌ |
| dspace index-lucene-update | update the search and browse indexes | ❌ | ❌ | ❌ |
| dspace itemcounter | update the item counts for display in the user interface | ❌ | ❌ | ❌ |
| dspace itemupdate | update metadata or bitstream content in items | ❌ | ✅ | ❌ |

### Statistics Commands
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace stats-log-converter | convert dspace.log files ready for import into the Solr statistics index (does not actually import the data) | ❌ | ❌ | ❌ |
| dspace stats-log-importer | import converted log files into the Solr statistics index | ❌ | ❌ | ❌ |
| dspace stats-log-importer-elasticsearch | import converted log files into an Elastic Search index | ❌ | ❌ | ❌ |
| dspace stats-util | manages the Solr statistics core | ❌ | ❌ | ❌ |
| dspace solr-export-statistics | exports data from the Solr statistics core | ❌ | ❌ | ❌ |
| dspace solr-import-statistics | imports data into the Solr statistics core | ❌ | ❌ | ❌ |
| dspace solr-reindex-statistics | reindexes the Solr statistics core (this usually follows a change to the Solr schema) | ❌ | ❌ | ❌ |

### User Management Commands
| Command | Description | dspace-cli (JRuby) feature | dspace-jruby feature | tcsh script operations |
| --- | --- | --- | --- | --- |
| dspace create-administrator | create an administrator user for DSpace | ❌ | ✅ | ❌ |
| dspace user | DSpace user management | ❌ | ✅ | ✅ |
