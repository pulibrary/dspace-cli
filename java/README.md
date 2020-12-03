# DSpace Command-Line Interface (CLI)
## Java Extensions
Extensions for the DSpace CLI implemented in Java.

### Compilation
```bash
ant compile
```

### Usage
```bash
export DSPACE_HOME=/dspace
export DSPACE_LIB=`ls $DSPACE_HOME/lib/*.jar | sed -z 's/\n/\:/g'`
export DSPACE_CLI_LIB=`ls $HOME/pulibrary-src/dspace-cli/java/lib/*.jar | sed -z 's/\n/\:/g'`
export MARC_INPUT_PATH=./proquest.mrc
export MARC_OUTPUT_PATH=./proquest_processed.mrc
java -classpath "build:$DSPACE_CLI_LIB:$DSPACE_LIB:$DSPACE_HOME/config" edu.princeton.dspace.etds.ETDMARCProcessor \
  --config ./config/etds/config.xml \
  --dspace_home $DSPACE_HOME \
  -i $MARC_INPUT_PATH \
  -o $MARC_OUTPUT_PATH \
  --verbose
```

