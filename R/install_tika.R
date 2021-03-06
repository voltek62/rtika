#' Install or Update the Apache Tika \code{jar}
#'
#' This downloads and installs the Tika App \code{jar} (~60 MB) into a user directory,
#' and verifies the integrity of the file using a md5 checksum.
#' The default settings should work fine.
#'
#' @param version The declared Tika version
#' @param md5_sum The md5 checksum. Set to an empty string \code{""} to skip the check.
#' @param mirrors A vector Apache mirror sites. One is picked randomly.
#' @param retries The number of times to try the download.
#' @param url Optional url of a particular file to download. Will override downloading from random mirrors.
#'
#' @return Logical if the installation was successful.
#' @examples
#' \dontrun{
#' install_tika()
#' }
#' @section Details:
#' The default settings of \code{install_tika()} should typically be left as they are.
#'
#' This function will download the version of the Tika \code{jar} tested to work
#' with this package, and can verify file integrity using a checksum.
#'
#' It will normally download from a random Apache mirror.
#' If the mirror fails,
#' it tries the archive at \code{http://archive.apache.org/dist/tika/}.
#' You can also enter a value for \code{url} directly to override this.
#'
#' It will download into a directory determined
#' by the \code{rappdirs::user_data_dir()} function,
#' specific to the operating system.
#'
#' If \code{tika()} is stopping with an error compalining about the \code{jar},
#' try running \code{install_tika()} again.
#'
#' @section Uninstalling:
#' If you are uninstalling the entire \code{rtika} package
#' and want to remove the Tika App \code{jar} also,
#' run:
#'
#'  \code{unlink(rappdirs::user_data_dir('rtika'), recursive = TRUE)}
#'
#' Alternately, navigate to the install folder and delete it manually.
#' It is the file path returned by \code{rappdirs::user_data_dir('rtika')}.
#' The path is OS specific, and explained here:
#' https://github.com/r-lib/rappdirs .
#'
#' @export

install_tika <- function(version = 1.18,
                         md5_sum = "",
                         mirrors = c(
                           "http://mirrors.ocf.berkeley.edu/apache/tika/",
                           "http://apache.cs.utah.edu/tika/",
                           "http://mirror.cc.columbia.edu/pub/software/apache/tika/"
                         ),
                         retries = 2,
                         url = "https://builds.apache.org/job/tika-branch-1x/10/org.apache.tika$tika-app/artifact/org.apache.tika/tika-app/1.18-20180309.175001-20/tika-app-1.18-20180309.175001-20.jar") {
   
     # Get user directory  -------------------
     user_data_dir <-
    normalizePath(
      rappdirs::user_data_dir("rtika"),
      mustWork = FALSE
    )


  if (!dir.exists(user_data_dir)) {
    dir.create(
      user_data_dir,
      recursive = TRUE,
      showWarnings = FALSE
    )
    if (!file.exists(user_data_dir)) {
      stop("Could not create use directory to download file. Stopping.")
    }
  }

  if (nchar(url) == 0) {
    random_mirror <- sample(mirrors, 1)

    url <- paste0(
      random_mirror,
      paste0("tika-app-", version, ".jar")
    )
  }

  message(
    "Downloading the Tika App .jar version ", version, ' into "',
    user_data_dir,
    '". The file is approximately 60 MB - this may take a while.'
  )

  download <- tika_fetch(
    url,
    download_dir = user_data_dir,
    retries = retries
  )

  if (is.na(download)) {
    warning('Could not download the Tika App .jar from mirror "', url, '".
Trying the Apache archive.')

    url <- paste0(
      "http://archive.apache.org/dist/tika/",
      paste0("tika-app-", version, ".jar")
    )

    download <- tika_fetch(
      url,
      download_dir = user_data_dir,
      retries = retries
    )

    if (is.na(download)) {
      stop('Could not download the Tika App .jar from the archive "', url, '". 
Stopping. Try running install_tika() again, setting url to a particular path.')
    }
  }

  path <- file.path(user_data_dir, "tika-app.jar")

  renamed <- file.rename(download, path)

  if (!renamed) {
    stop("Could not rename the temporary download file on this system.
Removing the temporary file and stopping the installation.")
    file.remove(download)
  }

  exists <- tika_jar()

  if (!is.na(exists)) {
    message("The download is successful.")
  } else {
    stop('Stopping. The "tika_jar()" funtion could not find the Tika App .jar')
  }

  if (nchar(md5_sum) > 0) {
    file_integrity <- tika_check(md5_sum)

    if (!file_integrity) {
      stop("The Tika App .jar integrity is bad! It failed the md5 checksum test.
    Removing the file and stopping installation.")
      file.remove(exists)
    } else {
      message("The file integrity is good.")
    }
  }

  writeLines(text = as.character(version), file.path(user_data_dir, "tika-app-version.txt"))

  message("The installation is successful.")
  return(invisible(TRUE))
}
