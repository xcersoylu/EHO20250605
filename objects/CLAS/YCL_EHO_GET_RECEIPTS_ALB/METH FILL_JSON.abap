  METHOD fill_json.
    TYPES : BEGIN OF ty_pparams,
              musterino TYPE string,
              hesapno   TYPE string,
              bastarih  TYPE string,
              sontarih  TYPE string,
            END OF ty_pparams,
            BEGIN OF ty_gethesaphareketleri,
              pid     TYPE string,
              pidpass TYPE string,
              pparams TYPE ty_pparams,
            END OF ty_gethesaphareketleri.
    DATA ls_json TYPE ty_gethesaphareketleri.

    DATA(lv_startdate) = mv_startdate+0(4) &&
                         mv_startdate+4(2) &&
                         mv_startdate+6(2).

    DATA(lv_enddate) = mv_enddate+0(4) &&
                       mv_enddate+4(2) &&
                       mv_enddate+6(2).
    ls_json = VALUE #(  pid = ms_bankpass-service_user
                       pidpass = ms_bankpass-service_password
                       pparams = VALUE #( musterino = ms_bankpass-firm_code
                                          hesapno = ms_bankpass-suffix
                                          bastarih = lv_startdate
                                          sontarih = lv_enddate ) ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.