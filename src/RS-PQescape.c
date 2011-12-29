/*
 *  RS-PQescape.c
 *
 *  $Id: RS-PQescape.c 212 2011-11-22 10:58:50Z tomoakin@kenroku.kanazawa-u.ac.jp $
 */

#include "RS-PostgreSQL.h"


/* 
 * Adapter function to PQescapeStringConn()
 * This function should properly escape the string argument 
 * appropriately depending on the encoding etc. that is specific to 
 * connection.
 * Note the single quote is not attached in the return val.
 */

SEXP
RS_PostgreSQL_escape(SEXP conHandle, SEXP preescapestring)
{
    S_EVALUATOR PGconn * my_connection;
    RS_DBI_connection *con;
    SEXP output;
    size_t length;
    const char *statement_cstr;
    char *escapedstring;
    con = RS_DBI_getConnection(conHandle);
    my_connection = (PGconn *) con->drvConnection;
    statement_cstr = CHR_EL(preescapestring, 0);
    length = strlen(statement_cstr);
    escapedstring = R_alloc(length * 2 + 1, 1);
    PQescapeStringConn(my_connection, escapedstring, statement_cstr, length, NULL);
    output = allocVector(STRSXP, 1);
    SET_STRING_ELT(output, 0, mkChar(escapedstring));
    return output;
}

