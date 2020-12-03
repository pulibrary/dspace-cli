package edu.princeton.dspace.seniorThesis;

import org.dspace.authorize.AuthorizeException;
import org.dspace.content.Collection;
import org.dspace.content.Community;
import org.dspace.content.Item;
import org.dspace.content.MetadataField;
import org.dspace.core.ConfigurationManager;
import org.dspace.core.Context;
import org.dspace.storage.rdbms.DatabaseManager;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.Hashtable;
import java.util.ArrayList;
import java.util.Iterator;

import org.apache.commons.cli.*;
import org.dspace.storage.rdbms.DatabaseUtils;
import org.dspace.storage.rdbms.TableRow;

import static java.util.Arrays.deepToString;


/**
 * When theses are deposited into DataSpace they are deposited into only a single collection.
 * The metadata may contain multiple pu.department field entries.  The thesis should be included in
 * all of the departmental collections corresponding to the pu.department entries.  This code finds
 * all theses that have multiple departments listed in the pu.department fields, and then adds the thesis
 * to any department collection to which it does not already belong.
 *
 * @author Mark Ratliff
 */

public class Map2Collections {

    private int COMMUNITY_ID;
    private int METADATA_FIELD_ID;
    private Connection dbconn;
    private Context context;
    private Statement stmt = null;
    Hashtable<String, Integer> deptname2id = null;
    boolean verbose;

    private Map2Collections(String config, int COMMUNITY_ID, int METADATA_FIELD_ID) throws SQLException {
        ConfigurationManager.loadConfig(config);
        this.COMMUNITY_ID = COMMUNITY_ID;
        this.METADATA_FIELD_ID = METADATA_FIELD_ID;
        this.verbose = false;
        this.context = new Context();
        this.context.turnOffAuthorisationSystem();
        this.dbconn = DatabaseManager.getConnection();

        Community comm = Community.find(context, COMMUNITY_ID);
        if (comm == null) {
            throw new RuntimeException("Can't find Community with id " + COMMUNITY_ID);
        }
        System.out.println("******  Community: " + comm.getID() + " " + comm.getHandle() + " '" + comm.getName() + "'");

        MetadataField mf = MetadataField.find(context, METADATA_FIELD_ID);
        if (mf == null) {
            throw new RuntimeException("Can't find Metadatafield with id " + METADATA_FIELD_ID);
        }
        System.out.println("******  MetadataField: " + mf.getFieldID() + " " + mf.getQualifier() + "." + mf.getElement());
    }

    private void setVerbose(boolean v) {
        this.verbose = v;
    }

    private ResultSet executeQuery(String sql) throws SQLException {
        if (stmt != null)
            stmt.close();
        stmt = dbconn.createStatement();
        if (verbose)
            System.out.println("\tQUERY: " + sql);
        ResultSet rs = stmt.executeQuery(sql);
        return rs;
    }

    private void close() throws SQLException {
        if (stmt != null)
            stmt.close();
        if (this.context.isValid())
            this.context.abort();
        this.dbconn = null;
    }

    /**
     * Return
     *
     * @return Hashtable of collection names (everything before the ',') and id's for easy lookup.
     * *@throws SQLException
     */
    private Hashtable<String, Integer> getDeptCollectionIDs() throws SQLException {
        if (deptname2id == null) {

            if (verbose) {
                System.out.println("Collections in COMMUNITY." + COMMUNITY_ID);
            }
            deptname2id = new Hashtable<String, Integer>();

            String select_stmt = "select collection.collection_id, name from collection " +
                    "inner join community2collection on " +
                    "collection.collection_id=community2collection.collection_id " +
                    "where community_id=" + COMMUNITY_ID;

            ResultSet rs = executeQuery(select_stmt);

            String name;
            Integer collectionid;
            while (rs.next()) {
                name = rs.getString("name");
                int commaAtI = name.indexOf(',');
                String use_name = name;
                if (commaAtI > 0)
                    use_name = name.substring(0, name.indexOf(','));
                collectionid = rs.getInt("collection_id");
                deptname2id.put(use_name, collectionid);
                if (verbose) {
                    System.out.println("\t" + use_name + " -> " + collectionid);
                }
            }

            rs.close();
        }
        return deptname2id;
    }

    /**
     * Obtain the list of items which have multiple pu.department fields
     *
     * @return
     * @throws SQLException
     */
    private ArrayList<Integer> getItemsWithMultipleDepts() throws SQLException {
        ArrayList<Integer> items = new ArrayList<Integer>();

        String select_stmt = "select item_id from (select item_id, count(*) from metadatavalue " +
                "where metadata_field_id=" + METADATA_FIELD_ID + " and item_id in " +
                "(select item_id from communities2item where community_id=" +
                COMMUNITY_ID + ") " +
                "group by item_id having count(*)>1)";

        ResultSet rs = executeQuery(select_stmt);

        int item_id;
        while (rs.next()) {
            item_id = rs.getInt("item_id");
            items.add(item_id);
        }

        rs.close();
        return items;
    }

    /**
     * For the given Item, look up the collection_id's for the department collections to which the Item should belong
     *
     * @return
     * @throws SQLException
     */
    private ArrayList<Integer> getPUDeptIDs(int item_id) throws SQLException {
        ArrayList<Integer> deptids = new ArrayList<Integer>();

        Hashtable<String, Integer> dept2collectionid = getDeptCollectionIDs();

        String select_stmt = "select text_value from metadatavalue where item_id=" +
                item_id + " and metadata_field_id=" + METADATA_FIELD_ID;

        ResultSet rs = executeQuery(select_stmt);

        String dept_name;
        Integer dept_id;
        while (rs.next()) {
            dept_name = rs.getString("text_value");
            dept_id = dept2collectionid.get(dept_name);
            if (dept_id != null) {
                deptids.add(dept_id);
            } else {
                Item i = Item.find(context, item_id);
                System.err.println("ERROR: " + i + " " + i.getHandle() + ": bad metadata value '" + dept_name + "' (no such collection)");
            }
        }

        rs.close();

        return deptids;
    }

    /**
     * Obtain the list of collections currently containing the Item
     *
     * @return
     * @throws SQLException
     */
    private ArrayList<Integer> getOwningCollectionIDs(Item item) throws SQLException {
        ArrayList<Integer> collection_ids = new ArrayList<Integer>();

        Collection colls[] = item.getCollections();
        for (int i = 0; i < colls.length; i++) {
            collection_ids.add(colls[i].getID());
        }

        return collection_ids;
    }

    /**
     * Obtain the Item to the given collection
     *
     * @return
     * @throws SQLException
     */
    private void addToCollection(Integer item_id, Integer collection_id) throws SQLException {
        TableRow row = DatabaseManager.row("collection2item");

        row.setColumn("collection_id", collection_id);
        row.setColumn("item_id", item_id);

        DatabaseManager.insert(context, row);
    }

    public static void usage(Options options) {
        HelpFormatter myhelp = new HelpFormatter();
        myhelp.printHelp("Map2Collections: ", options);
        System.out.println("");
    }

    /**
     * Main method containing controlling logic of the application.
     *
     * @param args
     */
    public static void main(String[] args) {
        CommandLineParser cliParser = new PosixParser();

        Options options = new Options();

        final String DSPACE_CONFIG_FILE = "/dspace/dspace.cfg";

        options.addOption("c", "config", true, "config file - default " + DSPACE_CONFIG_FILE);
        options.addOption("i", "community_id", true, "database community_id");
        options.addOption("d", "department_field", true, "database metadata field id");
        options.addOption("v", "verbose", false, "default: false");
        options.addOption("s", "submit", false, "default: do not commit changes");
        options.addOption("h", "help", false, "print help");

        String dspaceConfig = DSPACE_CONFIG_FILE;
        int communityId = -1;
        int departmendField = -1;
        boolean verbose = false;
        boolean submit = false;
        int nAdditions = 0;

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
            communityId = Integer.parseInt(line.getOptionValue('i'));
            departmendField = Integer.parseInt(line.getOptionValue('d'));

            verbose = line.hasOption('v');
            submit = line.hasOption('s');

        } catch (ParseException e) {
            System.err.println(e.toString());
            usage(options);
            System.exit(1);
        } catch (NumberFormatException e) {
            System.err.println("not a number: " + e.toString());
            usage(options);
            System.exit(1);
        }

        String info[] = { "info"};
        DatabaseUtils.main(info);

        try {
            Map2Collections m2c = new Map2Collections(dspaceConfig, communityId, departmendField);
            m2c.setVerbose(verbose);

            ArrayList<Integer> multi_dept_items = m2c.getItemsWithMultipleDepts();

            for (Integer item_id : multi_dept_items) {
                Item item = Item.find(m2c.context, item_id);
                if (item.isArchived()) {
                    // Get the collection_id's that the Item should belong to
                    ArrayList deptids = m2c.getPUDeptIDs(item_id);

                    // Get the collection_id's that the Item currently belongs to
                    ArrayList<Integer> collection_ids = m2c.getOwningCollectionIDs(item);

                    // For each department id that is not listed in collection_ids add the item to the cirresponding collection
                    Iterator dept_iter = deptids.iterator();
                    Integer dept_id;
                    while (dept_iter.hasNext()) {
                        dept_id = (Integer) dept_iter.next();

                        Collection deptColl = Collection.find(m2c.context, dept_id);
                        String status = "";

                        if (collection_ids.contains(dept_id)) {
                            status = "MAPPED";
                        } else {
                            status = "ADDING";
                        }
                        System.out.println(status + " " + item + "," + item.getHandle() + " " + deptColl + "," + deptColl.getHandle() +
                                "\tto-coll.name=" + deptColl.getName() +
                                "\titem.name=" + item.getName());
                        if (!collection_ids.contains(dept_id)) {
                            deptColl.addItem(item);
                            nAdditions = nAdditions + 1;
                        }
                    }
                }
            }

            System.out.println("******  Performed " + nAdditions + " collection additions");
            if (submit) {
                System.out.println("******  Commiting changes");
                m2c.context.complete();
            } else {
                System.out.println("******  DRYRUN: NOT Commiting changes");
            }
            m2c.close();

        } catch (SQLException sqle) {
            System.err.println("Caught SQLException");
            sqle.printStackTrace();
        } catch (AuthorizeException e) {
            System.err.println("Should have turned authorzation system off");
            e.printStackTrace();
        }

    }
}
