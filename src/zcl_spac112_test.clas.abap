CLASS zcl_spac112_test DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_spac112_test IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    SELECT COUNT(*) FROM zspac112_stock INTO @DATA(lv_t).
    SELECT COUNT(*) FROM zr_spac112_stock INTO @DATA(lv_r).
    SELECT COUNT(*) FROM zc_spac112_stock INTO @DATA(lv_c).
    out->write( |Table: { lv_t }  R: { lv_r }  C: { lv_c }| ).
    SELECT COUNT(*) FROM zc_spac112_stock WITH PRIVILEGED ACCESS INTO @DATA(lv_p).
    out->write( |Privileged C: { lv_p }| ).
  ENDMETHOD.
ENDCLASS.
