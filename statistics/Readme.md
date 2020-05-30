
`statistics/community.rb` compiles statistics information on number of accesses recorded in solr - stats.

It produces tab separated tables 
1. showing the total number of collection, item, bitstream views/downloads per community. 
2. and/or a listing of the top performing bitstreams in the given communities
    
Numbers can be filtered by time slots. 

You can give a list of ip that should be excluded.

You can request to exclude entries marked with isBot=1.

See the included statistics/community.yml for an example parameter file.

You can print the usage with `statistics/community.rb  --help` for the following output.

```
    -c, --collection_counts file     cumulative counts for collections
    -b, --bitstreams file            most downloaded bitstreams
    -y, --yml options                yml options file
    -v, --[no-]verbose               Run verbosely
    -h, --help                       Prints this help
```

# Sample top bitstream report 
```
# report-date: 2015-08-04 17:52:43 -0400
# solr-core: http://localhost:18082/solr/statistics
# hostname: monika.Princeton.EDU
#
# Top Bitstreams downloads for 2015
#
TOP	COMMUNITY	N-DOWNLOADS	BITSTREAM	ITEM-id	ITEM-handle	ITEM-name	COLLECTION-id	COLLECTION-handle	...
0	Princeton University Doctoral Dissertations	24873	BITSTREAM.12584	ITEM.6809	88435/dsp01gx41mh987	Modifications of impurity transport and divertor sources by lithium wall conditioning in the National Spherical Torus Experiment	COLLECTION.85	88435/dsp015m60qr913	COMMUNITY.67	88435/dsp01td96k251d	COMMUNITY.66	88435/dsp01z316q160r
1	Princeton University Doctoral Dissertations	24419	BITSTREAM.15637	ITEM.8281	88435/dsp01wd375w44n	First Principles Studies of Small Molecular Adsorbates on The Anatase TiO2 (101) Surface	COLLECTION.88	88435/dsp01sf2685121	COMMUNITY.67	88435/dsp01td96k251d	COMMUNITY.66	88435/dsp01z316q160r
2	Princeton University Doctoral Dissertations	18148	BITSTREAM.15770	ITEM.8413	88435/dsp01js956f96n	Exploring fluid mechanics in energy processes: viscous flows, interfacial instabilities & elastohydrodynamics	COLLECTION.87	88435/dsp01x633f104k	COMMUNITY.67	88435/dsp01td96k251d	COMMUNITY.66	88435/dsp01z316q160r
```
# Sample community report 
```
# report-date: 2015-08-04 18:00:40 -0400
# solr-core: http://localhost:18082/solr/statistics
# hostname: monika.Princeton.EDU
#
# @time_slots:
#   2014    2014-01-01T00:00:00.000Z TO 2015-01-01T00:00:00.000Z
#   2015    2014-01-01T00:00:00.000Z TO NOW
# 
# type=bitstream:    bitstream access count  in COMMUNITY.NAME
# type=item:     item page access count  in COMMUNITY.NAME
# type=collection:   collection page access count  in COMMUNITY.NAME
# type=all:  access to bitstream, items and collection pages   in COMMUNITY.NAME
# 
COMMUNITY.NAME  COLLECTION.ID   COLLECTION.HANDLE   type    2014    2015    COLLECTION.NAME
Princeton University Doctoral Dissertations COLLECTION.ALL      bitstream   264901  478945  ALL-COLLECTIONS
Princeton University Doctoral Dissertations COLLECTION.96   88435/dsp01rf55z771t    bitstream   34471   53354   Electrical Engineering
Princeton University Doctoral Dissertations COLLECTION.112  88435/dsp01pg15bd903    bitstream   31987   46277   Plasma Physics
... dot dot dot

Princeton University Doctoral Dissertations COLLECTION.ALL      item    58527   115326  ALL-COLLECTIONS
Princeton University Doctoral Dissertations COLLECTION.89   88435/dsp01np193919r    item    4107    5670    Civil and Environmental Engineering
Princeton University Doctoral Dissertations COLLECTION.96   88435/dsp01rf55z771t    item    2893    6336    Electrical Engineering
... dot dot dot

Princeton University Doctoral Dissertations COLLECTION.ALL      collection  5800    10443   ALL-COLLECTIONS

Princeton University Doctoral Dissertations COLLECTION.ALL      all 329228  604714  ALL-COLLECTIONS
Princeton University Doctoral Dissertations COLLECTION.96   88435/dsp01rf55z771t    all 37364   59690   Electrical Engineering
Princeton University Doctoral Dissertations COLLECTION.112  88435/dsp01pg15bd903    all 33539   49278   Plasma Physics
... dot dot dot

COMMUNITY.NAME  COLLECTION.ID   COLLECTION.HANDLE   type    2014    2015    COLLECTION.NAME
Princeton University Senior Theses  COLLECTION.ALL      bitstream   1576    7304    ALL-COLLECTIONS
Princeton University Senior Theses  COLLECTION.377  88435/dsp013n203z151    bitstream   202 770 Economics, 1927-2015
Princeton University Senior Theses  COLLECTION.407  88435/dsp0179407x233    bitstream   134 478 Woodrow Wilson School, 1929-2015
... dot dot dot

Princeton University Senior Theses  COLLECTION.ALL      item    210130  581245  ALL-COLLECTIONS
Princeton University Senior Theses  COLLECTION.377  88435/dsp013n203z151    item    20829   58230   Economics, 1927-2015
Princeton University Senior Theses  COLLECTION.384  88435/dsp016d56zw67q    item    20719   63023   History, 1926-2015
... dot dot dot

Princeton University Senior Theses  COLLECTION.ALL      collection  8921    17095   ALL-COLLECTIONS

Princeton University Senior Theses  COLLECTION.ALL      all 220627  605644  ALL-COLLECTIONS
Princeton University Senior Theses  COLLECTION.377  88435/dsp013n203z151    all 21031   59000   Economics, 1927-2015
Princeton University Senior Theses  COLLECTION.384  88435/dsp016d56zw67q    all 20832   63738   History, 1926-2015
... dot dot dot
```
