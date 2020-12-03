package edu.princeton.dspace;

/*
 * intended to turn this into a proper curation task
 * for now just run from main program
 */

import org.apache.commons.cli.*;
import org.dspace.authorize.AuthorizeException;
import org.dspace.core.ConfigurationManager;
import org.dspace.core.Constants;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.sql.*;

public class FixUTFFromQADB {
    Connection dbCorrect, dbSave;
    Boolean verbose;
    Boolean no_prompt;
    String metaDataName = "";

    public FixUTFFromQADB() {
    }

    final String allValues = "SELECT resource_id,metadata_value_id,text_value,resource_type_id FROM METADATAVALUE ";



    public static void usage(Options options) {
        HelpFormatter myhelp = new HelpFormatter();
        myhelp.printHelp("usage: ", options);
        System.out.println("");
    }

    final static String correctValueList
            = "SELECT resource_id,metadata_value_id,text_value,resource_type_id FROM METADATAVALUE " +
            "WHERE resource_type_id in (0, 2, 3, 4) AND metadata_field_id = ? ";
    final static String correctValueListOne
            = "SELECT resource_id,metadata_value_id,text_value,resource_type_id FROM METADATAVALUE " +
            "WHERE resource_type_id in (0, 2, 3, 4) AND metadata_field_id = ?  AND resource_id = 90451";
    final static String matchingValue = "SELECT resource_id,metadata_value_id,text_value,resource_type_id FROM METADATAVALUE " +
            "WHERE METADATA_FIELD_ID = ? " +
            "AND  resource_id = ? AND resource_type_id = ? AND metadata_value_id = ? ";
    final static String matchingValueNoId = "SELECT resource_id,metadata_value_id,text_value,resource_type_id FROM METADATAVALUE " +
            "WHERE METADATA_FIELD_ID = ? " +
            "AND  resource_id = ? AND resource_type_id = ? ";

    public void findAndUpdate(int metadata_field_id, int commit_after_n) throws SQLException, AuthorizeException, IOException {
        /* loop over all entries in METADATA_VALUE_TABLE in correct db  for given field_id */
        /* find matching value and update if they are different */
        int nDiff = 0;
        int nUpdates = 0;
        boolean neverCommit = (commit_after_n <= 0);

        PreparedStatement stmt = dbCorrect.prepareStatement(correctValueList);
        stmt.setInt(1, metadata_field_id);
        ResultSet rightValueIter = stmt.executeQuery();

        PreparedStatement matchStmt = dbSave.prepareStatement(matchingValue);
        matchStmt.setInt(1, metadata_field_id);

        PreparedStatement matchStmtNoId = dbSave.prepareStatement(matchingValueNoId);
        matchStmtNoId.setInt(1, metadata_field_id);

        while (rightValueIter.next()) {
            int res_id = rightValueIter.getInt("resource_id");
            int good_value_id = rightValueIter.getInt("metadata_value_id");
            String good_value = rightValueIter.getString("text_value");
            int res_type = rightValueIter.getInt("resource_type_id");
            verbose(metaDataName + " GOOD_VALUE: " + res_id + " " + good_value_id + " " + good_value);

            int match_res_id = -1, match_value_id = -1;
            String match_value = null;
            // first try to match including metadata_value_id
            int nMatches = 0;
            {
                matchStmt.setInt(2, res_id);
                matchStmt.setInt(3, res_type);
                matchStmt.setInt(4, good_value_id);
                ResultSet matchIter = matchStmt.executeQuery();

                while (matchIter.next()) {
                    match_res_id = matchIter.getInt("resource_id");
                    match_value_id = matchIter.getInt("metadata_value_id");
                    match_value = matchIter.getString("text_value");

                    verbose(metaDataName + " MATCH-AGAINST: " + match_res_id + " " + match_value_id + " " + match_value);
                    nMatches = nMatches + 1;
                }
            }
            String goodHandle = getHandle(dbCorrect, res_id, res_type);
            String saveHandle = getHandle(dbSave, res_id, res_type);

            if  (0 == nMatches) {
                // now  try with resource id and resource_type alone
                matchStmtNoId.setInt(2, res_id);
                matchStmtNoId.setInt(3, res_type);
                ResultSet matchIter = matchStmtNoId.executeQuery();
                while (matchIter.next()) {
                    match_res_id = matchIter.getInt("resource_id");
                    match_value_id = matchIter.getInt("metadata_value_id");
                    match_value = matchIter.getString("text_value");

                    verbose(metaDataName + " MATCH-AGAINST-NO-ID: " + match_res_id + " " + match_value_id + " " + match_value);
                    nMatches = nMatches + 1;
                }
            }

            switch (nMatches) {
                case 0:
                    System.out.println(metaDataName + " YIKES: no match for " + describe(res_type, res_id, good_value_id, good_value));
                    break;
                case 1:
                    boolean differ = true;
                    if (match_value != null && good_value != null) {
                        differ = match_value.compareTo(good_value) != 0;
                    } else {
                        differ = (match_value != good_value);  // test wherth noth or null - if not tey are different
                    }
                    if (differ) {
                        if (seemsSame(good_value, match_value)) {
                            nDiff = nDiff + 1;
                            System.out.println(metaDataName + " GOOD  DIFF-" + nDiff + "\t        \t" + describe(res_type, res_id, good_value_id, good_value, goodHandle));
                            System.out.println(metaDataName + " MATCH DIFF-" + nDiff + "\t        \t" + describe(res_type, res_id, match_value_id, match_value, saveHandle));
                            if (0 != goodHandle.compareTo(saveHandle)) {
                                System.out.println(metaDataName + " HANDLE DIFF-" + nDiff + "\t destHandle=" + saveHandle + " " + describe(res_type, res_id, good_value_id, good_value, goodHandle));
                            } else {
                                int nup = update(dbSave, nDiff, res_type, res_id, match_value_id, good_value, goodHandle);
                                if (nup != 1) neverCommit = true;
                                nUpdates++;
                                if (nUpdates == commit_after_n) {
                                    if (neverCommit) {
                                        verbose(metaDataName + " rollback");
                                        dbSave.rollback();
                                    } else {
                                        prompt_commit(metaDataName, dbSave);
                                    }
                                    nUpdates = 0;
                                }
                            }
                        } else {
                            // iso are different - really shouldn't happen
                            System.out.println(metaDataName + " ISO DIFF-" + nDiff + "\t        \t" + describe(res_type, res_id, good_value_id, good_value, goodHandle));
                            System.out.println(metaDataName + " ISO DIFF-" + nDiff + "\t        \t" + describe(res_type, res_id, good_value_id, match_value, saveHandle));
                        }
                    } else {
                        verbose(metaDataName + " SAME: " + describe(res_type, res_id, good_value_id, good_value, goodHandle));
                    }
                    break;
                default: {
                    System.out.println(metaDataName + " YIKES there are more than 1 for " + describe(res_type, res_id, good_value_id, good_value));
                    break;
                }
            }
            verbose("");
        }
        if (neverCommit) {
            verbose(metaDataName + " rollback");
            dbSave.rollback();
        } else {
            prompt_commit(metaDataName, dbSave);
        }

        matchStmt.close();
        stmt.close();
        System.out.println(metaDataName + " DIFF-TOTAL\tnDiff=" + nDiff);
    }

    /*
           UPDATE METADATAVALUE
       SET TEXT_VALUE = 'Elecciones 2006 y referéndum :  perpect'
       WHERE RESOURCE_TYPE_ID = 2 AND METADATA_VALUE_ID = 20971 ;

    */
    static final String update_metadata =
            "UPDATE METADATAVALUE SET TEXT_VALUE = ? WHERE RESOURCE_TYPE_ID = ? AND METADATA_VALUE_ID = ? AND RESOURCE_ID = ?";

    private int update(Connection dbUpdate, int nDiff, int res_type, int res_id, int md_value_id, String good_text, String handle) throws SQLException {
        int nup = 0;
        PreparedStatement stmt = dbUpdate.prepareStatement(update_metadata);
        stmt.setString(1, good_text);
        stmt.setInt(2, res_type);
        stmt.setInt(3, md_value_id);
        stmt.setInt(4, res_id);
        nup = stmt.executeUpdate();

        if (nup != 1) {
            System.out.println(metaDataName + " DIFF-UPDATE YIKES " + nDiff + "\t nrec=" + nup + " " + describe(res_type, res_id, md_value_id, good_text, handle));
        } else {
            System.out.println(metaDataName + " DIFF-UPD " + nDiff + "\tnrec=" + nup + "\t" + describe(res_type, res_id, md_value_id, good_text, handle));
        }
        stmt.close();
        return nup;
    }


    private void prompt_commit(String metaDataName, Connection dbCommit) throws IOException, SQLException {
        System.out.println("commit y/n ? ");
        BufferedReader buffer = new BufferedReader(new InputStreamReader(System.in));
        String line = buffer.readLine();
        if (line.length() > 0 && line.charAt(0) == 'y') {
            verbose(metaDataName + " commit");
            dbCommit.commit();
        }
    }


    public void listNonISO(Connection db) throws SQLException {
        System.out.println("allValueList    " + allValues);

        int nDiff = 0, n = 0;
        PreparedStatement stmt = db.prepareStatement(allValues);
        ResultSet rightValueIter = stmt.executeQuery();
        while (rightValueIter.next()) {
            int good_res_id = rightValueIter.getInt("resource_id");
            int good_value_id = rightValueIter.getInt("metadata_value_id");
            int good_res_type = rightValueIter.getInt("resource_type_id");
            String good_value = rightValueIter.getString("text_value");
            n = n + 1;
            verbose("CHECK-" + n + "\t" + good_res_id + " " + good_value_id + " " + good_value);
            try {
                if (good_value == null) {
                    verbose("SAME-" + n + "\t" + describe(good_res_type, good_res_id, good_value_id, good_value) + " -> NULL STRING");
                    continue;
                }
                String iso = new String(good_value.getBytes("ISO-8859-1"));
                String utf = new String(good_value.getBytes("UTF-8"));
                if (0 != utf.compareTo(iso)) {
                    nDiff = nDiff + 1;
                    System.out.println("GOOD  DIFF-" + nDiff + "\t" + describe(good_res_type, good_res_id, good_value_id, good_value, getHandle(db, good_res_id, good_res_type)));
                    System.out.println("MATCH DIFF-" + nDiff + "\t" + describe(good_res_type, good_res_id, good_value_id, iso, getHandle(dbSave, good_res_id, good_res_type)));
                } else {
                    verbose("GOOD  SAME-" + n + "\t" + describe(good_res_type, good_res_id, good_value_id, good_value));
                    verbose("MATCH SAME-" + n + "\t" + describe(good_res_type, good_res_id, good_value_id, iso));
                }
            } catch (UnsupportedEncodingException e) {
                System.out.println("YIKES-exception" + "\t" + describe(good_res_type, good_res_id, good_value_id, good_value));
            }
        }
        stmt.close();
    }

    public void setMetadaName(int metadata_field_id) throws SQLException {
        System.out.println("METADATAFIELD dest: " + getMetadataFieldInfo(dbCorrect, metadata_field_id));
        System.out.println("METADATAFIELD right: " + getMetadataFieldInfo(dbSave, metadata_field_id));
        if (0 != getMetadataFieldInfo(dbCorrect, metadata_field_id).compareTo(getMetadataFieldInfo(dbSave, metadata_field_id))) {
            throw new RuntimeException("YIKES the field defs are not matching");
        }
        metaDataName = getMetadataFieldInfo(dbCorrect, metadata_field_id);
    }

    private static String getMetadataFieldInfo(Connection db, int field_id) throws SQLException {
        final String mdInfo = "SELECT metadata_field_id,element,qualifier FROM METADATAFIELDREGISTRY WHERE METADATA_FIELD_ID = " + field_id;
        PreparedStatement stmt = db.prepareStatement(mdInfo);
        ResultSet iter = stmt.executeQuery();
        iter.next();
        String s = "metadata_field_id=" + iter.getInt("metadata_field_id") +
                "[" + iter.getString("element") + "." + iter.getString("qualifier") + "]";
        stmt.close();
        return s;
    }

    static final String UNKNOWN_HANDLE = "HANDLE/UNKNOWN";

    final static String select_handle = " SELECT HANDLE FROM HANDLE WHERE RESOURCE_ID = ? AND RESOURCE_TYPE_ID = ? ";

    static final String bitstream_handle = "SELECT HANDLE FROM HANDLE WHERE RESOURCE_TYPE_ID = 2 AND RESOURCE_ID IN ( \n" +
            "SELECT ITEM_ID FROM ITEM2BUNDLE WHERE BUNDLE_ID in (SELECT BUNDLE_ID FROM BUNDLE2BITSTREAM WHERE BITSTREAM_ID IN (?)\n" +
            "))";

    String getHandle(Connection db, int res_id, int res_type) throws SQLException {
        PreparedStatement stmt;
        if (res_type == Constants.ITEM || res_type == Constants.COLLECTION || res_type == Constants.COMMUNITY) {
            stmt = db.prepareStatement(select_handle);
            stmt.setInt(2, res_type);
        } else {
            stmt = db.prepareStatement(bitstream_handle);
        }

        stmt.setInt(1, res_id);
        ResultSet handle = stmt.executeQuery();
        try {
            if (handle.next()) {
                return handle.getString("handle");
            }
            return UNKNOWN_HANDLE;
        } finally {
            stmt.close();
        }
    }

    public static Connection getConnection(String version) throws SQLException {
        String dbUrl = ConfigurationManager.getProperty(version + ".db.url");
        String user = ConfigurationManager.getProperty(version + ".db.username");
        String pwd = ConfigurationManager.getProperty(version + ".db.password");

        System.out.println("*** " + version);
        System.out.println(dbUrl);
        System.out.println(user);
        System.out.println(pwd);
        System.out.println();

        return DriverManager.getConnection(dbUrl, user, pwd);
    }

    // describe(good_item_id, good_value_id, good_value))
    String describe(int res_type, int res_id, int val_id, String val, String handle) {
        if (handle == null) {
            handle = "--------------------";
        }
        String str = metaDataName + "\t" + "value_id=" + val_id + " RES=" + Constants.typeText[res_type] + "." + res_id + " " + handle + " " + val;
        return str;
    }

    String describe(int res_type, int res_id, int val_id, String val) {
        return describe(res_type, res_id, val_id, val, null);
    }

    void verbose(String s) {
        if (verbose) {
            System.out.println("DEBUG " + s);
        }
    }

    public static void main(String args[]) throws AuthorizeException, IOException {
        CommandLineParser cliParser = new PosixParser();

        Options options = new Options();

        // ePerson parameter
        options.addOption("c", "config", true, "config file  ");
        options.addOption("m", "metadata_field_list", true, "metadata field ids ; comma separated");
        options.addOption("l", "list all differences", false, "default false");
        options.addOption("n", "no prompt", false, "default false");
        options.addOption("v", "verbose", false, "default: false");
        options.addOption("s", "submit", true, "prompt for commit after n changes; -1  => never commit");
        options.addOption("h", "help", false, "print help");

        // Extract the values of the options passed from the commandline
        try {
            CommandLine line = cliParser.parse(options, args);
            line = cliParser.parse(options, args);

            if (line.hasOption('h')) {
                usage(options);
                System.exit(0);
            }

            ConfigurationManager.loadConfig(line.getOptionValue('c'));

            FixUTFFromQADB normalizer = new FixUTFFromQADB();
            normalizer.dbCorrect = getConnection("right");
            normalizer.dbSave = getConnection("dest");
            normalizer.dbSave.setAutoCommit(false);
            normalizer.verbose = line.hasOption('v');
            boolean list_all = line.hasOption('l');
            boolean no_prompt = line.hasOption('n');


            System.out.println("rightValueList    " + correctValueList);
            System.out.println("destMatchingValue " + matchingValue);
            System.out.println("matchingValueNoId " + matchingValueNoId);
            System.out.println();

            BufferedReader buffer = new BufferedReader(new InputStreamReader(System.in));
            if (!no_prompt) {
                System.out.println("return to continue");
                buffer.readLine();
            }

            if (list_all) {
                normalizer.listNonISO(normalizer.dbSave);
            } else {

                int commit_after_n = Integer.parseInt(line.getOptionValue('s'));
                System.out.println("prompt_commit each " + commit_after_n);

                if (!no_prompt) {
                    System.out.println("return to continue");
                    buffer.readLine();
                }

                String md_val_list = line.getOptionValue('m');
                String[] val_list = md_val_list.split(",");

                for (String val : val_list) {
                    System.out.println("\n-------\n");
                    Integer mid = Integer.parseInt(val);
                    normalizer.setMetadaName(mid);
                    if (!no_prompt) {
                        System.out.println("return to continue");
                        buffer.readLine();
                    }

                    normalizer.findAndUpdate(mid, commit_after_n);
                    System.out.println("\n-------\n");
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        } catch (ParseException e) {
            e.printStackTrace();
        }
    }

    private static boolean seemsSame(String good_value, String match_value) throws UnsupportedEncodingException {
        boolean same;
        if (good_value == null) {
            return match_value == null;
        }
        String pattern = "[^a-zA-Z0-9_()!@#%{}|;':,./<>]";
        String good = new String(good_value.getBytes("UTF-8")).replaceAll(pattern, "");
        String match = new String(match_value.getBytes("UTF-8")).replaceAll(pattern, "");

        same = (0 == good.compareTo(match));
        return same;
    }
}