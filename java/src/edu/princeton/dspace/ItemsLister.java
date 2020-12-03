package edu.princeton.dspace;

/*
 * intended to turn this into a proper curation task
 * for now just run from main program
 */

import org.apache.log4j.Logger;
import org.dspace.authorize.AuthorizeException;
import org.dspace.content.*;
import org.dspace.core.Constants;
import org.dspace.core.Context;
import org.dspace.storage.rdbms.DatabaseManager;
import org.dspace.storage.rdbms.TableRowIterator;
import java.sql.SQLException;

public class ItemsLister {
    private static Logger log = Logger.getLogger(ItemsLister.class);

    MetadataField metadata_field = null;
    String metadata_value = null;

    Context context = null;

    public ItemsLister() {
    }

    public void restrictToItemsWith(String fully_qualified_metadata_field, String value)
            throws SQLException, AuthorizeException {
        if (value != null && value.isEmpty()) {
            throw new RuntimeException("must provide non empty metadata value");
        }
        metadata_value = value;
        if (fully_qualified_metadata_field != null) {
            metadata_field = Utils.getMetadataField(context, Utils.toMetadatum(fully_qualified_metadata_field));
            if (metadata_field == null) {
                throw new RuntimeException("No such metadata field " + fully_qualified_metadata_field);
            }
        }
    }

    public TableRowIterator itemIterator(DSpaceObject restrict_to_dso) throws SQLException {
        log.info("restrictToDso " + restrict_to_dso + " " + restrict_to_dso.getHandle() );

        String sql = "SELECT DISTINCT MV.RESOURCE_ID FROM MetadataValue MV  " ;
        String restrict = null;
        if (restrict_to_dso != null) {
            if (restrict_to_dso.getType() == Constants.COLLECTION) {
                sql = sql + " INNER JOIN Collection2Item CO  ON MV.resource_id = CO.item_id ";
                restrict = " CO.Collection_Id = " + restrict_to_dso.getID();
            } else if (restrict_to_dso.getType() == Constants.COMMUNITY) {
                sql = sql + " INNER JOIN Community2Item CO  ON MV.resource_id = CO.item_id ";
                restrict = " CO.Community_Id = " + restrict_to_dso.getID();
            } else if (restrict_to_dso.getType() == Constants.ITEM) {
                restrict = " MV.Resource_Id = " + restrict_to_dso.getID();
            } else {
                throw new RuntimeException("can't restrict item listing to " + restrict_to_dso);
            }
        }
        String where = "RESOURCE_TYPE_ID = " + Constants.ITEM;
        if (metadata_field != null)
            where = where + " MV.metadata_field_id=" + metadata_field.getFieldID();
        if (metadata_value != null && !metadata_value.isEmpty()) {
            if (!where.isEmpty())
                where = where + " AND ";
            where = where + " MV.text_value LIKE '" + metadata_value + "'";
        }
        if (restrict != null) {
            if (!where.isEmpty())
                where = where + " AND ";
            where = where + restrict;
        }
        if (! where.isEmpty())
            sql = sql + " WHERE  " + where;
        log.debug("SQL: " + sql);
        return DatabaseManager.queryTable(context, "MetadataValue", sql);
    }

}
