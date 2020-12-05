/* handler.c: HTTP Request Handlers */

#include "spidey.h"

#include <errno.h>
#include <limits.h>
#include <string.h>

#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>

/* Internal Declarations */
Status handle_browse_request(Request *request);
Status handle_file_request(Request *request);
Status handle_cgi_request(Request *request);
Status handle_error(Request *request, Status status);

/**
 * Handle HTTP Request.
 *
 * @param   r           HTTP Request structure
 * @return  Status of the HTTP request.
 *
 * This parses a request, determines the request path, determines the request
 * type, and then dispatches to the appropriate handler type.
 *
 * On error, handle_error should be used with an appropriate HTTP status code.
 **/
Status  handle_request(Request *r) {
    Status result;

    /* Parse request */
    if(parse_request(r) != 0){
        return handle_error(r, HTTP_STATUS_BAD_REQUEST);
    }

    /* Determine request path */
    r->path = determine_request_path(r->uri);
    debug("HTTP REQUEST PATH: %s", r->path);

    /* Dispatch to appropriate request handler type based on file type */

    struct stat s;
    if(r->path && stat(r->path, &s) == 0){
        if(S_ISDIR(s.st_mode)){
            result = handle_browse_request(r);
        }else if(S_ISREG(s.st_mode)){
            if(access(r->path, X_OK)==0){

                result = handle_cgi_request(r);
            }else{
                result = handle_file_request(r);
            }
        }
    }else{
        result = handle_error(r, HTTP_STATUS_NOT_FOUND);
    }
    

    log("HTTP REQUEST STATUS: %s", http_status_string(result));   

    return result;
}

/**
 * Handle browse request.
 *
 * @param   r           HTTP Request structure.
 * @return  Status of the HTTP browse request.
 *
 * This lists the contents of a directory in HTML.
 *
 * If the path cannot be opened or scanned as a directory, then handle error
 * with HTTP_STATUS_NOT_FOUND.
 **/
Status  handle_browse_request(Request *r) {
    char *mimetype = "\0";
    struct dirent **entries;
    int n;

    /* Open a directory for reading or scanning */
    n = scandir(r->path, &entries, 0, alphasort);
    if(n<0){
        return handle_error(r,HTTP_STATUS_NOT_FOUND);
    }

    /* Write HTTP Header with OK Status and text/html Content-Type */
    fprintf(r->stream, "HTTP/1.0 200 OK\r\n");
    fprintf(r->stream, "Content-Type: text/html\r\n");
    fprintf(r->stream, "\r\n");

    /* For each entry in directory, emit HTML list item */
    fprintf(r->stream, "<ul>\n");
    for(int i = 0; i < n; i++){
        if(streq(entries[i]->d_name, ".")){
            free(entries[i]);
            i++;
        }
        if(streq(entries[i]->d_name, "..")){
            if(strchr(r->uri, '/') == r->uri+strlen(r->uri)-1){
                fprintf(r->stream, "<li><a href=\"%s%s\">%s</a></li>\n", r->uri, entries[i]->d_name, entries[i]->d_name);

            }else{
                fprintf(r->stream, "<li><a href=\"%s/%s\">%s</a></li>\n", r->uri, entries[i]->d_name, entries[i]->d_name); 
            }

            free(entries[i]);
            i++;
        }
        if(access(entries[i]->d_name, X_OK)==0){
            mimetype = "\0";
        }else{
            mimetype = determine_mimetype(entries[i]->d_name);
        }
        if(strchr(r->uri, '/') == r->uri+strlen(r->uri)-1){
            if(streq(mimetype, "image/png") || streq(mimetype, "image/jpeg")){
                fprintf(r->stream, "<li><a href=\"%s%s\"><img src=\"%s%s\" style=\"width:100px\">%s</a></li>\n", r->uri, entries[i]->d_name, r->uri, entries[i]->d_name, entries[i]->d_name);

            }else{
                fprintf(r->stream, "<li><a href=\"%s%s\">%s</a></li>\n", r->uri, entries[i]->d_name, entries[i]->d_name);
            }
        }else{
            if(streq(mimetype, "image/png") || streq(mimetype, "image/jpeg")){
                fprintf(r->stream, "<li><a href=\"%s/%s\"><img src=\"%s/%s\" style=\"width:100px\">%s</a></li>\n", r->uri, entries[i]->d_name, r->uri, entries[i]->d_name, entries[i]->d_name);

            }else{
                fprintf(r->stream, "<li><a href=\"%s/%s\">%s</a></li>\n", r->uri, entries[i]->d_name, entries[i]->d_name);
            }

        }
        
        free(mimetype);
        free(entries[i]);
    }
    free(entries);
    fprintf(r->stream,"</ul>\n");


    /* Return OK */
    return HTTP_STATUS_OK;
}

/**
 * Handle file request.
 *
 * @param   r           HTTP Request structure.
 * @return  Status of the HTTP file request.
 *
 * This opens and streams the contents of the specified file to the socket.
 *
 * If the path cannot be opened for reading, then handle error with
 * HTTP_STATUS_NOT_FOUND.
 **/
Status  handle_file_request(Request *r) {
    FILE *fs;
    char buffer[BUFSIZ];
    char *mimetype = "\0";
    size_t nread;
    Status status = HTTP_STATUS_OK;

    /* Open file for reading */
    fs = fopen(r->path, "r");
    if(!fs){
        status = HTTP_STATUS_NOT_FOUND;
        goto fail;
    }
    /* Determine mimetype */
    
    mimetype = determine_mimetype(r->uri);

    /* Write HTTP Headers with OK status and determined Content-Type */

    fprintf(r->stream, "HTTP/1.0 200 OK\r\n");
    fprintf(r->stream, "Content-Type: %s\r\n", mimetype);
    fprintf(r->stream, "\r\n");
    /* Read from file and write to socket in chunks */
    nread = fread(buffer, 1, BUFSIZ, fs);
    while(nread > 0){
        fwrite(buffer, 1, nread, r->stream);
        nread = fread(buffer, 1, BUFSIZ, fs);
    }
    /* Close file, deallocate mimetype, return OK */
    fclose(fs);
    free(mimetype);
    return status;

fail:
    /* Close file, free mimetype, return INTERNAL_SERVER_ERROR */
    free(mimetype);
    fclose(fs);
    return handle_error(r, status);
}

/**
 * Handle CGI request
 *
 * @param   r           HTTP Request structure.
 * @return  Status of the HTTP file request.
 *
 * This popens and streams the results of the specified executables to the
 * socket.
 *
 * If the path cannot be popened, then handle error with
 * HTTP_STATUS_INTERNAL_SERVER_ERROR.
 **/
Status  handle_cgi_request(Request *r) {
    FILE *pfs;
    char buffer[BUFSIZ];

    /* Export CGI environment variables from request:
     * http://en.wikipedia.org/wiki/Common_Gateway_Interface */
    setenv("QUERY_STRING", r->query, 1);
    setenv("DOCUMENT_ROOT", RootPath, 1);
    setenv("REMOTE_ADDR", r->host, 1);
    setenv("REMOTE_PORT", r->port, 1);
    setenv("REQUEST_METHOD", r->method, 1);
    setenv("REQUEST_URI", r->uri, 1);
    setenv("SCRIPT_FILENAME", r->path, 1);
    setenv("SERVER_PORT", Port, 1);


    /* Export CGI environment variables from request headers */
    for(Header *header = r->headers; header; header = header->next){
        if(streq(header->name, "Host")){
            setenv("HTTP_HOST", header->data, 1);
        }else if(streq(header->name, "User-Agent")){
            setenv("HTTP_USER_AGENT", header->data, 1);
        }

    }

    /* POpen CGI Script */

    pfs = popen(r->path, "r");
    if(!pfs){
        return handle_error(r, HTTP_STATUS_INTERNAL_SERVER_ERROR);
    }

    /* Copy data from popen to socket */
    size_t nread = fread(buffer, 1, BUFSIZ, pfs);
    while(nread > 0){
        fwrite(buffer, 1, nread, r->stream);
        nread = fread(buffer, 1, BUFSIZ, pfs);
    }


    /* Close popen, return OK */
    pclose(pfs);
    return HTTP_STATUS_OK;
}

/**
 * Handle displaying error page
 *
 * @param   r           HTTP Request structure.
 * @return  Status of the HTTP error request.
 *
 * This writes an HTTP status error code and then generates an HTML message to
 * notify the user of the error.
 **/
Status  handle_error(Request *r, Status status) {
    const char *status_string = http_status_string(status);

    /* Write HTTP Header */
    fprintf(r->stream, "HTTP/1.0 %s\r\n", status_string);
    fprintf(r->stream, "Content-Type: text/html\r\n");
    fprintf(r->stream, "\r\n");

    /* Write HTML Description of Error*/
    fprintf(r->stream, "<h1>%s</h1>\n", status_string);
    fprintf(r->stream, "<center><img src=\"https://www.safetysupplywarehouse.com/v/vspfiles/photos/WFS3-2T.jpg\"></center>\n");

    /* Return specified status */

    return status;
}

/* vim: set expandtab sts=4 sw=4 ts=8 ft=c: */
