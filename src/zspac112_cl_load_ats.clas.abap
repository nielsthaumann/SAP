"! Class to fetch ATS resume data from a remote CSV file and load it into database table ZSPAC112_ATS
CLASS zspac112_cl_load_ats DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun. " Print messages in terminal for development
ENDCLASS.

CLASS zspac112_cl_load_ats IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    " URL to the table as CSV
    CONSTANTS lc_url  TYPE string VALUE 'https://raw.githubusercontent.com/nielsthaumann/SAP/main/ats_resume_dataset_elite_v3.csv'.
    CONSTANTS lc_cols TYPE i VALUE 17. " Expected number of columns in the table

    " Data declarations for HTTP response and CSV parsing
    DATA lv_csv    TYPE string.                                        " Received CSV data
    DATA lt_rows   TYPE STANDARD TABLE OF zspac112_ats WITH EMPTY KEY. " Rows to append to the table
    DATA lt_fields TYPE string_table.                                  " Temporary list of parsed column values for the current row
    DATA lv_raw    TYPE string.                                        " Raw substring extracted for a single field
    DATA lv_c      TYPE string.                                        " Current character being inspected in the loop
    DATA lv_quoted TYPE abap_bool.                                     " Flag tracking whether the parser is currently inside double quotes
    DATA lv_i      TYPE i.                                             " Current character index (0-based offset)
    DATA lv_start  TYPE i.                                             " Starting character index of the current field
    DATA lv_rownum TYPE i.                                             " Counter for non-empty rows processed (1 = header)
    DATA lv_bad    TYPE i.                                             " Counter for malformed rows skipped due to wrong column count


    " Download the CSV file with HTTP GET

    TRY.
        " Create HTTP destination and client objects from the target URL
        DATA(lo_dest)   = cl_http_destination_provider=>create_by_url( lc_url ).
        DATA(lo_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        DATA(lo_resp)   = lo_client->execute( if_web_http_client=>get ).
        DATA(lv_status) = lo_resp->get_status( )-code.

        " Abort if the server did not return HTTP 200 (OK)
        IF lv_status <> 200.
          out->write( |Download failed, HTTP status { lv_status }| ).
          lo_client->close( ).
          RETURN.
        ENDIF.

        " Extract response body as string and release HTTP client resources
        lv_csv = lo_resp->get_text( ).
        lo_client->close( ).
      CATCH cx_http_dest_provider_error cx_web_http_client_error INTO DATA(lx_http).
        " Handle network, SSL, or destination configuration errors gracefully
        out->write( |Connection error: { lx_http->get_text( ) }| ).
        RETURN.
    ENDTRY.

    " Normalize line endings: Convert Windows line endings (CRLF) to Unix line endings (LF) for uniform parsing

    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf
            IN lv_csv WITH cl_abap_char_utilities=>newline.
    lv_csv = lv_csv && cl_abap_char_utilities=>newline.
    DATA(lv_len) = strlen( lv_csv ).

    " Parse CSV character-by-character (handles quoted commas & newlines)

    " Read one character at the current offset
    WHILE lv_i < lv_len.
      lv_c = substring( val = lv_csv off = lv_i len = 1 ).

      " Toggle quote state: an opening quote sets lv_quoted = abap_true;
      " a closing quote (or escaped "") toggles it back to abap_false
      IF lv_c = '"'.
        lv_quoted = xsdbool( lv_quoted = abap_false ).

      " Reached a field delimiter (comma) or row delimiter (newline) outside of quotes
      ELSEIF lv_quoted = abap_false AND ( lv_c = ',' OR lv_c = cl_abap_char_utilities=>newline ).
        lv_raw = substring( val = lv_csv off = lv_start len = lv_i - lv_start ).

        " Strip outer double quotes and unescape internal double quotes ("" -> ")
        IF strlen( lv_raw ) >= 2 AND substring( val = lv_raw off = 0 len = 1 ) = '"'.
          lv_raw = substring( val = lv_raw off = 1 len = strlen( lv_raw ) - 2 ).
          lv_raw = replace( val = lv_raw sub = `""` with = `"` occ = 0 ).
        ENDIF.

        " Store cleaned field value and advance start pointer past the delimiter
        APPEND lv_raw TO lt_fields.
        lv_start = lv_i + 1.

        " If we hit a newline, process the completed row
        IF lv_c = cl_abap_char_utilities=>newline.

          " Ignore completely empty lines (e.g., trailing newlines at EOF)
          IF lines( lt_fields ) = 1 AND lt_fields[ 1 ] IS INITIAL.
            "  Blank line: do nothing

          ELSE.
            lv_rownum = lv_rownum + 1.

            " Skip row 1 because it contains CSV column headers
            IF lv_rownum > 1.

              " Validate that the row matches the expected structure of 17 columns
              IF lines( lt_fields ) = lc_cols.

                " Map string fields to typed structure components of ZSPAC112_ATS
                APPEND VALUE #(
                  resume_id               = lt_fields[ 1 ]
                  resume_text             = lt_fields[ 2 ]
                  resume_skills           = lt_fields[ 3 ]
                  experience_years        = CONV #( lt_fields[ 4 ] )   " Convert from string to number
                  education_level         = lt_fields[ 5 ]
                  projects                = lt_fields[ 6 ]
                  certifications          = lt_fields[ 7 ]
                  job_role                = lt_fields[ 8 ]
                  required_skills         = lt_fields[ 9 ]
                  job_experience_required = CONV #( lt_fields[ 10 ] )  " Convert from string to number
                  job_description         = lt_fields[ 11 ]
                  skill_match_score       = CONV #( lt_fields[ 12 ] )  " Convert from string to number
                  experience_match        = CONV #( lt_fields[ 13 ] )  " Convert from string to number
                  education_match         = CONV #( lt_fields[ 14 ] )  " Convert from string to number
                  final_score             = CONV #( lt_fields[ 15 ] )  " Convert from string to number
                  shortlisted             = CONV #( lt_fields[ 16 ] )  " Convert from string to number
                  similarity_score        = CONV #( lt_fields[ 17 ] )  " Convert from string to number
                ) TO lt_rows.

              " Track rows that do not match the expected column count
              ELSE.
                lv_bad = lv_bad + 1.

              ENDIF.
            ENDIF.
          ENDIF.

          " Reset field buffer for the next row
          CLEAR lt_fields.
        ENDIF.
      ENDIF.

      " Move to the next character
      lv_i = lv_i + 1.
    ENDWHILE.

    " Write to the table (MODIFY, so you can re-run it)
    MODIFY zspac112_ats FROM TABLE @lt_rows.
    COMMIT WORK.

    " Output summary statistics to the ADT console
    out->write( |Rows loaded: { lines( lt_rows ) }, skipped: { lv_bad }| ).

  ENDMETHOD.
ENDCLASS.
