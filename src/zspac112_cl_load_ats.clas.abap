CLASS zspac112_cl_load_ats DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zspac112_cl_load_ats IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    CONSTANTS lc_url  TYPE string VALUE 'https://raw.githubusercontent.com/nielsthaumann/SAP/main/ats_resume_dataset_elite_v3.csv'.
    CONSTANTS lc_cols TYPE i VALUE 17.

    DATA lv_csv    TYPE string.
    DATA lt_rows   TYPE STANDARD TABLE OF zspac112_ats WITH EMPTY KEY.
    DATA lt_fields TYPE string_table.
    DATA lv_raw    TYPE string.
    DATA lv_c      TYPE string.
    DATA lv_quoted TYPE abap_bool.
    DATA lv_i      TYPE i.
    DATA lv_start  TYPE i.
    DATA lv_rownum TYPE i.
    DATA lv_bad    TYPE i.

    " 1. Download the file
    TRY.
        DATA(lo_dest)   = cl_http_destination_provider=>create_by_url( lc_url ).
        DATA(lo_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        DATA(lo_resp)   = lo_client->execute( if_web_http_client=>get ).
        DATA(lv_status) = lo_resp->get_status( )-code.
        IF lv_status <> 200.
          out->write( |Download failed, HTTP status { lv_status }| ).
          lo_client->close( ).
          RETURN.
        ENDIF.
        lv_csv = lo_resp->get_text( ).
        lo_client->close( ).
      CATCH cx_http_dest_provider_error cx_web_http_client_error INTO DATA(lx_http).
        out->write( |Connection error: { lx_http->get_text( ) }| ).
        RETURN.
    ENDTRY.

    " 2. Normalize line endings, make sure the last row ends with a newline
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf
            IN lv_csv WITH cl_abap_char_utilities=>newline.
    lv_csv = lv_csv && cl_abap_char_utilities=>newline.
    DATA(lv_len) = strlen( lv_csv ).

    " 3. Parse: find field borders, cut fields out with substring
    WHILE lv_i < lv_len.
      lv_c = substring( val = lv_csv off = lv_i len = 1 ).

      IF lv_c = '"'.
        " every quote toggles the state, so "" inside a field cancels out
        lv_quoted = xsdbool( lv_quoted = abap_false ).

      ELSEIF lv_quoted = abap_false
         AND ( lv_c = ',' OR lv_c = cl_abap_char_utilities=>newline ).

        lv_raw = substring( val = lv_csv off = lv_start len = lv_i - lv_start ).

        " remove surrounding quotes and unescape ""
        IF strlen( lv_raw ) >= 2 AND substring( val = lv_raw off = 0 len = 1 ) = '"'.
          lv_raw = substring( val = lv_raw off = 1 len = strlen( lv_raw ) - 2 ).
          lv_raw = replace( val = lv_raw sub = `""` with = `"` occ = 0 ).
        ENDIF.

        APPEND lv_raw TO lt_fields.
        lv_start = lv_i + 1.

        IF lv_c = cl_abap_char_utilities=>newline.
          IF lines( lt_fields ) = 1 AND lt_fields[ 1 ] IS INITIAL.
            " blank line, ignore
          ELSE.
            lv_rownum = lv_rownum + 1.
            IF lv_rownum > 1.              " row 1 is the header
              IF lines( lt_fields ) = lc_cols.
                APPEND VALUE #(
                  resume_id               = lt_fields[ 1 ]
                  resume_text             = lt_fields[ 2 ]
                  resume_skills           = lt_fields[ 3 ]
                  experience_years        = CONV #( lt_fields[ 4 ] )
                  education_level         = lt_fields[ 5 ]
                  projects                = lt_fields[ 6 ]
                  certifications          = lt_fields[ 7 ]
                  job_role                = lt_fields[ 8 ]
                  required_skills         = lt_fields[ 9 ]
                  job_experience_required = CONV #( lt_fields[ 10 ] )
                  job_description         = lt_fields[ 11 ]
                  skill_match_score       = CONV decfloat34( lt_fields[ 12 ] )
                  experience_match        = CONV #( lt_fields[ 13 ] )
                  education_match         = CONV #( lt_fields[ 14 ] )
                  final_score             = CONV decfloat34( lt_fields[ 15 ] )
                  shortlisted             = CONV #( lt_fields[ 16 ] )
                  similarity_score        = CONV decfloat34( lt_fields[ 17 ] )
                ) TO lt_rows.
              ELSE.
                lv_bad = lv_bad + 1.
              ENDIF.
            ENDIF.
          ENDIF.
          CLEAR lt_fields.
        ENDIF.
      ENDIF.

      lv_i = lv_i + 1.
    ENDWHILE.

    " 4. Write to the table (MODIFY, so you can re-run it)
    MODIFY zspac112_ats FROM TABLE @lt_rows.
    COMMIT WORK.
    out->write( |Rows loaded: { lines( lt_rows ) }, skipped: { lv_bad }| ).

  ENDMETHOD.
ENDCLASS.
