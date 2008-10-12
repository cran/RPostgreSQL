## zzz.R
## Last Modified: $Date: 2008-10-08 19:56:45 -0500 (Wed, 08 Oct 2008) $

## This package was developed as a part of Summer of Code program organized by Google.
## Thanks to David A. James & Saikat DebRoy, the authors of RMySQL package.
## Code from RMySQL package was reused with the permission from the authors.
## Also Thanks to my GSoC mentor Dirk Eddelbuettel for helping me in the development.

.onLoad <- function(lib, pkg) {
    library.dynam("RPostgreSQL", pkg, lib)
}



