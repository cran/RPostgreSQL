% $Id: dbConnect-methods.Rd,v 0.1 2008/07/28 20:56:01 psk Exp $
\name{dbConnect-methods}
\docType{methods}
\alias{dbDisconnect-methods}
\alias{dbConnect-methods}
\alias{dbDisconnect,PostgreSQLConnection-method}
\alias{dbConnect,PostgreSQLDriver-method}
\alias{dbConnect,PostgreSQLConnection-method}
\alias{dbConnect,character-method}
\title{
  Create a connection object to an PostgreSQL DBMS
}
\description{
   These methods are straight-forward implementations of the corresponding
   generic functions.
}
\section{Methods}{\describe{
\item{drv}{
  an object of class \code{PostgreSQLDriver}, or
  the character string "PostgreSQL" or an \code{PostgreSQLConnection}.
  }
\item{conn}{
  an \code{PostgreSQLConnection} object as produced by \code{dbConnect}.
  }
\item{host}{Name or the numeric IPaddress of the host to connect to. If address is specified, it should be in the standard IPv4 address format, e.g., 172.28.40.9 or if your machine supports IPv6, you can also use those addresses. The default is to connect to localhost by a UNIX domain socket.
 }
\item{dbname}{The database name. Defaults to "", which is interpreted as PostgreSQL default.
  Most parameters are currently passed to PQsetdbLogin() as is. 
  If dbname contains an = sign or has a valid connection URI prefix, 
  it is taken as a conninfo for PQconnectdb() depending on the linked driver version.
  Refer to \url{https://www.postgresql.org/docs/current/libpq-connect.html} for detail.
 }
\item{user}{PostgreSQL user name to connect as. Defaults to be the same as the operating system name of the user running the application.
 }
\item{password}{Password to be used if the server demands password authentication.
 }
\item{port}{Port number to connect to at the server host.
 }
\item{tty}{Ignored (formerly, this specified where to send server debug output).
 }
\item{options}{Command-line options to be sent to the server.
 }
\item{forceISOdate}{logical if the communication of date (time stamp) from PostgreSQL is forced to ISO style at conection. This is an exception that is not really set by an option for PQsetdbLogin, but by issueing dbGetQuery(con, "set datestyle to ISO") after connection.
 }
}
}
\section{Side Effects}{
  A connection between R/S-Plus and an PostgreSQL  server is
  established.   The current implementation supports up to
  100 simultaneous connections.
}
\references{
  See the Database Interface definition document
  \code{DBI.pdf} in the base directory of this package
  or \url{https://cran.r-project.org/package=DBI}.
}
\seealso{
  \code{\link{PostgreSQL}},
  \code{\link[DBI]{dbConnect}},
  \code{\link[DBI]{dbSendQuery}},
  \code{\link[DBI]{dbGetQuery}},
  \code{\link[DBI]{fetch}},
  \code{\link[DBI]{dbCommit}},
  \code{\link[DBI]{dbGetInfo}},
  \code{\link[DBI]{dbReadTable}}.
}
\examples{\dontrun{
# create an PostgreSQL instance and create one connection.
drv <- dbDriver("PostgreSQL")

# open the connection using user, passsword, etc., as
con <- dbConnect(drv, dbname = "postgres")

df <- dbGetQuery(con, statement = paste(
                      "SELECT itemCode, itemCost, itemProfit",
                      "FROM sales",
                      "SORT BY itemName"));
# Run an SQL statement by creating first a resultSet object
rs <- dbSendQuery(con, statement = paste(
                      "SELECT itemCode, itemCost, itemProfit",
                      "FROM sales",
                      "SORT BY itemName"));

# we now fetch records from the resultSet into a data.frame
df <- fetch(rs, n = -1)   # extract all rows
dim(df)
}
}
\keyword{methods}
\keyword{interface}
\keyword{database}
% vim: syntax=tex
