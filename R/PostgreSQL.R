## PostgreSQL.R
## $Id$

## This package was developed as a part of Summer of Code program organized by Google.
## Thanks to David A. James & Saikat DebRoy, the authors of RMySQL package.
## Code from RMySQL package was reused with the permission from the authors.
## Also Thanks to my GSoC mentor Dirk Eddelbuettel for helping me in the development.

##
## Constants
##

##.PostgreSQLRCS <- "$Id: PostgreSQL.R,v 0.1 2008/06/10 14:00:00$"
.PostgreSQLPkgName <- "RPostgreSQL"
.PostgreSQLVersion <- "0.6-1"       ##package.description(.PostgreSQLPkgName, fields = "Version")
.PostgreSQL.NA.string <- "\\N"      ## on input, PostgreSQL interprets \N as NULL (NA)

setOldClass("data.frame")      ## to appease setMethod's signature warnings...

##
## Class: DBIObject
##
setClass("PostgreSQLObject", representation("DBIObject", "dbObjectId", "VIRTUAL"))

##
## Class: dbDriver
##

PostgreSQL <- function(max.con=16, fetch.default.rec = 500, force.reload=FALSE) {
    postgresqlInitDriver(max.con = max.con, fetch.default.rec = fetch.default.rec,
                         force.reload = force.reload)
}

##
## Class: DBIDriver
##
setClass("PostgreSQLDriver", representation("DBIDriver", "PostgreSQLObject"))

## coerce (extract) any PostgreSQLObject into a PostgreSQLDriver
setAs("PostgreSQLObject", "PostgreSQLDriver",
      def = function(from) new("PostgreSQLDriver", Id = as(from, "integer")[1:2])
      )

setMethod("dbUnloadDriver", "PostgreSQLDriver",
          def = function(drv, ...) postgresqlCloseDriver(drv, ...),
          valueClass = "logical"
          )

setMethod("dbGetInfo", "PostgreSQLDriver",
          def = function(dbObj, ...) postgresqlDriverInfo(dbObj, ...)
          )

setMethod("dbListConnections", "PostgreSQLDriver",
          def = function(drv, ...) dbGetInfo(drv, "connectionIds")[[1]]
          )

setMethod("summary", "PostgreSQLDriver",
          def = function(object, ...) postgresqlDescribeDriver(object, ...)
          )

##
## Class: DBIConnection
##
setClass("PostgreSQLConnection", representation("DBIConnection", "PostgreSQLObject"))

setMethod("dbConnect", "PostgreSQLDriver",
          def = function(drv, ...) postgresqlNewConnection(drv, ...),
          valueClass = "PostgreSQLConnection"
          )

setMethod("dbConnect", "character",
          def = function(drv, ...) postgresqlNewConnection(dbDriver(drv), ...),
          valueClass = "PostgreSQLConnection"
          )

## clone a connection
setMethod("dbConnect", "PostgreSQLConnection",
          def = function(drv, ...) postgresqlCloneConnection(drv, ...),
          valueClass = "PostgreSQLConnection"
          )

setMethod("dbDisconnect", "PostgreSQLConnection",
          def = function(conn, ...) postgresqlCloseConnection(conn, ...),
          valueClass = "logical"
          )

setGeneric("dbEscapeStrings", def = function(conn, string, ...) standardGeneric("dbEscapeStrings"))
setMethod("dbEscapeStrings",
          signature(conn="PostgreSQLConnection", string="character"),
          def = function(conn, string, ...) postgresqlEscapeStrings(conn, string, ...),
          valueClass = "character"
          )

setMethod("dbSendQuery",
          signature(conn = "PostgreSQLConnection", statement = "character"),
          def = function(conn, statement,...) postgresqlExecStatement(conn, statement,...),
          valueClass = "PostgreSQLResult"
          )


setMethod("dbGetQuery",
          signature(conn = "PostgreSQLConnection", statement = "character"),
          def = function(conn, statement, ...) postgresqlQuickSQL(conn, statement, ...)
          )

setMethod("dbGetException", "PostgreSQLConnection",
          def = function(conn, ...){
              if(!isPostgresqlIdCurrent(conn))
                  stop(paste("expired", class(conn)))
              .Call(RS_PostgreSQL_getException, as(conn, "integer"))
          },
          valueClass = "list"
          )

setMethod("dbGetInfo", "PostgreSQLConnection",
          def = function(dbObj, ...) postgresqlConnectionInfo(dbObj, ...)
          )

setMethod("dbListResults", "PostgreSQLConnection",
          def = function(conn, ...) dbGetInfo(conn, "rsId")[[1]]
          )

setMethod("summary", "PostgreSQLConnection",
          def = function(object, ...) postgresqlDescribeConnection(object, ...)
          )

## convenience methods
setMethod("dbListTables", "PostgreSQLConnection",
          def = function(conn, ...){
              out <- dbGetQuery(conn,
                                paste("select tablename from pg_tables where schemaname !='information_schema'",
                                      "and schemaname !='pg_catalog'", ...))
              if (is.null(out) || nrow(out) == 0)
                  out <- character(0)
              else
                  out <- out[, 1]
              out
          },
          valueClass = "character"
          )

setMethod("dbReadTable", signature(conn="PostgreSQLConnection", name="character"),
          def = function(conn, name, ...) postgresqlReadTable(conn, name, ...),
          valueClass = "data.frame"
          )

setMethod("dbWriteTable",
          signature(conn="PostgreSQLConnection", name="character", value="data.frame"),
          def = function(conn, name, value, ...){
              postgresqlWriteTable(conn, name, value, ...)
          },
          valueClass = "logical"
          )

## write table from filename (TODO: connections)
setMethod("dbWriteTable",
          signature(conn="PostgreSQLConnection", name="character", value="character"),
          def = function(conn, name, value, ...){
              postgresqlImportFile(conn, name, value, ...)
          },
          valueClass = "logical"
          )

setMethod("dbExistsTable",
          signature(conn="PostgreSQLConnection", name="character"),
          def = function(conn, name, ...){
              qlength <- length(name)
              if(qlength == 1){
              currentschema <- dbGetQuery(conn, "SELECT current_schema()")
              res <- dbGetQuery(conn,
                  paste("select tablename from pg_tables where ",
                  "schemaname !='information_schema' and schemaname !='pg_catalog' ",
                  "and schemaname='", postgresqlEscapeStrings(conn, currentschema[[1]]), "' ",
                  "and tablename='", postgresqlEscapeStrings(conn, name), "'", sep=""))
              }
              else{
                  if(qlength == 2){
                  res <- dbGetQuery(conn,
                      paste("select tablename from pg_tables where ",
                      "schemaname !='information_schema' and schemaname !='pg_catalog' ",
                      "and schemaname='", postgresqlEscapeStrings(conn, name[1]), "' ",
                      "and tablename='", postgresqlEscapeStrings(conn, name[2]), "'", sep=""))
                  }
              }
              return(as.logical(dim(res)[1]))
          },
          valueClass = "logical"
          )

setMethod("dbRemoveTable",
          signature(conn="PostgreSQLConnection", name="character"),
          def = function(conn, name, ...){
              if(dbExistsTable(conn, name)){
                  rc <- try(dbGetQuery(conn, paste("DROP TABLE", postgresqlTableRef(name))))
                  !inherits(rc, ErrorClass)
              }
              else FALSE
          },
          valueClass = "logical"
          )

setMethod("dbBegin",
          signature(conn="PostgreSQLConnection"),
          def = function(conn,  ...){
              rc <- try(dbGetQuery(conn, "BEGIN"))
              !inherits(rc, ErrorClass)
          },
          valueClass = "logical"
          )
setMethod("dbCommit",
          signature(conn="PostgreSQLConnection"),
          def = function(conn,  ...){
              rc <- try(dbGetQuery(conn, "COMMIT"))
              !inherits(rc, ErrorClass)
          },
          valueClass = "logical"
          )
setMethod("dbRollback",
          signature(conn="PostgreSQLConnection"),
          def = function(conn,  ...){
              rc <- try(dbGetQuery(conn, "ROLLBACK"))
              !inherits(rc, ErrorClass)
          },
          valueClass = "logical"
          )

## return field names (no metadata)
setMethod("dbListFields",
          signature(conn="PostgreSQLConnection", name="character"),
          def = function(conn, name, ...){
              qlength <- length(name)
              if(qlength == 1){
              currentschema <- dbGetQuery(conn, "SELECT current_schema()")
              flds <- dbGetQuery(conn,
                  paste0("select a.attname from pg_attribute a, pg_class c, pg_tables t, pg_namespace nsp ",
                  "where a.attrelid = c.oid and c.relname = tablename and c.relnamespace = nsp.oid and ",
                  "a.attnum > 0 and not a.attisdropped and ",
                  "nspname = current_schema() and ",
                  "schemaname = nspname and ",
                  "tablename = '", postgresqlEscapeStrings(conn, name), "'"))[,1]
              }
              else{
                  if(qlength == 2){
                  flds <- dbGetQuery(conn,
                      paste0("select a.attname from pg_attribute a, pg_class c, pg_tables t, pg_namespace nsp ",
                      "where a.attrelid = c.oid and c.relname = t.tablename and c.relnamespace = nsp.oid and ",
                      "a.attnum > 0 and not a.attisdropped and ",
                      "nspname = schemaname and ",
                      "schemaname = '", postgresqlEscapeStrings(conn, name[1]), "' and ",
                      "tablename = '", postgresqlEscapeStrings(conn, name[2]), "'"))[,1]
                  }
              }

              if(length(flds)==0)
                  flds <- character()
              flds
          },
          valueClass = "character"
          )


setMethod("dbCallProc", "PostgreSQLConnection",
          def = function(conn, ...) .NotYetImplemented()
          )

setMethod("dbCommit", "PostgreSQLConnection",
          def = function(conn, ...) postgresqlTransactionStatement(conn, "COMMIT")
          )

setMethod("dbRollback", "PostgreSQLConnection",
          def = function(conn, ...) {
              rsList <- dbListResults(conn)
              if (length(rsList))
                  dbClearResult(rsList[[1]])
              postgresqlTransactionStatement(conn, "ROLLBACK")
          }
          )


##
## Class: DBIResult
##
setClass("PostgreSQLResult", representation("DBIResult", "PostgreSQLObject"))

setAs("PostgreSQLResult", "PostgreSQLConnection",
      def = function(from) new("PostgreSQLConnection", Id = as(from, "integer")[1:3])
      )
setAs("PostgreSQLResult", "PostgreSQLDriver",
      def = function(from) new("PostgreSQLDriver", Id = as(from, "integer")[1:2])
      )

setMethod("dbClearResult", "PostgreSQLResult",
          def = function(res, ...) postgresqlCloseResult(res, ...),
          valueClass = "logical"
          )

setMethod("fetch", signature(res="PostgreSQLResult", n="numeric"),
          def = function(res, n, ...){
              out <- postgresqlFetch(res, n, ...)
              if(is.null(out))
                  out <- data.frame(out)
              out
          },
          valueClass = "data.frame"
          )

setMethod("fetch",
          signature(res="PostgreSQLResult", n="missing"),
          def = function(res, n, ...){
              out <-  postgresqlFetch(res, n=0, ...)
              if(is.null(out))
                  out <- data.frame(out)
              out
          },
          valueClass = "data.frame"
          )

setMethod("dbGetInfo", "PostgreSQLResult",
          def = function(dbObj, ...) postgresqlResultInfo(dbObj, ...),
          valueClass = "list"
          )

setMethod("dbGetStatement", "PostgreSQLResult",
          def = function(res, ...){
              st <-  dbGetInfo(res, "statement")[[1]]
              if(is.null(st))
                  st <- character()
              st
          },
          valueClass = "character"
          )

setMethod("dbListFields",
          signature(conn="PostgreSQLResult", name="missing"),
          def = function(conn, name, ...){
              flds <- dbGetInfo(conn, "fields")$fields$name
              if(is.null(flds))
                  flds <- character()
              flds
          },
          valueClass = "character"
          )

setMethod("dbColumnInfo", "PostgreSQLResult",
          def = function(res, ...) postgresqlDescribeFields(res, ...),
          valueClass = "data.frame"
          )

setMethod("dbGetRowsAffected", "PostgreSQLResult",
          def = function(res, ...) dbGetInfo(res, "rowsAffected")[[1]],
          valueClass = "numeric"
          )

setMethod("dbGetRowCount", "PostgreSQLResult",
          def = function(res, ...) dbGetInfo(res, "rowCount")[[1]],
          valueClass = "numeric"
          )

setMethod("dbHasCompleted", "PostgreSQLResult",
          def = function(res, ...) dbGetInfo(res, "completed")[[1]] == 1,
          valueClass = "logical"
          )

setMethod("dbGetException", "PostgreSQLResult",
          def = function(conn, ...){
              id <- as(conn, "integer")[1:2]
              .Call(RS_PostgreSQL_getException, id)
          },
          valueClass = "list"    ## TODO: should be a DBIException?
          )

setMethod("summary", "PostgreSQLResult",
          def = function(object, ...) postgresqlDescribeResult(object, ...)
          )



setMethod("dbDataType",
          signature(dbObj = "PostgreSQLObject", obj = "ANY"),
          def = function(dbObj, obj, ...) postgresqlDataType(obj, ...),
          valueClass = "character"
          )


## MODIFIED : -- sameer
setMethod("make.db.names",
          signature(dbObj="PostgreSQLObject", snames = "character"),
          def = function(dbObj, snames,keywords,unique, allow.keywords,...){
              postgresqlQuoteId(snames)
          },
          valueClass = "character"
          )

setMethod("SQLKeywords", "PostgreSQLObject",
          def = function(dbObj, ...) .PostgreSQLKeywords,
          valueClass = "character"
          )

setMethod("isSQLKeyword",
          signature(dbObj="PostgreSQLObject", name="character"),
          def = function(dbObj, name,keywords,case, ...){
              isSQLKeyword.default(name, keywords = .PostgreSQLKeywords)
          },
          valueClass = "character"
          )
## extension to the DBI 0.1-4
setGeneric("dbApply", def = function(res, ...) standardGeneric("dbApply"))
setMethod("dbApply", "PostgreSQLResult",
          def = function(res, ...)  postgresqlDBApply(res, ...),
          )


