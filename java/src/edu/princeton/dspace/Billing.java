package edu.princeton.dspace;


/**
 * This application is used to compute charges for Items stored in DSpace.
 * Makes use of CLI-API v1.0 from Apache http://commons.apache.org/cli/
 * and the DSpace API.
 *
 * @author Mark Ratliff, Princeton University
 */

import java.sql.SQLException;
import java.util.Iterator;
import java.util.Date;
import java.util.ArrayList;
import java.util.Set;
import java.util.HashSet;
import java.io.File;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.text.DecimalFormat;

import org.dspace.content.*;
import org.dspace.core.Constants;
import org.dspace.core.Context;
import org.apache.commons.cli.*;



public class Billing {

    /**
     * Main method of application which processes command line arguments and
     * runs the computations.
     *
     * @param args Arguments from the commandline
     */

    String storageunits;
    long bytes2units;

    public static void main(String[] args) {

        CommandLineParser cliParser = new PosixParser();
        String outputfile, startdate, enddate, cost, mincost, costunits;
        String[] costparts;

        // Define the options which can be passed via the commandline

        Options options = new Options();

        options.addOption(OptionBuilder.isRequired(true).hasArg(true)
                .withDescription("File to which report should be written")
                .create("o"));

        options.addOption(OptionBuilder
                .isRequired(true)
                .hasArg(true)
                .withDescription(
                        "Date on which to commence billing calculation [yyyyMMdd]")
                .create("s"));

        options.addOption(OptionBuilder.isRequired(true).hasArg(true)
                .withDescription(
                        "Date on which to end billing calculation [yyyyMMdd]")
                .create("e"));

        options.addOption(OptionBuilder.isRequired(true).hasArg(true)
                .withDescription("Cost in dollars per unit of storage [for example 0.003/MB]."+
                        "Units can be B, KB, MB or GB").create("c"));

        options.addOption(OptionBuilder.isRequired(true).hasArg(true)
                .withDescription("The minimum cost in dollars for a submission [for example 0.03]")
                .create("m"));

        HelpFormatter f = new HelpFormatter();
        String usagestr = "java Billing -o outputfile -s startdate -e enddate -c cost -m minimum_cost";

        try {

            // Extract the values of the options passed from the commandline

            CommandLine line = cliParser.parse(options, args);

            outputfile = line.getOptionValue("o");
            startdate = line.getOptionValue("s");
            enddate = line.getOptionValue("e");
            cost = line.getOptionValue('c');
            costparts = cost.split("/");
            cost = costparts[0];
            costunits = costparts[1];

            mincost = line.getOptionValue('m');

            Integer.parseInt(startdate);
            Integer.parseInt(enddate);
            Integer.parseInt(enddate);

            if (startdate.toString().length() != 8
                    && enddate.toString().length() != 8) {
                System.err
                        .println("startdate and enddate must be 8 digits long:  yyyymmdd");
                f.printHelp(usagestr, options);
                System.exit(1);
            }

            // Set the date after which items should be billed

            int year = Integer.parseInt(startdate.substring(0, 4));
            int month = Integer.parseInt(startdate.substring(4, 6));
            int day = Integer.parseInt(startdate.substring(6, 8));

            DCDate dcbillingdate = new DCDate(year, month, day, 0, 0, 0);

            Date from_date = dcbillingdate.toDate();

            // Set the date before which items should be billed

            year = Integer.parseInt(enddate.substring(0, 4));
            month = Integer.parseInt(enddate.substring(4, 6));
            day = Integer.parseInt(enddate.substring(6, 8));

            dcbillingdate = new DCDate(year, month, day, 0, 0, 0);

            Date to_date = dcbillingdate.toDate();

            // Check to see that from_date < to_date
            if (to_date.before(from_date))
            {
                System.out.println("The start date must be a date prior to the end date");
                f.printHelp(usagestr, options);
                System.exit(1);
            }

            File reportfile = new File(outputfile);

            Billing b = new Billing();
            b.setStorageUnits(costunits);

            b.computeCharges(from_date, to_date, Float.parseFloat(cost),
                    Float.parseFloat(mincost), reportfile);

        } catch (MissingOptionException moe) {
            System.err.println("Missing options: " + moe.getMessage());

            f.printHelp(usagestr, options);
            System.exit(1);
        } catch (MissingArgumentException mae) {
            System.err.println("Missing arguments for: " + mae.getMessage());

            f.printHelp(usagestr, options);
            System.exit(1);
        } catch (ParseException pe) {
            System.err.println("Problems parsing commandline "
                    + pe.getMessage());

            f.printHelp(usagestr, options);
            System.exit(1);
        } catch (NumberFormatException nfe) {
            System.err
                    .println("The arguments startdate, enddate must be integers.  The "+
                            "arguments cost and minimum_cost must be decimals.");
            f.printHelp(usagestr, options);
            System.exit(1);
        } catch (SQLException sqle) {
            System.err.println("There was an SQLException");
            sqle.printStackTrace();
        } catch (Exception e) {
            System.err.println("There was an Exception");
            e.printStackTrace();
            System.exit(1);
        }

    }

    /**
     * This method computes all applicable charges.
     *
     * @param from_date Items accessioned after this date will be included in the report
     * @param to_date Items accessioned before this date will be included in the report
     * @param unit_cost cost per GB of storage
     * @param min_cost
     * @param reportfile the file that the XML report should be written to
     * @throws Exception
     */
    public void computeCharges(Date from_date, Date to_date, float unit_cost,
                               float min_cost, File reportfile) throws Exception {

        Context context;
        String collectionname;

        // Open output file
        FileWriter fstream = new FileWriter(reportfile);
        BufferedWriter output = new BufferedWriter(fstream);

        // Write common header information to the reportfile
        writeReportHeader(output, from_date, to_date, unit_cost);

        // Get the DSpace context
        context = new Context();

        // Need to fill this in?
        // output.write("<dspace_instance_name></dspace_instance_name>");

        // Should we record the name of the communities in the XML?

        // For each Item, get the size of its BitStreams and calculate the
        // charge

        ArrayList<Integer> uniqueitemids = findItemsByDate(context, from_date, to_date);

        ArrayList<String> collectionnames = findCollectionNames(context, uniqueitemids);

        Iterator ci = collectionnames.iterator();

        // Iterate through the collections the items are contained within

        while (ci.hasNext()) {

            collectionname = (String) ci.next();
            output.write("<collection name=\"" + collectionname + "\">");
            output.newLine();

            // Write the Item information for all items in this collection
            writeReportItems(context, uniqueitemids, collectionname, unit_cost,
                    min_cost, output);

            output.write("</collection>");
        }

        // Close the report
        output.write("</dspace_billing_report>");
        output.close();

    }

    /**
     * This method finds all Items with accession dates newer than
     * since_this_date.
     *
     * @param context
     * @param from_date Items accessioned after this date will be included in the report
     * @param to_date Items accessioned before this date will be included in the report
     * @return An ArrayList containing the Items
     * @throws Exception
     */
    private ArrayList<Integer> findItemsByDate(Context context, Date from_date,
                                               Date to_date) throws Exception {

        MetadataValue mdvalue;
        DCDate dcaccessiondate;
        Date accessiondate;
        java.util.Collection mdvaluecollection;
        Iterator iterator;
        ArrayList<Integer> itemids = new ArrayList<Integer>();

        MetadataSchema mdschema = MetadataSchema.find(context, "dc");

        int schemaID = mdschema.getSchemaID();

        MetadataField mdfield = MetadataField.findByElement(context, schemaID,
                "date", "accessioned");

        int mdfieldID = mdfield.getFieldID();

        mdvaluecollection = MetadataValue.findByField(context, mdfieldID);

        // Step through the collection. For each value, create a DCDate and
        // compare to billing date

        iterator = mdvaluecollection.iterator();

        while (iterator.hasNext()) {

            mdvalue = (MetadataValue) iterator.next();

            dcaccessiondate = new DCDate(mdvalue.getValue());

            accessiondate = dcaccessiondate.toDate();

            // If DCDate > BillingDate then add Item ID to list

            if (accessiondate.after(from_date) && accessiondate.before(to_date)) {
                if (mdvalue.getResourceTypeId() != Constants.ITEM) {
                    System.err.println("ERROR " + this.getClass().getSimpleName() + " " +
                            "tyep=" + mdvalue.getResourceTypeId() + ":id=" + mdvalue.getResourceId() + " not an item");
                } else {
                    itemids.add(new Integer(mdvalue.getResourceId()));
                }
            }

        }

        // Eliminate duplicate Item IDs
        Set<Integer> set = new HashSet<Integer>(itemids);
        ArrayList<Integer> uniqueitemids = new ArrayList<Integer>(set);

/*		System.out.println("Number of unique Item IDs is = "
				+ uniqueitemids.size() + "\n");
*/

        return uniqueitemids;
    }

    /**
     * This method sums the size of all bitstreams associated with an item.
     *
     * @param item  The Item the BitStreams are associated with
     * @return The totalsize in bytes
     * @throws SQLException
     */
    private long computeItemTotalSize(Item item) throws SQLException {
        Bundle[] bundlearray;
        Bitstream[] bitstreamarray;
        long totalitemsize = 0;

        // Get the Bundles associated with this item
        bundlearray = item.getBundles();

        // For each bundle, get the size of each bitstream and add to total size
        // of the item

        for (int i = 0; i < bundlearray.length; i++) {

            bitstreamarray = bundlearray[i].getBitstreams();

            for (int j = 0; j < bitstreamarray.length; j++) {
                // System.out.println("Size of biststream = "
                // + bitstreamarray[j].getSize());

                totalitemsize += bitstreamarray[j].getSize();
            }
        }

        return totalitemsize;
    }

    /**
     * Find the names of all the collections the given Items belong to.
     *
     * @param context DSpace context
     * @param uniqueitemids The list of Items
     * @return @ throws SQLException
     */

    private ArrayList<String> findCollectionNames(Context context,
                                                  ArrayList<Integer> uniqueitemids) throws SQLException {
        Item item;
        org.dspace.content.Collection[] collections;
        ItemIterator ii = new ItemIterator(context, uniqueitemids);
        HashSet<String> hs = new HashSet<String>();

        while (ii.hasNext()) {

            item = ii.next();
            collections = item.getCollections();

            hs.add(collections[0].getName());
        }

        ArrayList<String> collectionnames = new ArrayList<String>(hs);

        return collectionnames;
    }

    /**
     * Write information for each of the Items in the indicated collection to
     * the report file.
     *
     * @param context
     * @param uniqueitemids
     *            The list of all Items
     * @param collectionname
     *            The name of the collection for which Items should be reported
     * @param unit_cost
     *            The cost for submitting an Item (per GB).
     * @param output
     *            The report XML file
     * @throws SQLException
     * @throws IOException
     */
    private void writeReportItems(Context context, ArrayList<Integer> uniqueitemids,
                                  String collectionname, float unit_cost, float min_cost, BufferedWriter output)
            throws SQLException, IOException {
        Metadatum[] dcvaluearray;
        DCDate dcdate;
        String submitter;
        SimpleDateFormat sdf = new SimpleDateFormat("MMddyyyy");
        Item item;
        long totalitemsize;

        ItemIterator ii = new ItemIterator(context, uniqueitemids);

        while (ii.hasNext()) {

            item = ii.next();
            org.dspace.content.Collection[] itemcollections = item
                    .getCollections();

            if (collectionname.equals(itemcollections[0].getName())) {
                output.write("<item>");
                output.newLine();

                // Print the name and accession date for the item
                output.write("  <arkID>" + item.getHandle() + "</arkID>");
                output.newLine();

                output.write("  <title>" + item.getName() + "</title>");
                output.newLine();

                dcvaluearray = item.getMetadataByMetadataString("dc.date.accessioned");
                dcdate = new DCDate(dcvaluearray[0].value);
                output.write("  <accession_date>" + sdf.format(dcdate.toDate())
                        + "</accession_date>");
                output.newLine();

                dcvaluearray = item.getMetadataByMetadataString("dc.description.provenance");
                submitter = findSubmitterFromProvenance(dcvaluearray);
                output.write("  <submitter>" + submitter + "</submitter>");
                output.newLine();

                dcvaluearray = item.getMetadataByMetadataString("pu.projectgrantnumber");
                output.write("  <puprojectgrantnumber>");
                if (dcvaluearray != null && dcvaluearray.length > 0) {
                    output.write(cleanProjectGrantNumber(dcvaluearray[0].value));
                }
                output.write("</puprojectgrantnumber>");
                output.newLine();

                totalitemsize = computeItemTotalSize(item);

                output.write("  <totalbytes>" + totalitemsize + "</totalbytes>");
                output.newLine();

                String cost = computeItemCost(totalitemsize, unit_cost, min_cost);
                output.write("  <cost>" + cost + "</cost>");
                output.newLine();

                output.write("</item>");
            }
        }
    }

    /**
     * Calculate the cost to be charged for a submitted Item.
     *
     * @param totalitemsize
     *            The size of the item in bytes
     * @param unit_cost
     *            The cost per GB
     * @return The cost for the item as a String in XXXX.XX format
     */
    private String computeItemCost(long totalitemsize, float unit_cost, float min_cost) {
        // Convert size to MB then multiply by cost/MB
        float totalcost = (totalitemsize/this.bytes2units) * unit_cost;

        // Charge minimum amount
        if (totalcost < min_cost)
            totalcost = min_cost;

        // Format for printing
        DecimalFormat currency = new DecimalFormat("#0.00");
        return currency.format(totalcost);
    }

    /**
     * Write header information to the XML report file (e.g. when the report was
     * run, accessions during what time interval should be reported, etc.)
     *
     * @param output The file that the report will be written to
     * @param from_date Items accessioned after this date will be included in the report
     * @param to_date Items accessioned before this date will be included in the report
     * @param unit_cost  The cost per GB for storage
     * @throws IOException
     */
    private void writeReportHeader(BufferedWriter output, Date from_date,
                                   Date to_date, float unit_cost) throws IOException {
        SimpleDateFormat sdf = new SimpleDateFormat("MMddyyyy");

        output.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        output.newLine();
        output.write("<dspace_billing_report>");
        output.newLine();

        output.write("<header>");
        output.newLine();

        Date today = new Date();

        output.write("<report_date>" + sdf.format(today) + "</report_date>");
        output.newLine();
        output.newLine();

        output.write("<billing_interval>");
        output.write("<billing_begin>" + sdf.format(from_date)
                + "</billing_begin>");
        output.write("<billing_end>" + sdf.format(to_date) + "</billing_end>");
        output.write("</billing_interval>");
        output.newLine();

        output.write("<unit_of_measure unit=\""+this.storageunits+"\"/>");
        output.newLine();
        output.write("<unit_cost unit=\""+unit_cost+"\"/>");
        output.newLine();

        output.write("</header>");
        output.newLine();
    }

    private String findSubmitterFromProvenance(Metadatum[] dcvaluearray)
    {
        String keywords = "Submitted by ";
        String str, submitter;

        if (dcvaluearray != null && dcvaluearray.length > 0) {
            for (int i=0; i<dcvaluearray.length; ++i)
            {
                str = dcvaluearray[i].value;

                // We are looking for an entry that starts with "Submitted by"
                if (str.startsWith(keywords))
                {
                    // Extract the Name and e-mail address
                    submitter = str.substring(keywords.length(), str.indexOf(')')+1);
                    return submitter;
                }
            }
            return "Unknown";
        }
        else
        {
            return "Unknown";
        }
    }

    private String cleanProjectGrantNumber(String value)
    {
        // Remove an dashes '-' from the string
        StringBuffer sb = new StringBuffer(value);

        for (int i=0; i<sb.length(); ++i)
        {
            if (sb.charAt(i) == '-')
            {
                sb.deleteCharAt(i);
            }
        }

        return sb.toString();
    }

    public void setStorageUnits(String units)
    {
        this.storageunits = units;

        if (units.equals("B")) this.bytes2units = 1;
        else if (units.equals("KB")) this.bytes2units = 1000;
        else if (units.equals("MB")) this.bytes2units = 1000000;
        else if (units.equals("GB")) this.bytes2units = 1000000000;
//		else if (units.equals("TB")) this.bytes2units = 1000000000000;
    }

}