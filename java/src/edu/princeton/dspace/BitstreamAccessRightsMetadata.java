package edu.princeton.dspace;

/*
 * intended to turn this into a proper curation task
 * for now just run from main program
 */

import org.apache.commons.cli.*;
import org.apache.log4j.Logger;
import org.dspace.authorize.AuthorizeException;
import org.dspace.authorize.AuthorizeManager;
import org.dspace.authorize.ResourcePolicy;
import org.dspace.content.*;
import org.dspace.core.ConfigurationManager;
import org.dspace.core.Constants;
import org.dspace.core.Context;
import org.dspace.eperson.EPerson;
import org.dspace.eperson.Group;
import org.dspace.storage.rdbms.TableRow;
import org.dspace.storage.rdbms.TableRowIterator;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

public class BitstreamAccessRightsMetadata {
    private static Logger log = Logger.getLogger(BitstreamAccessRightsMetadata.class);

    private ItemsLister itemLister = new ItemsLister();

    private Metadatum rightsDC;
    private MetadataField rightsField;
    private String rightsValue;
    private Group accessGroup;
    private  Boolean verbose = false;

    private Context context = null;

    private static final String bundleName = "ORIGINAL";

    public BitstreamAccessRightsMetadata() {
    }

    public void setContext(Context context) {
        this.context = context;
        itemLister.context = context;
    }

    public void perform(DSpaceObject dso) throws SQLException, AuthorizeException, IOException {
            if (dso != null) {
                TableRowIterator tri = itemLister.itemIterator(dso);
                while (tri.hasNext()) {
                    TableRow row = tri.next();
                    int id = row.getIntColumn("item_id");
                    Item item = Item.find(context, id);
                    if (item == null)
                        throw new RuntimeException("No item with id " + id + ", although there is an entry in the MetadataValue table");
                    else {
                        applyTo(item);
                    }
                }
                tri.close();
            }
    }

    private void applyTo(Item item) throws IOException, SQLException, AuthorizeException {
        if (verbose) {
            log.info("applyTo: " + item + " " + item.getHandle());
        }
        Bundle[] bundles = item.getBundles(bundleName);
        for (Bundle b : bundles) {
            Bitstream bits[] = b.getBitstreams();
            for (Bitstream bit : bits) {
                if (hasAccessRestriction(bit)) {
                    String[] values = { rightsValue };
                    Metadatum[] vals = item.getMetadata(rightsDC.schema, rightsField.getElement(), rightsField.getQualifier(), Item.ANY);
                    if (vals == null || vals.length == 0){
                        item.addMetadata(rightsDC.schema,
                                rightsField.getElement(), rightsField.getQualifier(), Item.ANY, values);
                        item.update();
                        log.info("SETTING-" + rightsDC + ": " + Utils.describe(item));
                    } else {
                        log.info("HAS-VALUE: " + Utils.describe(bit));
                    }
                    break;
                } else {
                    if (verbose) {
                        log.info("NOT: " + accessGroup + " " + Utils.describe(bit));
                    }
                }
            }
        }
    }

    private boolean hasAccessRestriction(Bitstream bit) throws SQLException {
        List<ResourcePolicy> list = AuthorizeManager.getPoliciesActionFilter(context, bit,
                Constants.READ);
        for (ResourcePolicy p : list) {
            if (p.getGroup() == accessGroup)
                return true;
        }
        return false;
    }

    public static void usage(Options options) {
        HelpFormatter myhelp = new HelpFormatter();
        myhelp.printHelp("MuddAccessRoghtsMetadata: ", options);
        System.out.println("");
        System.out.println(
                "Look for bitstreams with given READ access policy and set dc.rights.field\n" +
                        "With -f and -w option:\n" +
                        "        look only on bitstream in items where the metadata field is LIKE the given metadata value\n" +
                        "With -f only\n" +
                        "        look only on bitstream in items with any value for the given metadata field\n" +
                        "With -w only\n" +
                        "        look only on bitstream in items where at least one metadata value is LIKE the given value\n" +
                        "\n");
    }

    public static void main(String args[]) {
        /* ConsoleAppender ca = new ConsoleAppender();
        ca.setWriter(new OutputStreamWriter(System.out));
        ca.setLayout(new PatternLayout("# %m%n"));
        log.addAppender(ca);
        */
        CommandLineParser cliParser = new PosixParser();

        Options options = new Options();

        final String DSPACE_CONFIG_FILE = "/dspace/config/dspace.cfg";
        final String DEFAULT_RIGHTS_FIELD = "dc.rights.accessRights";

        options.addOption("c", "config", true, "config file - default " + DSPACE_CONFIG_FILE);
        options.addOption("a", "accessfield", true, "metadata field to be set if bitstream READ access is given group- default " + DEFAULT_RIGHTS_FIELD);
        options.addOption("A", "accessvalue", true, "file containing access field value ");
        options.addOption("g", "group", true, "access group to look for, eg SrTheses_Bitstream_Read_Mudd");
        options.addOption("e", "eperson", true, "authorize as given eperson/netid");
        options.addOption("f", "metadatafield", true, "fully qualified metadata field, eg pu.date.classyear");
        options.addOption("w", "wert", true, "metadata field value, eg 2014");
        options.addOption("r", "root", true, "handle or <TYPE>.ID   eg COMMUNITY.267");
        options.addOption("s", "submit", false, "default: do not commit changes");
        options.addOption("v", "verbose", false, "default: false");
        options.addOption("h", "help", false, "print help");

        String dspaceConfig = DSPACE_CONFIG_FILE;
        boolean submit = false;

        BitstreamAccessRightsMetadata normalizer = new BitstreamAccessRightsMetadata();
        normalizer.rightsField = null;
        normalizer.verbose = false;

        // Extract the values of the options passed from the commandline
        try {
            CommandLine line = cliParser.parse(options, args);
            line = cliParser.parse(options, args);

            if (line.hasOption('h')) {
                usage(options);
                System.exit(0);
            }
            normalizer.verbose = line.hasOption('v');

            if (line.hasOption('c')) {
                dspaceConfig = line.getOptionValue('c');
            }
            ConfigurationManager.loadConfig(dspaceConfig);
            Context context = new Context();
            normalizer.setContext(context);

            submit = line.hasOption('s');
            if (!line.hasOption('e')) {
                throw new ParseException("must given eperson parameter");
            } else {
                EPerson ePerson = EPerson.findByNetid(context, line.getOptionValue('e'));
                if (ePerson == null) {
                    throw new ParseException("no such eperon: " + line.getOptionValue('e'));
                }
                context.setCurrentUser(ePerson);
            }

            if (line.hasOption('a')) {
                String val = line.getOptionValue('a');
                normalizer.rightsDC = Utils.toMetadatum(val);
                normalizer.rightsField =  Utils.getMetadataField(context, normalizer.rightsDC);
                if (normalizer.rightsField == null) {
                    throw new ParseException("no such metadata field " + val);
                }
            }

            try {
                normalizer.rightsValue = Utils.readFile(line.getOptionValue('A'));
            } catch (IOException io) {
                new ParseException((io.getMessage()));
            }
            if (normalizer.rightsValue == null || normalizer.rightsValue.isEmpty())
                throw new ParseException("rights value is empty ");
            System.out.println("Value : '" + normalizer.rightsValue + "'");

            if (line.hasOption('g')) {
                normalizer.accessGroup = Group.findByName(context, line.getOptionValue('g'));
                if (normalizer.accessGroup == null)
                    throw new RuntimeException(line.getOptionValue('g') + "is not a value access group");
            } else {
                throw new ParseException("must give a access group paramater");
            }
            if (normalizer.verbose)
                log.info("group -> " + normalizer.accessGroup.getID());

            try {
                normalizer.itemLister.restrictToItemsWith(line.getOptionValue('f'), line.getOptionValue('w'));
            } catch (RuntimeException e) {
                throw new ParseException(e.getMessage());
            }
            DSpaceObject root = DSpaceObject.fromString(context, line.getOptionValue('r'));
            if (root == null) {
                throw new ParseException("must give a valid root parameter");
            }

            System.out.println("root = " + root);

            if (! submit) {
                System.out.println("***** Will NOT commit changes - dryrun only");
            }
            normalizer.perform(root);
            if (submit) {
                System.out.println("***** " + root + " " + root.getHandle() + " committing changes");
                context.commit();
            } else {
                System.out.println("***** " + root + " " + root.getHandle() + " NOT committing changes");
                context.abort();
            }
        } catch (ParseException e) {
            System.out.println();
            System.out.println(e.toString() + "\n");
            usage(options);
            e.printStackTrace();
            System.exit(1);
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

}
