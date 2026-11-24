CLASS zspac112_cl_load_ai_results DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zspac112_cl_load_ai_results IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    CONSTANTS lc_base_url TYPE string VALUE 'https://raw.githubusercontent.com/nielsthaumann/SAP/main/'.
    CONSTANTS lc_cols     TYPE i VALUE 6.
    CONSTANTS lc_sep      TYPE string VALUE ';'.

    TYPES: BEGIN OF ty_ai_row,
             resume_id   TYPE zspac112_ats-resume_id,
             ai_score    TYPE decfloat16,
             ai_feedback TYPE string,
           END OF ty_ai_row.

    DATA lt_files    TYPE string_table.
    DATA lt_all_ai   TYPE HASHED TABLE OF ty_ai_row WITH UNIQUE KEY resume_id.
    DATA lt_fields   TYPE string_table.
    DATA lv_url      TYPE string.
    DATA lv_csv      TYPE string.
    DATA lv_raw      TYPE string.
    DATA lv_c        TYPE string.
    DATA lv_quoted   TYPE abap_bool.
    DATA lv_i        TYPE i.
    DATA lv_start    TYPE i.
    DATA lv_rownum   TYPE i.
    DATA lv_bad      TYPE i.
    DATA lv_f1       TYPE string.
    DATA lv_f4       TYPE string.
    DATA lv_f6       TYPE string.

    lt_files = VALUE #(
      ( `benchmark_resultater_Backend_Developer_100_cases.csv` )
      ( `benchmark_resultater_Data_Analyst_100_cases.csv` )
      ( `benchmark_resultater_Data_Scientist_100_cases.csv` )
      ( `benchmark_resultater_Frontend_Developer_100_cases.csv` )
      ( `benchmark_resultater_ML_Engineer_100_cases.csv` )
      ( `benchmark_resultater_Software_Engineer_100_cases.csv` )
    ).

    LOOP AT lt_files INTO DATA(lv_file).
      lv_url = lc_base_url && lv_file.
      CLEAR: lv_csv, lt_fields, lv_raw, lv_c, lv_quoted, lv_i, lv_start, lv_rownum.

      " 1. Download CSV
      TRY.
          DATA(lo_dest)   = cl_http_destination_provider=>create_by_url( lv_url ).
          DATA(lo_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
          DATA(lo_resp)   = lo_client->execute( if_web_http_client=>get ).
          DATA(lv_status) = lo_resp->get_status( )-code.
          IF lv_status <> 200.
            out->write( |Download failed ({ lv_status }): { lv_url }| ).
            lo_client->close( ).
            CONTINUE.
          ENDIF.
          lv_csv = lo_resp->get_text( ).
          lo_client->close( ).
        CATCH cx_http_dest_provider_error cx_web_http_client_error INTO DATA(lx_http).
          out->write( |Connection error ({ lv_url }): { lx_http->get_text( ) }| ).
          RETURN.
      ENDTRY.

      IF lv_csv CS '<!DOCTYPE html>' OR lv_csv CS '<html'.
        out->write( |ERROR: HTML returned instead of CSV for { lv_url }| ).
        CONTINUE.
      ENDIF.

      " 2. Strip leading Unicode BOM (\uFEFF) if present and normalize CRLF -> LF
      lv_csv = replace( val = lv_csv pcre = '^\x{FEFF}' with = '' ).
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf
              IN lv_csv WITH cl_abap_char_utilities=>newline.
      lv_csv = lv_csv && cl_abap_char_utilities=>newline.
      DATA(lv_len) = strlen( lv_csv ).

      " 3. Parse semicolon-separated fields
      WHILE lv_i < lv_len.
        lv_c = substring( val = lv_csv off = lv_i len = 1 ).

        IF lv_c = '"'.
          lv_quoted = xsdbool( lv_quoted = abap_false ).

        ELSEIF lv_quoted = abap_false
           AND ( lv_c = lc_sep OR lv_c = cl_abap_char_utilities=>newline ).

          lv_raw = substring( val = lv_csv off = lv_start len = lv_i - lv_start ).

          IF strlen( lv_raw ) >= 2 AND substring( val = lv_raw off = 0 len = 1 ) = '"'.
            lv_raw = substring( val = lv_raw off = 1 len = strlen( lv_raw ) - 2 ).
            lv_raw = replace( val = lv_raw sub = `""` with = `"` occ = 0 ).
          ENDIF.

          APPEND lv_raw TO lt_fields.
          lv_start = lv_i + 1.

          IF lv_c = cl_abap_char_utilities=>newline.
            READ TABLE lt_fields INDEX 1 INTO lv_f1.
            IF lines( lt_fields ) = 1 AND lv_f1 IS INITIAL.
              " Blank line, ignore
            ELSE.
              lv_rownum = lv_rownum + 1.
              IF lv_rownum > 1.
                IF lines( lt_fields ) = lc_cols.
                  READ TABLE lt_fields INDEX 1 INTO lv_f1.
                  READ TABLE lt_fields INDEX 4 INTO lv_f4.
                  READ TABLE lt_fields INDEX 6 INTO lv_f6.
                  TRY.
                      INSERT VALUE #(
                        resume_id   = condense( lv_f1 )
                        ai_score    = CONV decfloat16( condense( lv_f4 ) )
                        ai_feedback = lv_f6
                      ) INTO TABLE lt_all_ai.
                    CATCH cx_sy_conversion_no_number.
                      lv_bad = lv_bad + 1.
                  ENDTRY.
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
    ENDLOOP.

    IF lt_all_ai IS INITIAL.
      out->write( |No AI rows parsed. Skipped: { lv_bad }| ).
      RETURN.
    ENDIF.

    " 4. Fetch matching existing rows from ZSPAC112_ATS and join AI results
    SELECT * FROM zspac112_ats
      FOR ALL ENTRIES IN @lt_all_ai
      WHERE resume_id = @lt_all_ai-resume_id
      INTO TABLE @DATA(lt_ats_rows).

    LOOP AT lt_ats_rows ASSIGNING FIELD-SYMBOL(<ls_ats>).
      READ TABLE lt_all_ai WITH TABLE KEY resume_id = <ls_ats>-resume_id INTO DATA(ls_ai).
      IF sy-subrc = 0.
        <ls_ats>-ai_score    = ls_ai-ai_score.
        <ls_ats>-ai_feedback = ls_ai-ai_feedback.
      ENDIF.
    ENDLOOP.

    " 5. Update ZSPAC112_ATS in place
    MODIFY zspac112_ats FROM TABLE @lt_ats_rows.
    COMMIT WORK.

    out->write( |AI rows parsed: { lines( lt_all_ai ) } \| ZSPAC112_ATS updated: { lines( lt_ats_rows ) } \| Skipped: { lv_bad }| ).

  ENDMETHOD.
ENDCLASS.

