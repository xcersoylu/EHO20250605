  METHOD fill_json.
    TYPES : BEGIN OF ty_json,
              kullanicikod    TYPE string,
              sifre           TYPE string,
              hesapno         TYPE string,
              baslangictarihi TYPE string,
              bitistarihi     TYPE string,
              refno           TYPE string,
            END OF ty_json.
    DATA ls_json TYPE ty_json.

    DATA(lv_startdate) = mv_startdate+6(2) && '.' &&
                         mv_startdate+4(2) && '.' &&
                         mv_startdate+0(4).

    DATA(lv_enddate)   = mv_enddate+6(2) && '.' &&
                         mv_enddate+4(2) && '.' &&
                         mv_enddate+0(4).

    ls_json = VALUE #( kullanicikod = ms_bankpass-service_user
                       sifre = ms_bankpass-service_password
                       hesapno = ms_bankpass-bankaccount
                       baslangictarihi = lv_startdate
                       bitistarihi = lv_enddate ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json ).
  ENDMETHOD.