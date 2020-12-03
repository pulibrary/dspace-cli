package edu.princeton.dspace;

/*
 * intended to turn this into a proper curation task
 * for now just run from main program
 */

import org.apache.commons.cli.*;
import org.apache.log4j.Logger;
import org.dspace.authorize.AuthorizeException;
import org.dspace.content.*;
import org.dspace.core.ConfigurationManager;
import org.dspace.core.Context;
import org.dspace.eperson.EPerson;
import org.dspace.servicemanager.DSpaceKernelImpl;
import org.dspace.servicemanager.DSpaceKernelInit;
import org.dspace.storage.rdbms.TableRow;
import org.dspace.storage.rdbms.TableRowIterator;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Set;
import java.util.TreeSet;

public class NormalizeBitstreamNames {
    private static Logger log = Logger.getLogger(NormalizeBitstreamNames.class);

    private static String theses_prefix = "PUTheses";   // TODO: should be properties and CLI parameter
    private static String extensionOnly = ".pdf";       // TODO: should be properties and CLI parameter

    private static final int UNCHANGED_NAME = 0;
    private static final int CHANGED_NAME = 1;
    private static final int UGLY_CHANGED_NAME = 2;
    private static final int REVERT_NAME_CHANGE = 3;
    private int[] change_results = {0, 0, 0, 0};

    static final int SIMPLE_MODE = 0;
    static final int THESES_MODE = 1;
    private int mode = SIMPLE_MODE;

    private ItemsLister itemLister = new ItemsLister();

    private String bundleName = "ORIGINAL";

    private  Boolean verbose = false;

    private Context context = null;

    public NormalizeBitstreamNames() {
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
                    int id = row.getIntColumn("resource_id");
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
        Set<String> reservedNames = new TreeSet<String>();
        for (Bundle b : bundles) {
            Bitstream bits[] = b.getBitstreams();
            for (Bitstream bit : bits) {
                reservedNames.add(bit.getName());
            }
        }
        for (Bundle b : bundles) {
            Bitstream bits[] = b.getBitstreams();
            for (Bitstream bit : bits) {
                String old = bit.getName();
                if (changeBitName(bit) && reservedNames.contains(bit.getName())) {
                    log.info("REVERT.NameChange: " + Utils.describe(bit) + "old-name: " + old);
                    bit.setName(old);
                    bit.update();
                    change_results[REVERT_NAME_CHANGE]++;
                } else
                    reservedNames.add(bit.getName());
            }
        }
    }

    private boolean changeBitName(Bitstream bit) throws SQLException, AuthorizeException {
        String old_name = bit.getName();
        boolean doSimple = ! matchingFileExtension(getFileExtension(old_name));

        String new_name;
        if (doSimple || SIMPLE_MODE == mode) {
            new_name = simple_new_name(old_name);
        } else {
            new_name = theses_new_name(bit, theses_prefix);
        }
        if (! new_name.equals(old_name)) {
            if (new_name.startsWith(".")) {
                log.info("applyTo.NameChangeFail: " + Utils.describe(bit) + " new-name=" + new_name);
                change_results[UGLY_CHANGED_NAME]++;
            } else {
                log.info("applyTo.NameChange: " + Utils.describe(bit) + " new-name=" + new_name);
                bit.setName(new_name);
                bit.update();
                change_results[CHANGED_NAME]++;
                return true;
            }
        } else {
            if (verbose) {
                log.info("applyTo.NameConforms: " + Utils.describe(bit));
            }
            change_results[UNCHANGED_NAME]++;
        }
        return false;
    }

    private static String simple_new_name(String name) {
        name  = name.replaceAll(" ", "_");
        name  = name.replaceAll("[^a-zA-Z0-9-+=/.:_]", "");
        return name;
    }

    private static String theses_new_name(Bitstream bit, String prefix) throws SQLException {
        String name = bit.getName();
        String ext = getFileExtension(name);
        Item item = (Item) bit.getParentObject();
        Metadatum[] value = item.getMetadata("pu", "date", "classyear", Item.ANY);
        String year = "";
        if (value.length > 0)
            year = value[0].value;
        String authors = "";
        value = item.getMetadata("dc", "contributor", "author", Item.ANY);
        for (int i = 0; i < value.length; i++)
            authors = authors + "-" + value[i].value;
        authors = authors.substring(1);
        name = prefix + year + "-" + authors + ext;
        return simple_new_name(name);
    }

    private static String getFileExtension(String name) {
        return name.substring(name.lastIndexOf('.'));
    }

    private static  boolean matchingFileExtension(String ext)
    {
        return ext.toLowerCase().equals(extensionOnly);
    }

    public static void usage(Options options) {
        HelpFormatter myhelp = new HelpFormatter();
        myhelp.printHelp("NormalizeBitstreamNames: ", options);
        System.out.println("");
        System.out.println(
                "Normalize the names of bitstreams inside the DspaceObject designated by the root parameter\n" +
                        "With -f and -w option:\n" +
                        "        work only on bitstream in items where the metadata field is LIKE the given metadata value\n" +
                        "With -f only\n" +
                        "        work only on bitstream in items with any value for the given metadata field\n" +
                        "With -w only\n" +
                        "        work only on bitstream in items where at least one metadata value is LIKE the given value\n" +
                        "\n");
    }

    public static void main(String args[]) {
        CommandLineParser cliParser = new PosixParser();

        Options options = new Options();

        final String DSPACE_CONFIG_FILE = "/dspace/config/dspace.cfg";
        final String DEFAULT_MODE = "simple";

        // ePerson parameter
        options.addOption("c", "config", true, "config file - default " + DSPACE_CONFIG_FILE);
        options.addOption("m", "mode", true, "mode : [simple, theses] - default " + DEFAULT_MODE);
        options.addOption("r", "root", true, "handle or <TYPE>.ID   eg COMMUNITY.267");
        options.addOption("e", "eperson", true, "authorize as given eperson/netid");
        options.addOption("f", "metadata_field", true, "fully qualified metadata field, eg pu.date.classyear");
        options.addOption("w", "wert", true, "metadata field value, eg 2014");
        options.addOption("v", "verbose", false, "default: false");
        options.addOption("s", "submit", false, "default: do not commit changes");
        options.addOption("h", "help", false, "print help");

        String dspaceConfig = DSPACE_CONFIG_FILE;
        boolean submit = false;

        NormalizeBitstreamNames normalizer = new NormalizeBitstreamNames();
        normalizer.mode = SIMPLE_MODE;
        normalizer.verbose = false;

        // Extract the values of the options passed from the commandline
        try {
            CommandLine line = cliParser.parse(options, args);
            line = cliParser.parse(options, args);

            if (line.hasOption('h')) {
                usage(options);
                System.exit(0);
            }
            if (line.hasOption('c')) {
                dspaceConfig = line.getOptionValue('c');
            }
            ConfigurationManager.loadConfig(dspaceConfig);
            String dspace_dir = ConfigurationManager.getProperty("dspace.dir");
            System.out.println("dspace.dir=" + dspace_dir);

            DSpaceKernelImpl kernel_impl = DSpaceKernelInit.getKernel(null);
            if  (! kernel_impl.isRunning()) {
                System.out.println("starting kernel");
                kernel_impl.start( dspace_dir);
            }

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

            if (line.hasOption('m') && ! DEFAULT_MODE.equals(line.getOptionValue('m'))) {
                normalizer.mode = THESES_MODE;
            }

            normalizer.itemLister.restrictToItemsWith(line.getOptionValue('f'), line.getOptionValue('w'));

            DSpaceObject root = DSpaceObject.fromString(context, line.getOptionValue('r'));
            if (root == null) {
                throw new ParseException("must give a valid root parameter");
            }

            System.out.println("root = " + root);
            normalizer.verbose = line.hasOption('v');
            normalizer.perform(root);
            String prefix = "***** " + root.getName().replaceAll("\\s+", " ") + " " + root.getHandle() + " ";
            System.out.println(prefix + normalizer.change_results[CHANGED_NAME] + " bitstream names changed");
            System.out.println(prefix + normalizer.change_results[UNCHANGED_NAME] + " bitstreams had conforming names");
            System.out.println(prefix  + normalizer.change_results[UGLY_CHANGED_NAME] + " bitstreams had non conforming name that could not be changed");
            System.out.println(prefix  + normalizer.change_results[REVERT_NAME_CHANGE] + " bitstreams names were reverted after name change created a duplicate name");
            if (submit) {
                System.out.println("***** " + root.getName() + " " + root.getHandle() + " committing changes");
                context.commit();
            } else {
                System.out.println("***** " + root.getName() + " " + root.getHandle() + " NOT committing changes");
                context.abort();
            }
        } catch (ParseException e) {
            System.err.println(e.toString());
            usage(options);
            System.exit(1);
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

}
